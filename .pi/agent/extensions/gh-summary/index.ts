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
const MAX_UNTRACKED_FILES = 25;
const MAX_UNTRACKED_READ_BYTES = 256_000;
const MAX_UNTRACKED_FILE_CHARS = 12_000;

const SYSTEM_PROMPT = `You write concise, human-sounding GitHub pull request titles and descriptions from git worktree changes.

Requirements:
- Base the PR summary primarily on the provided git status, diffs, and untracked file contents.
- Use the provided conversation context only to understand intent, rationale, constraints, or wording around those worktree changes.
- Do not summarize unrelated conversation history or mention work that is not reflected in the worktree changes.
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

type WorktreeChanges = {
    root: string;
    text: string;
};

async function collectWorktreeChanges(cwd: string): Promise<WorktreeChanges> {
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

    if (!status.trim()) return { root, text: "" };

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

    return { root, text: sections.join("\n\n") };
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

    const conversationSection = conversationContext.trim()
        ? [
              "Supplemental conversation context. Use this only to clarify intent/rationale for the worktree changes; do not summarize unrelated parts of the conversation:",
              "<conversation_context>",
              conversationContext,
              "</conversation_context>",
              "",
          ].join("\n")
        : "";

    return [
        "Summarize the current git worktree changes into a concise GitHub-ready PR description, together with a suggested title.",
        "Focus on what changed in the worktree. Use conversation context only as supporting context for those changes, not as the thing being summarized.",
        "",
        templateSection,
        conversationSection,
        "Output format:",
        "Title: <suggested PR title>",
        "",
        "<PR description markdown>",
        "",
        "Git worktree changes:",
        "<git_worktree_changes>",
        changesText,
        "</git_worktree_changes>",
    ].join("\n");
}

// The prompt forbids wrapping fences, but strip one anyway so the temp file is
// directly pasteable into GitHub if the model ignores that instruction.
function stripWrappingCodeFence(text: string): string {
    const trimmed = text.trim();
    const match = trimmed.match(/^```(?:markdown|md)?\s*\n([\s\S]*?)\n```$/i);
    return (match ? match[1] : trimmed).trimEnd() + "\n";
}

function shellQuote(value: string): string {
    return `'${value.replace(/'/g, `'\\''`)}'`;
}

// Used for pbcopy and osascript so large/nested strings go through stdin instead
// of shell arguments, avoiding fish/POSIX/AppleScript quoting interactions.
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

// This script runs inside the new Ghostty tab. The delayed Cmd+W is backgrounded
// so the shell can exit immediately after scheduling tab cleanup.
function wrapperScript(summaryPath: string): string {
    return `#!/bin/sh
set +e
tmpfile=${shellQuote(summaryPath)}
nvim -n +'setlocal filetype=markdown buftype=nofile bufhidden=wipe noswapfile' +'setlocal nomodified' "$tmpfile"
status=$?
(
  sleep 0.1
  /usr/bin/osascript -e 'tell application "Ghostty" to activate' \
    -e 'tell application "System Events" to keystroke "w" using command down'
) >/dev/null 2>&1 &
exit "$status"
`;
}

async function openInGhostty(wrapperPath: string): Promise<void> {
    // Paste only a simple wrapper invocation into Ghostty; the fragile bits live
    // in the temp script where quoting is easier to control.
    const command = `command /bin/sh ${shellQuote(wrapperPath)}`;
    await runWithInput("/usr/bin/pbcopy", [], command);

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

export default function ghSummaryExtension(pi: ExtensionAPI) {
    pi.registerCommand("gh-summary", {
        description:
            "Create a GitHub-ready PR title/description from the git worktree and open it in Ghostty/neovim",
        handler: async (_args, ctx) => {
            if (!ctx.model) {
                ctx.ui.notify("No model selected", "error");
                return;
            }

            let changes: WorktreeChanges;
            try {
                changes = await collectWorktreeChanges(ctx.cwd);
            } catch (error) {
                ctx.ui.notify(
                    `Failed to inspect git worktree: ${(error as Error).message}`,
                    "error",
                );
                return;
            }

            if (!changes.text.trim()) {
                ctx.ui.notify("No git worktree changes found", "warning");
                return;
            }

            ctx.ui.notify("Generating PR summary from git worktree...", "info");

            let summary = "";
            try {
                const auth = await ctx.modelRegistry.getApiKeyAndHeaders(
                    ctx.model,
                );
                if (!auth.ok || !auth.apiKey) {
                    throw new Error(
                        auth.ok
                            ? `No API key for ${ctx.model.provider}`
                            : auth.error,
                    );
                }

                const prTemplate = await readPrTemplate(changes.root);
                const conversationContext = buildConversationContext(
                    ctx.sessionManager.getBranch() as SessionEntry[],
                );
                const userMessage: UserMessage = {
                    role: "user",
                    content: [
                        {
                            type: "text",
                            text: buildUserPrompt(
                                changes.text,
                                conversationContext,
                                prTemplate,
                            ),
                        },
                    ],
                    timestamp: Date.now(),
                };

                const response = await complete(
                    ctx.model,
                    { systemPrompt: SYSTEM_PROMPT, messages: [userMessage] },
                    { apiKey: auth.apiKey, headers: auth.headers },
                );

                if (response.stopReason === "aborted") {
                    ctx.ui.notify("PR summary generation cancelled", "info");
                    return;
                }

                summary = stripWrappingCodeFence(
                    response.content
                        .filter(
                            (c): c is { type: "text"; text: string } =>
                                c.type === "text",
                        )
                        .map((c) => c.text)
                        .join("\n"),
                );

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

            // Keep both files together so the notification path is enough to
            // inspect or rerun the generated workflow while debugging.
            const tmpDir = await mkdtemp(path.join(os.tmpdir(), "gh-summary-"));
            const summaryPath = path.join(tmpDir, "pr-description.md");
            const wrapperPath = path.join(tmpDir, "open-gh-summary.sh");

            await writeFile(summaryPath, summary, "utf8");
            await writeFile(wrapperPath, wrapperScript(summaryPath), "utf8");
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
