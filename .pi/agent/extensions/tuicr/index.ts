import { spawn } from "node:child_process";
import { chmod, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// tuicr is an interactive TUI, so it cannot run inside pi's process. It is
// launched in a new Ghostty tab; this extension waits for the tab to finish and
// then pulls the comments tuicr persisted for the repo.
const POLL_INTERVAL_MS = 500;
const WAIT_TIMEOUT_MS = 4 * 60 * 60 * 1000;

type CommandResult = { code: number; stdout: string; stderr: string };

type ReviewSession = {
    slug: string;
    kind: string;
    path?: string;
    updated_at?: string;
    comment_count?: number;
};

type ReviewComment = {
    id: string;
    location?: string;
    path?: string | null;
    start_line?: number | null;
    end_line?: number | null;
    side?: string | null;
    comment_type?: string | null;
    lifecycle_state?: string | null;
    content?: string;
};

function runCapture(
    file: string,
    args: string[],
    cwd: string,
    allowedExitCodes = [0],
): Promise<CommandResult> {
    return new Promise((resolve, reject) => {
        const child = spawn(file, args, {
            cwd,
            stdio: ["ignore", "pipe", "pipe"],
        });
        let stdout = "";
        let stderr = "";

        child.stdout.on("data", (chunk) => {
            stdout += String(chunk);
        });
        child.stderr.on("data", (chunk) => {
            stderr += String(chunk);
        });
        child.on("error", reject);
        child.on("close", (code) => {
            const resolvedCode = code ?? 1;
            if (allowedExitCodes.includes(resolvedCode)) {
                resolve({ code: resolvedCode, stdout, stderr });
            } else {
                reject(
                    new Error(
                        stderr.trim() ||
                            `${file} ${args.join(" ")} exited with code ${resolvedCode}`,
                    ),
                );
            }
        });
    });
}

function runWithInput(
    file: string,
    args: string[],
    input: string,
): Promise<void> {
    return new Promise((resolve, reject) => {
        const child = spawn(file, args, { stdio: ["pipe", "ignore", "pipe"] });
        let stderr = "";

        child.stderr.on("data", (chunk) => {
            stderr += String(chunk);
        });
        child.on("error", reject);
        child.on("close", (code) => {
            if (code === 0) resolve();
            else
                reject(
                    new Error(
                        stderr.trim() || `${file} exited with code ${code}`,
                    ),
                );
        });

        child.stdin.end(input);
    });
}

function shellQuote(value: string): string {
    return `'${value.replace(/'/g, `'\\''`)}'`;
}

function sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

async function commandExists(command: string): Promise<boolean> {
    const result = await runCapture(
        "/bin/sh",
        ["-c", `command -v ${shellQuote(command)} >/dev/null 2>&1`],
        process.cwd(),
        [0, 1, 127],
    );
    return result.code === 0;
}

// Same pattern as the gh-summary extension: mirror the clipboard tool per
// platform so the Ghostty tab can be driven by pasting a single command.
function runClipboardCommand(
    file: string,
    args: string[],
    input: string,
): Promise<void> {
    return new Promise((resolve, reject) => {
        const child = spawn(file, args, { stdio: ["pipe", "ignore", "pipe"] });
        let stderr = "";
        let settled = false;
        let settleTimer: NodeJS.Timeout | undefined;

        const settle = (error?: Error) => {
            if (settled) return;
            settled = true;
            if (settleTimer) clearTimeout(settleTimer);
            child.stderr.destroy();
            child.unref();
            if (error) reject(error);
            else resolve();
        };

        child.stderr.on("data", (chunk) => {
            stderr += String(chunk);
        });
        child.on("error", settle);
        child.on("close", (code) => {
            if (code === 0) settle();
            else
                settle(
                    new Error(
                        stderr.trim() || `${file} exited with code ${code}`,
                    ),
                );
        });

        child.stdin.end(input, () => {
            // Wayland/X11 clipboard tools stay alive to serve paste requests, so
            // continue once stdin has been accepted.
            settleTimer = setTimeout(() => settle(), 200);
        });
    });
}

async function copyToClipboard(text: string): Promise<void> {
    if (process.platform === "darwin") {
        await runWithInput("/usr/bin/pbcopy", [], text);
        return;
    }

    if (await commandExists("wl-copy")) {
        await runClipboardCommand("wl-copy", [], text);
        return;
    }

    throw new Error("wl-copy is required for clipboard support on Linux");
}

async function sendHyprlandShortcut(shortcut: string): Promise<void> {
    await runCapture(
        "hyprctl",
        ["dispatch", "sendshortcut", `${shortcut},activewindow`],
        process.cwd(),
    );
}

// Runs inside the new Ghostty tab. The exit status is written to a marker file
// so the extension knows the review is over without watching the process tree.
// On macOS the delayed Cmd+W is backgrounded so the shell can exit immediately;
// on Linux the tab closes on its own because the script is `exec`ed.
function wrapperScript(
    repoRoot: string,
    tuicrArgs: string[],
    donePath: string,
): string {
    const argv = tuicrArgs.map(shellQuote).join(" ");
    return `#!/bin/sh
set +e
cd ${shellQuote(repoRoot)} || exit 1
tuicr ${argv}
status=$?
printf '%s' "$status" > ${shellQuote(donePath)}
if [ "${process.platform}" = "darwin" ]; then
  (
    sleep 0.1
    /usr/bin/osascript -e 'tell application "Ghostty" to activate' \
      -e 'tell application "System Events" to keystroke "w" using command down'
  ) >/dev/null 2>&1 &
fi
exit "$status"
`;
}

async function openInGhosttyMac(wrapperPath: string): Promise<void> {
    // Only a trivial wrapper invocation is pasted into Ghostty; the fragile
    // quoting lives in the temp script.
    await copyToClipboard(`command /bin/sh ${shellQuote(wrapperPath)}`);

    const script = `tell application "Ghostty" to activate
delay 0.3
tell application "System Events"
  keystroke "t" using command down
  delay 0.4
  keystroke "v" using command down
  key code 36
end tell
`;

    await runWithInput("/usr/bin/osascript", [], script);
}

async function openInGhosttyLinux(wrapperPath: string): Promise<void> {
    if (!(await commandExists("hyprctl"))) {
        throw new Error(
            "opening a new Ghostty tab on Linux currently requires Hyprland's hyprctl",
        );
    }

    // `exec` makes Ghostty close the tab when tuicr exits.
    await copyToClipboard(`exec /bin/sh ${shellQuote(wrapperPath)}`);

    await sendHyprlandShortcut("CTRL_SHIFT,T");
    await sleep(400);
    await sendHyprlandShortcut("CTRL_SHIFT,V");
    await sleep(100);
    await sendHyprlandShortcut(",Return");
}

async function openInGhostty(wrapperPath: string): Promise<void> {
    if (process.platform === "darwin") return openInGhosttyMac(wrapperPath);
    if (process.platform === "linux") return openInGhosttyLinux(wrapperPath);
    throw new Error(
        `unsupported platform for Ghostty automation: ${process.platform}`,
    );
}

function parseJson<T>(raw: string, fallback: T): T {
    const trimmed = raw.trim();
    if (!trimmed) return fallback;
    try {
        return JSON.parse(trimmed) as T;
    } catch {
        return fallback;
    }
}

async function listSessions(repoRoot: string): Promise<ReviewSession[]> {
    const result = await runCapture(
        "tuicr",
        ["review", "list", "--repo", repoRoot],
        repoRoot,
        [0, 1],
    );
    if (result.code !== 0) return [];
    return parseJson<ReviewSession[]>(result.stdout, []);
}

async function sessionComments(
    repoRoot: string,
    slug: string,
): Promise<ReviewComment[]> {
    const result = await runCapture(
        "tuicr",
        ["review", "comments", "--session", slug, "--repo", repoRoot],
        repoRoot,
        [0, 1],
    );
    if (result.code !== 0) return [];
    return parseJson<ReviewComment[]>(result.stdout, []);
}

// Comments from every session of the repo, keyed by id so pre-existing comments
// (from earlier reviews) can be filtered out after tuicr exits.
async function collectComments(
    repoRoot: string,
): Promise<Map<string, ReviewComment>> {
    const comments = new Map<string, ReviewComment>();
    for (const session of await listSessions(repoRoot)) {
        if (!session.slug) continue;
        for (const comment of await sessionComments(repoRoot, session.slug)) {
            if (comment?.id) comments.set(comment.id, comment);
        }
    }
    return comments;
}

function commentHeading(comment: ReviewComment): string {
    if (!comment.path) return "General review comment";

    const side = comment.side === "old" ? " (old side)" : "";
    if (comment.start_line == null) return `${comment.path}${side}`;
    if (comment.end_line != null && comment.end_line !== comment.start_line) {
        return `${comment.path}:${comment.start_line}-${comment.end_line}${side}`;
    }
    return `${comment.path}:${comment.start_line}${side}`;
}

function formatReview(comments: ReviewComment[], repoRoot: string): string {
    const sorted = [...comments].sort((a, b) => {
        const pathA = a.path ?? "";
        const pathB = b.path ?? "";
        if (pathA !== pathB) return pathA.localeCompare(pathB);
        return (a.start_line ?? 0) - (b.start_line ?? 0);
    });

    const items = sorted.map((comment) => {
        const type =
            comment.comment_type && comment.comment_type !== "none"
                ? ` [${comment.comment_type}]`
                : "";
        const body = (comment.content ?? "").trim() || "(empty comment)";
        return `### ${commentHeading(comment)}${type}\n${body}`;
    });

    return [
        `I reviewed the working tree in ${repoRoot} with tuicr and left ${comments.length} comment${comments.length === 1 ? "" : "s"}.`,
        "",
        "Address each of them. Ask me if any comment is ambiguous.",
        "",
        "## Review comments",
        "",
        items.join("\n\n"),
    ].join("\n");
}

async function readDoneStatus(donePath: string): Promise<number | undefined> {
    try {
        const raw = (await readFile(donePath, "utf8")).trim();
        return raw ? Number(raw) : 0;
    } catch (error) {
        const code = (error as NodeJS.ErrnoException).code;
        if (code === "ENOENT") return undefined;
        throw error;
    }
}

export default function tuicrExtension(pi: ExtensionAPI) {
    pi.registerCommand("tuicr", {
        description:
            "Review the working tree with tuicr in a new Ghostty tab, then add the review comments to this session. Usage: /tuicr [extra tuicr args]",
        handler: async (args, ctx) => {
            if (!(await commandExists("tuicr"))) {
                ctx.ui.notify("tuicr is not installed or not on PATH", "error");
                return;
            }

            let repoRoot = ctx.cwd;
            try {
                repoRoot = (
                    await runCapture(
                        "git",
                        ["rev-parse", "--show-toplevel"],
                        ctx.cwd,
                    )
                ).stdout.trim();
            } catch {
                // Not a git repo: tuicr can still annotate files from the cwd.
            }

            const extraArgs = (args ?? "").trim();
            const tuicrArgs = [
                "-w",
                ...(
                    extraArgs.match(/(?:[^\s"']+|"[^"]*"|'[^']*')+/g) ?? []
                ).map((token) => token.replace(/^['"]|['"]$/g, "")),
            ];

            const before = await collectComments(repoRoot);

            const tmpDir = await mkdtemp(path.join(os.tmpdir(), "pi-tuicr-"));
            const donePath = path.join(tmpDir, "exit-status");
            const wrapperPath = path.join(tmpDir, "run-tuicr.sh");
            await writeFile(
                wrapperPath,
                wrapperScript(repoRoot, tuicrArgs, donePath),
                "utf8",
            );
            await chmod(wrapperPath, 0o700);

            try {
                await openInGhostty(wrapperPath);
            } catch (error) {
                await rm(tmpDir, { recursive: true, force: true });
                ctx.ui.notify(
                    `Failed to open Ghostty tab: ${(error as Error).message}`,
                    "error",
                );
                return;
            }

            ctx.ui.setStatus("tuicr", "Waiting for tuicr review...");
            let status: number | undefined;
            try {
                const deadline = Date.now() + WAIT_TIMEOUT_MS;
                while (status === undefined) {
                    if (Date.now() > deadline) {
                        ctx.ui.notify("Timed out waiting for tuicr", "error");
                        return;
                    }
                    await sleep(POLL_INTERVAL_MS);
                    status = await readDoneStatus(donePath);
                }
            } finally {
                ctx.ui.setStatus("tuicr", undefined);
                await rm(tmpDir, { recursive: true, force: true });
            }

            if (status !== 0) {
                ctx.ui.notify(`tuicr exited with status ${status}`, "warning");
                return;
            }

            const after = await collectComments(repoRoot);
            const fresh = [...after.values()].filter(
                (comment) => !before.has(comment.id),
            );

            if (fresh.length === 0) {
                ctx.ui.notify("tuicr review finished with no comments", "info");
                return;
            }

            ctx.ui.notify(
                `Adding ${fresh.length} tuicr comment${fresh.length === 1 ? "" : "s"} to the session`,
                "info",
            );
            await pi.sendUserMessage(formatReview(fresh, repoRoot));
        },
    });
}
