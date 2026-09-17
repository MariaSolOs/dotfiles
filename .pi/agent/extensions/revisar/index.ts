import { execFile, spawn } from "node:child_process";
import { access, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { constants } from "node:fs";
import os from "node:os";
import path from "node:path";
import { setTimeout as sleep } from "node:timers/promises";
import { promisify } from "node:util";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Personal, source-only build. Rebuild with cargo build --release --locked in
// this checkout; no installation, download, or tuicr dependency is involved.
const REVISAR = "/Volumes/git/revisar/target/release/revisar";
const exec = promisify(execFile);
const START_TIMEOUT = 30_000;
const REVIEW_TIMEOUT = 4 * 60 * 60 * 1000;

function quote(value: string): string {
    return `'${value.replace(/'/g, `'\\''`)}'`;
}

async function run(
    file: string,
    args: string[],
    input?: string,
): Promise<void> {
    // execFile's promise does not expose stdin, so supply input via its child.
    const pending = exec(file, args, {
        timeout: 10_000,
        maxBuffer: 1024 * 1024,
    });
    pending.child.stdin?.on("error", () => {});
    pending.child.stdin?.end(input);
    await pending;
}

async function readOptional(file: string): Promise<string | undefined> {
    try {
        return await readFile(file, "utf8");
    } catch (error) {
        if ((error as NodeJS.ErrnoException).code === "ENOENT")
            return undefined;
        throw error;
    }
}

function wrapper(root: string, dir: string): string {
    // Temporary files are a one-shot transport, not saved review state. The
    // marker is renamed atomically only after stdout has been closed. The
    // terminal UI writes to /dev/tty, leaving stdout as pure feedback.
    return `#!/bin/sh
umask 077
[ -d ${quote(dir)} ] || exit 0
finish() {
    status=$?
    trap - 0
    if [ -d ${quote(dir)} ]; then
        printf '%s' "$status" > ${quote(path.join(dir, "status.pending"))}
        mv -f ${quote(path.join(dir, "status.pending"))} ${quote(path.join(dir, "status"))}
    fi
    # Pi reads the real status above. A cancelled review is not a terminal
    # failure: always let Ghostty's command finish successfully.
    exit 0
}
trap finish 0
trap 'exit 2' HUP INT TERM
printf 'started' > ${quote(path.join(dir, "started"))}
export PATH=${quote(process.env.PATH ?? "/usr/bin:/bin")}
cd ${quote(root)} || exit 1
${quote(REVISAR)} > ${quote(path.join(dir, "feedback.md"))} 2> ${quote(path.join(dir, "error"))}
exit $?
`;
}

async function copyWayland(command: string): Promise<void> {
    // Wayland clipboard owners must stay alive until the paste. Do not wait
    // for process exit before issuing the shortcut that consumes the clipboard.
    const child = spawn("wl-copy", ["--foreground", "--paste-once"], {
        stdio: ["pipe", "ignore", "ignore"],
    });
    try {
        await new Promise<void>((resolve, reject) => {
            child.on("error", reject);
            child.stdin.on("error", reject);
            child.on("exit", (code) => {
                if (code !== 0)
                    reject(new Error(`wl-copy exited with status ${code}`));
            });
            child.stdin.end(command, () => setTimeout(resolve, 200));
        });
    } finally {
        child.unref();
    }
}

async function openGhostty(script: string): Promise<string | undefined> {
    if (process.platform === "darwin") {
        // Ghostty 1.3's native API runs the wrapper as the tab's command, not
        // as text pasted into a shell. Keep the stable ID so cleanup can close
        // only this review tab even if focus changes or Ghostty keeps it open.
        const result = await exec(
            "/usr/bin/osascript",
            [
                "-e",
                `on run argv
    tell application "Ghostty"
        set cfg to new surface configuration
        set command of cfg to item 1 of argv
        set wait after command of cfg to false
        set reviewTab to new tab in front window with configuration cfg
        return id of reviewTab
    end tell
end run`,
                `/bin/sh ${quote(script)}`,
            ],
            { timeout: 10_000 },
        );
        const tabId = result.stdout.trim();
        if (!tabId) throw new Error("Ghostty did not return the review tab ID");
        return tabId;
    } else if (process.platform === "linux") {
        // Replace the new tab's shell so it exits when the wrapper finishes.
        await copyWayland(`exec /bin/sh ${quote(script)}`);
        await run("hyprctl", [
            "dispatch",
            "sendshortcut",
            "ALT SHIFT,T,activewindow",
        ]);
        await sleep(400);
        await run("hyprctl", [
            "dispatch",
            "sendshortcut",
            "ALT SHIFT,P,activewindow",
        ]);
        await sleep(100);
        await run("hyprctl", [
            "dispatch",
            "sendshortcut",
            ",Return,activewindow",
        ]);
    } else {
        throw new Error(
            "The revisar extension requires macOS or Linux/Hyprland with Ghostty",
        );
    }
}

async function closeGhosttyTab(tabId: string): Promise<void> {
    // The tab may already have closed automatically or been closed by hand.
    // Never fall back to Cmd+W or closing the selected/front tab.
    await exec(
        "/usr/bin/osascript",
        [
            "-e",
            `on run argv
    tell application "Ghostty"
        repeat with win in windows
            repeat with candidate in tabs of win
                if id of candidate is item 1 of argv then
                    close tab candidate
                    return
                end if
            end repeat
        end repeat
    end tell
end run`,
            tabId,
        ],
        { timeout: 10_000 },
    );
}

export default function revisarExtension(pi: ExtensionAPI) {
    let active: { controller: AbortController; dir?: string } | undefined;

    // A review belongs to the Pi conversation that launched it. Reloading,
    // switching, or quitting must never deliver its comments to another one.
    pi.on("session_shutdown", async (_event, ctx) => {
        const review = active;
        review?.controller.abort();
        ctx.ui.setStatus("revisar", undefined);
        if (review?.dir) await rm(review.dir, { recursive: true, force: true });
    });

    pi.registerCommand("revisar", {
        description:
            "Review working-tree changes in a Ghostty tab. Send passes comments directly to this agent; cancel discards them.",
        handler: async (args, ctx) => {
            if (ctx.mode !== "tui") {
                ctx.ui.notify(
                    "/revisar requires interactive Pi and Ghostty",
                    "error",
                );
                return;
            }
            if (args.trim()) {
                ctx.ui.notify(
                    "Usage: /revisar (working tree only; no arguments)",
                    "warning",
                );
                return;
            }
            if (active) {
                ctx.ui.notify("A revisar review is already open", "warning");
                return;
            }
            if (!ctx.isIdle() || ctx.hasPendingMessages()) {
                ctx.ui.notify(
                    "Wait for the agent and queued messages to finish before reviewing",
                    "warning",
                );
                return;
            }
            const review: { controller: AbortController; dir?: string } = {
                controller: new AbortController(),
            };
            active = review;
            const signal = review.controller.signal;
            const sessionId = ctx.sessionManager.getSessionId();
            let feedback: string | undefined;
            let tabId: string | undefined;
            let handedOff = false;
            try {
                await access(REVISAR, constants.X_OK).catch(() => {
                    throw new Error(
                        `Build revisar first: cd /Volumes/git/revisar && cargo build --release --locked`,
                    );
                });
                const result = await exec(
                    "git",
                    ["rev-parse", "--show-toplevel"],
                    { cwd: ctx.cwd, timeout: 10_000, signal },
                );
                const root = result.stdout.replace(/\n$/, "");
                signal.throwIfAborted();
                const dir = await mkdtemp(
                    path.join(os.tmpdir(), "pi-revisar-"),
                );
                review.dir = dir;
                const script = path.join(dir, "run.sh");
                await writeFile(script, wrapper(root, dir), { mode: 0o700 });
                signal.throwIfAborted();
                ctx.ui.setStatus("revisar", "Opening revisar in Ghostty...");
                tabId = await openGhostty(script);
                const startDeadline = Date.now() + START_TIMEOUT;
                const reviewDeadline = Date.now() + REVIEW_TIMEOUT;
                let started = false;
                let status: number;
                while (true) {
                    signal.throwIfAborted();
                    const raw = await readOptional(path.join(dir, "status"));
                    if (raw !== undefined) {
                        if (!/^\d+$/.test(raw))
                            throw new Error(
                                "Invalid revisar exit status; no feedback sent",
                            );
                        status = Number(raw);
                        break;
                    }
                    if (
                        !started &&
                        (await readOptional(path.join(dir, "started"))) !==
                            undefined
                    ) {
                        started = true;
                        ctx.ui.setStatus(
                            "revisar",
                            "Reviewing in Ghostty - S sends, q cancels",
                        );
                    }
                    if (!started && Date.now() >= startDeadline) {
                        throw new Error(
                            "Ghostty did not start revisar. On macOS, check Ghostty Automation permission; on Linux, check the alt+shift+t/p bindings. No feedback sent.",
                        );
                    }
                    if (Date.now() >= reviewDeadline) {
                        throw new Error(
                            "revisar timed out after four hours. This review was discarded; close its tab and start again.",
                        );
                    }
                    await sleep(250, undefined, { signal });
                }
                signal.throwIfAborted();
                if (status === 2) {
                    ctx.ui.notify("Review cancelled; no feedback sent", "info");
                    return;
                }
                if (status !== 0) {
                    const error = (
                        await readOptional(path.join(dir, "error"))
                    )?.trim();
                    throw new Error(
                        error ||
                            `revisar exited with status ${status}; no feedback sent`,
                    );
                }
                feedback = (
                    await readFile(path.join(dir, "feedback.md"), "utf8")
                ).trim();
                signal.throwIfAborted();
                if (!feedback) {
                    ctx.ui.notify("Review finished with no comments", "info");
                    return;
                }
                if (ctx.sessionManager.getSessionId() !== sessionId) {
                    feedback = undefined;
                    throw new Error(
                        "The Pi conversation changed; no feedback sent",
                    );
                }
                await pi.sendUserMessage(feedback, { deliverAs: "followUp" });
                handedOff = true;
                ctx.ui.notify("Review feedback passed to the agent", "info");
            } catch (error) {
                if (!signal.aborted) {
                    // Keep failed handoff text in Pi's editor, never on disk.
                    // It remains visible and editable instead of silently lost.
                    if (feedback && !handedOff) ctx.ui.setEditorText(feedback);
                    ctx.ui.notify(
                        `revisar: ${(error as Error).message}`,
                        "error",
                    );
                }
            } finally {
                if (tabId) {
                    try {
                        await closeGhosttyTab(tabId);
                    } catch (error) {
                        if (!signal.aborted)
                            ctx.ui.notify(
                                `Could not close the revisar tab: ${(error as Error).message}`,
                                "warning",
                            );
                    }
                }
                if (!signal.aborted) ctx.ui.setStatus("revisar", undefined);
                if (review.dir)
                    await rm(review.dir, { recursive: true, force: true });
                if (active === review) active = undefined;
            }
        },
    });
}
