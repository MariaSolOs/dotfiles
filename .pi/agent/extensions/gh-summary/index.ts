import { spawn } from "node:child_process";
import {
    chmod,
    mkdtemp,
    open,
    readFile,
    stat,
    writeFile,
} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { complete, type UserMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Keep the summarization request bounded while preserving enough concrete diff
// context for the model to write a useful PR title and description.
const MAX_CHANGESET_CHARS = 120_000;
const MAX_SECTION_CHARS = 50_000;
const MAX_CONVERSATION_CONTEXT_CHARS = 12_000;
const MAX_EXTRA_CONTEXT_CHARS = 8_000;
const MAX_UNTRACKED_FILES = 25;
const MAX_UNTRACKED_READ_BYTES = 256_000;
const MAX_UNTRACKED_FILE_CHARS = 12_000;

const SYSTEM_PROMPT = `You write concise, human-sounding GitHub pull request titles and descriptions from git changes.

Requirements:
- Base the PR summary primarily on the provided git status, commit list, diffs, and untracked file contents.
- Use provided extra context and conversation context only to understand intent, rationale, constraints, or wording around those git changes.
- Do not summarize unrelated context or mention work that is not reflected in the git changes.
- Use raw Markdown only; do not wrap the entire response in a code fence.
- Do not include padding or preamble like "Here’s a summary".
- Include a suggested PR title and a PR description.
- Keep the PR description to paragraphs, at most 3, unless a provided PR template requires another structure.
- Be concise, but include important facts, design decisions, results, and follow-ups when applicable.
- Use first person plural or neutral engineering voice when appropriate.`;

function truncate(value: string, max = MAX_SECTION_CHARS): string {
    if (value.length <= max) return value;
    return `${value.slice(0, max)}\n...[truncated ${value.length - max} chars]`;
}

type CommandResult = {
    code: number;
    stdout: string;
    stderr: string;
};

type ContentBlock = {
    type?: string;
    text?: string;
};

type SessionEntry = {
    type?: string;
    message?: {
        role?: string;
        content?: unknown;
    };
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

async function runGit(
    cwd: string,
    args: string[],
    allowedExitCodes = [0],
): Promise<string> {
    const result = await runCapture("git", args, cwd, allowedExitCodes);
    return result.stdout;
}

function extractTextParts(content: unknown): string[] {
    if (typeof content === "string") return [content];
    if (!Array.isArray(content)) return [];

    const parts: string[] = [];
    for (const item of content) {
        if (!item || typeof item !== "object") continue;
        const block = item as ContentBlock;
        if (block.type === "text" && typeof block.text === "string") {
            parts.push(block.text);
        }
    }
    return parts;
}

function buildConversationContext(entries: SessionEntry[]): string {
    const sections: string[] = [];
    let total = 0;

    for (const entry of [...entries].reverse()) {
        if (entry.type !== "message" || !entry.message?.role) continue;

        const role = entry.message.role;
        if (role !== "user" && role !== "assistant") continue;

        const text = extractTextParts(entry.message.content).join("\n").trim();
        if (!text) continue;

        const label = role === "user" ? "User" : "Assistant";
        const section = `${label}: ${truncate(text, 2_000)}`;
        const separatorLength = sections.length === 0 ? 0 : 2;
        if (
            total + separatorLength + section.length >
            MAX_CONVERSATION_CONTEXT_CHARS
        ) {
            break;
        }

        sections.unshift(section);
        total += separatorLength + section.length;
    }

    return sections.join("\n\n");
}

function appendBoundedSection(
    sections: string[],
    title: string,
    body: string,
    total: { value: number },
): void {
    if (total.value >= MAX_CHANGESET_CHARS) return;

    const trimmed = body.trimEnd();
    if (!trimmed) return;

    let section = `## ${title}\n${trimmed}`;
    const separatorLength = sections.length === 0 ? 0 : 2;
    if (total.value + separatorLength + section.length > MAX_CHANGESET_CHARS) {
        const remaining = MAX_CHANGESET_CHARS - total.value - separatorLength;
        if (remaining <= 500) {
            sections.push("...[git changes truncated]");
            total.value = MAX_CHANGESET_CHARS;
            return;
        }
        section = truncate(section, remaining);
    }

    sections.push(section);
    total.value += separatorLength + section.length;
}

function parseNulSeparated(value: string): string[] {
    return value.split("\0").filter(Boolean);
}

function resolveRepoPath(
    root: string,
    relativePath: string,
): string | undefined {
    const resolved = path.resolve(root, relativePath);
    const relative = path.relative(root, resolved);
    if (
        relative === "" ||
        relative.startsWith("..") ||
        path.isAbsolute(relative)
    ) {
        return undefined;
    }
    return resolved;
}

async function readUntrackedFile(
    root: string,
    relativePath: string,
): Promise<string> {
    const absolutePath = resolveRepoPath(root, relativePath);
    if (!absolutePath) return "[omitted: path resolves outside repository]";

    try {
        const fileStat = await stat(absolutePath);
        if (!fileStat.isFile()) return "[omitted: not a regular file]";

        const bytesToRead = Math.min(fileStat.size, MAX_UNTRACKED_READ_BYTES);
        const handle = await open(absolutePath, "r");
        try {
            const buffer = Buffer.alloc(bytesToRead);
            const { bytesRead } = await handle.read(buffer, 0, bytesToRead, 0);
            const content = buffer.subarray(0, bytesRead);
            if (content.includes(0)) return "[binary file omitted]";

            const truncationNote =
                fileStat.size > bytesRead
                    ? `\n...[truncated ${fileStat.size - bytesRead} bytes]`
                    : "";
            return truncate(
                content.toString("utf8") + truncationNote,
                MAX_UNTRACKED_FILE_CHARS,
            );
        } finally {
            await handle.close();
        }
    } catch (error) {
        return `[omitted: ${(error as Error).message}]`;
    }
}

async function buildUntrackedSection(
    root: string,
    rawFiles: string,
): Promise<string> {
    const files = parseNulSeparated(rawFiles);
    if (files.length === 0) return "";

    const chunks = [
        `Untracked files (${files.length}):`,
        files.map((file) => `- ${file}`).join("\n"),
    ];

    for (const file of files.slice(0, MAX_UNTRACKED_FILES)) {
        const content = await readUntrackedFile(root, file);
        chunks.push([`--- ${file}`, content].join("\n"));
    }

    if (files.length > MAX_UNTRACKED_FILES) {
        chunks.push(
            `...[omitted ${files.length - MAX_UNTRACKED_FILES} additional untracked files]`,
        );
    }

    return chunks.join("\n\n");
}

type GitChanges = {
    root: string;
    source: "worktree" | "branch";
    text: string;
};

async function refExists(root: string, ref: string): Promise<boolean> {
    const result = await runCapture(
        "git",
        ["rev-parse", "--verify", "--quiet", `${ref}^{commit}`],
        root,
        [0, 1],
    );
    return result.code === 0;
}

async function firstExistingBaseRef(
    root: string,
    branch: string,
): Promise<string | undefined> {
    const candidates: string[] = [];

    const originHead = await runCapture(
        "git",
        ["symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"],
        root,
        [0, 1],
    );
    if (originHead.code === 0 && originHead.stdout.trim()) {
        candidates.push(originHead.stdout.trim());
    }

    candidates.push("origin/main", "origin/master", "main", "master");

    const upstream = await runCapture(
        "git",
        ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"],
        root,
        [0, 128],
    );
    if (upstream.code === 0 && upstream.stdout.trim()) {
        candidates.push(upstream.stdout.trim());
    }

    for (const candidate of [...new Set(candidates)]) {
        if (candidate === branch) continue;
        if (await refExists(root, candidate)) return candidate;
    }

    return undefined;
}

async function collectBranchChanges(
    root: string,
    branch: string,
    head: string,
): Promise<GitChanges> {
    const baseRef = await firstExistingBaseRef(root, branch.trim());
    if (!baseRef) return { root, source: "branch", text: "" };

    const mergeBase = (
        await runGit(root, ["merge-base", baseRef, "HEAD"], [0, 1])
    ).trim();
    if (!mergeBase) return { root, source: "branch", text: "" };

    const commitCount = Number(
        (
            await runGit(root, ["rev-list", "--count", `${mergeBase}..HEAD`])
        ).trim(),
    );
    if (commitCount === 0) return { root, source: "branch", text: "" };

    const [commits, diffStat, diff] = await Promise.all([
        runGit(root, ["log", "--oneline", "--decorate", `${mergeBase}..HEAD`]),
        runGit(root, ["diff", "--stat", `${mergeBase}..HEAD`, "--"]),
        runGit(root, [
            "diff",
            "--no-ext-diff",
            "--find-renames",
            "--find-copies",
            `${mergeBase}..HEAD`,
            "--",
        ]),
    ]);

    const sections: string[] = [];
    const total = { value: 0 };
    appendBoundedSection(
        sections,
        "Repository",
        [
            `Root: ${root}`,
            `Branch: ${branch.trim() || "(detached HEAD)"}`,
            `HEAD: ${head.trim()}`,
            `Base ref: ${baseRef}`,
            `Merge base: ${mergeBase.slice(0, 12)}`,
            `Commits ahead: ${commitCount}`,
        ].join("\n"),
        total,
    );
    appendBoundedSection(sections, "Branch commits", commits, total);
    appendBoundedSection(sections, "Branch diffstat", diffStat, total);
    appendBoundedSection(sections, "Branch diff", diff, total);

    return { root, source: "branch", text: sections.join("\n\n") };
}

async function collectGitChanges(cwd: string): Promise<GitChanges> {
    let root: string;
    try {
        root = (await runGit(cwd, ["rev-parse", "--show-toplevel"])).trim();
    } catch (error) {
        throw new Error(
            `Not a git repository, or git is unavailable: ${(error as Error).message}`,
        );
    }

    const [branch, head, status] = await Promise.all([
        runGit(root, ["branch", "--show-current"]),
        runGit(root, ["rev-parse", "--short", "HEAD"]),
        runGit(root, ["status", "--short"]),
    ]);

    if (!status.trim()) return collectBranchChanges(root, branch, head);

    const [stagedStat, unstagedStat, stagedDiff, unstagedDiff, untrackedRaw] =
        await Promise.all([
            runGit(root, ["diff", "--cached", "--stat", "--"]),
            runGit(root, ["diff", "--stat", "--"]),
            runGit(root, [
                "diff",
                "--cached",
                "--no-ext-diff",
                "--find-renames",
                "--find-copies",
                "--",
            ]),
            runGit(root, [
                "diff",
                "--no-ext-diff",
                "--find-renames",
                "--find-copies",
                "--",
            ]),
            runGit(root, ["ls-files", "--others", "--exclude-standard", "-z"]),
        ]);

    const sections: string[] = [];
    const total = { value: 0 };
    appendBoundedSection(
        sections,
        "Repository",
        [
            `Root: ${root}`,
            `Branch: ${branch.trim() || "(detached HEAD)"}`,
            `HEAD: ${head.trim()}`,
        ].join("\n"),
        total,
    );
    appendBoundedSection(sections, "Worktree status", status, total);
    appendBoundedSection(sections, "Staged diffstat", stagedStat, total);
    appendBoundedSection(sections, "Staged diff", stagedDiff, total);
    appendBoundedSection(sections, "Unstaged diffstat", unstagedStat, total);
    appendBoundedSection(sections, "Unstaged diff", unstagedDiff, total);
    appendBoundedSection(
        sections,
        "Untracked files",
        await buildUntrackedSection(root, untrackedRaw),
        total,
    );

    return { root, source: "worktree", text: sections.join("\n\n") };
}

// Match GitHub's common single-file PR template location; absence is normal.
async function readPrTemplate(cwd: string): Promise<string | undefined> {
    try {
        const templatePath = path.join(
            cwd,
            ".github",
            "PULL_REQUEST_TEMPLATE.md",
        );
        const template = await readFile(templatePath, "utf8");
        return template.trim() || undefined;
    } catch (error) {
        const code = (error as NodeJS.ErrnoException).code;
        if (code === "ENOENT" || code === "ENOTDIR") return undefined;
        throw error;
    }
}

function buildUserPrompt(
    changesText: string,
    source: GitChanges["source"],
    extraContext: string,
    conversationContext: string,
    prTemplate?: string,
): string {
    const templateSection = prTemplate
        ? [
              "Use this GitHub PR template for the description if possible:",
              "<pull_request_template>",
              prTemplate,
              "</pull_request_template>",
              "",
          ].join("\n")
        : "";

    const extraContextSection = extraContext.trim()
        ? [
              "Extra context provided explicitly with this command. Use this only to clarify intent/rationale for the git changes:",
              "<extra_context>",
              truncate(extraContext.trim(), MAX_EXTRA_CONTEXT_CHARS),
              "</extra_context>",
              "",
          ].join("\n")
        : "";

    const conversationSection = conversationContext.trim()
        ? [
              "Supplemental conversation context. Use this only to clarify intent/rationale for the git changes; do not summarize unrelated parts of the conversation:",
              "<conversation_context>",
              conversationContext,
              "</conversation_context>",
              "",
          ].join("\n")
        : "";

    const sourceDescription =
        source === "worktree"
            ? "current git worktree changes"
            : "commits on the current branch";

    return [
        `Summarize the ${sourceDescription} into a concise GitHub-ready PR description, together with a suggested title.`,
        "Focus on the provided git changes. Use extra/context sections only as supporting context for those changes, not as the thing being summarized.",
        "",
        templateSection,
        extraContextSection,
        conversationSection,
        "Output format:",
        "Title: <suggested PR title>",
        "",
        "<PR description markdown>",
        "",
        "Git changes:",
        "<git_changes>",
        changesText,
        "</git_changes>",
    ].join("\n");
}

// The prompt forbids wrapping fences, but strip one anyway so the temp file is
// directly pasteable into GitHub if the model ignores that instruction.
function stripWrappingCodeFence(text: string): string {
    const trimmed = text.trim();
    const match = trimmed.match(/^```(?:markdown|md)?\s*\n([\s\S]*?)\n```$/i);
    return (match ? match[1] : trimmed).trimEnd() + "\n";
}

function textFromResponse(
    response: Awaited<ReturnType<typeof complete>>,
): string {
    return response.content
        .filter(
            (content): content is { type: "text"; text: string } =>
                content.type === "text",
        )
        .map((content) => content.text)
        .join("\n");
}

function vimString(value: string): string {
    return `'${value.replace(/'/g, "''")}'`;
}

function nvimScript(summaryPath: string): string {
    return `execute 'edit ' . fnameescape(${vimString(summaryPath)})
setlocal filetype=markdown noswapfile
`;
}

function shellQuote(value: string): string {
    return `'${value.replace(/'/g, `'\\''`)}'`;
}

// Used for clipboard/automation helpers so large/nested strings go through
// stdin instead of shell arguments, avoiding fish/POSIX/AppleScript quoting
// interactions.
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
            if (code === 0) {
                resolve();
            } else {
                reject(
                    new Error(
                        stderr.trim() || `${file} exited with code ${code}`,
                    ),
                );
            }
        });

        child.stdin.end(input);
    });
}

// This script runs inside the new Ghostty tab. On macOS the delayed Cmd+W is
// backgrounded so the shell can exit immediately after scheduling tab cleanup;
// on Linux we paste the command with `exec`, so the tab closes when this script
// exits after nvim.
function wrapperScript(nvimScriptPath: string): string {
    return `#!/bin/sh
set +e
vimscript=${shellQuote(nvimScriptPath)}
nvim -n -S "$vimscript"
status=$?
(
  sleep 0.1
  /usr/bin/osascript -e 'tell application "Ghostty" to activate' \
    -e 'tell application "System Events" to keystroke "w" using command down'
) >/dev/null 2>&1 &
exit "$status"
`;
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

function sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

function runClipboardCommand(
    file: string,
    args: string[],
    input: string,
): Promise<void> {
    return new Promise((resolve, reject) => {
        const child = spawn(file, args, {
            stdio: ["pipe", "ignore", "pipe"],
        });
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
            // Wayland/X11 clipboard tools often stay alive to serve future paste
            // requests. Once stdin is accepted, continue with Ghostty automation
            // instead of waiting forever for the clipboard owner to exit.
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

async function openInGhosttyMac(wrapperPath: string): Promise<void> {
    // Paste only a simple wrapper invocation into Ghostty; the fragile bits live
    // in the temp script where quoting is easier to control.
    const command = `command /bin/sh ${shellQuote(wrapperPath)}`;
    await copyToClipboard(command);

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

    // Replacing the new tab's shell makes Ghostty close the tab naturally when
    // nvim exits, avoiding platform-specific close-tab automation.
    const command = `exec /bin/sh ${shellQuote(wrapperPath)}`;
    await copyToClipboard(command);

    await sendHyprlandShortcut("CTRL_SHIFT,T");
    await sleep(400);
    await sendHyprlandShortcut("CTRL_SHIFT,V");
    await sleep(100);
    await sendHyprlandShortcut(",Return");
}

async function openInGhostty(wrapperPath: string): Promise<void> {
    if (process.platform === "darwin") {
        await openInGhosttyMac(wrapperPath);
        return;
    }

    if (process.platform === "linux") {
        await openInGhosttyLinux(wrapperPath);
        return;
    }

    throw new Error(
        `unsupported platform for Ghostty automation: ${process.platform}`,
    );
}

export default function ghSummaryExtension(pi: ExtensionAPI) {
    pi.registerCommand("gh-summary", {
        description:
            "Create a GitHub-ready PR title/description from git changes and open it in neovim. Usage: /gh-summary [extra context]",
        handler: async (args, ctx) => {
            if (!ctx.model) {
                ctx.ui.notify("No model selected", "error");
                return;
            }

            let changes: GitChanges;
            const model = ctx.model;
            try {
                changes = await collectGitChanges(ctx.cwd);
            } catch (error) {
                ctx.ui.notify(
                    `Failed to inspect git changes: ${(error as Error).message}`,
                    "error",
                );
                return;
            }

            if (!changes.text.trim()) {
                ctx.ui.notify(
                    "No git worktree changes or current-branch commits found",
                    "warning",
                );
                return;
            }

            ctx.ui.notify(
                `Generating PR summary from ${changes.source === "worktree" ? "git worktree" : "current branch commits"}...`,
                "info",
            );

            let summary = "";
            const extraContext = (args ?? "").trim();
            let prTemplate: string | undefined;
            let conversationContext = "";
            try {
                const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
                if (!auth.ok || !auth.apiKey) {
                    throw new Error(
                        auth.ok
                            ? `No API key for ${model.provider}`
                            : auth.error,
                    );
                }
                const apiKey = auth.apiKey;
                const headers = auth.headers;

                prTemplate = await readPrTemplate(changes.root);
                conversationContext = buildConversationContext(
                    ctx.sessionManager.getBranch() as SessionEntry[],
                );
                const userMessage: UserMessage = {
                    role: "user",
                    content: [
                        {
                            type: "text",
                            text: buildUserPrompt(
                                changes.text,
                                changes.source,
                                extraContext,
                                conversationContext,
                                prTemplate,
                            ),
                        },
                    ],
                    timestamp: Date.now(),
                };

                const response = await complete(
                    model,
                    { systemPrompt: SYSTEM_PROMPT, messages: [userMessage] },
                    { apiKey, headers },
                );

                if (response.stopReason === "aborted") {
                    ctx.ui.notify("PR summary generation cancelled", "info");
                    return;
                }

                summary = stripWrappingCodeFence(textFromResponse(response));

                if (!summary.trim()) {
                    throw new Error("Model returned an empty summary");
                }
            } catch (error) {
                ctx.ui.notify(
                    `Failed to generate PR summary: ${(error as Error).message}`,
                    "error",
                );
                return;
            }

            // Keep the generated draft and launch scripts together so the
            // notification path is enough to debug the workflow.
            const tmpDir = await mkdtemp(path.join(os.tmpdir(), "gh-summary-"));
            const summaryPath = path.join(tmpDir, "pr-description.md");
            const nvimScriptPath = path.join(tmpDir, "gh-summary.nvim.vim");
            const wrapperPath = path.join(tmpDir, "open-gh-summary.sh");

            await writeFile(summaryPath, summary, "utf8");
            await writeFile(nvimScriptPath, nvimScript(summaryPath), "utf8");
            await writeFile(wrapperPath, wrapperScript(nvimScriptPath), "utf8");
            await chmod(wrapperPath, 0o700);

            try {
                await openInGhostty(wrapperPath);
                ctx.ui.notify(
                    `Opened PR summary in Ghostty/neovim: ${summaryPath}`,
                    "info",
                );
            } catch (error) {
                ctx.ui.notify(
                    `Failed to open Ghostty/neovim: ${(error as Error).message}. Summary written to ${summaryPath}`,
                    "error",
                );
                if (ctx.hasUI) {
                    ctx.ui.setEditorText(summary);
                }
            }
        },
    });
}
