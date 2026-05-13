import { spawn } from "node:child_process";
import { chmod, mkdtemp, readFile, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { complete, type UserMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Keep the summarization request bounded while preserving enough recent context
// for the model to infer what changed and why.
const MAX_CONVERSATION_CHARS = 80_000;
const MAX_BLOCK_CHARS = 6_000;

const SYSTEM_PROMPT = `You write concise, human-sounding GitHub pull request titles and descriptions from coding-agent conversations.

Requirements:
- Use raw Markdown only; do not wrap the entire response in a code fence.
- Do not include padding or preamble like "Here’s a summary".
- Include a suggested PR title and a PR description.
- Keep the PR description to paragraphs, at most 3, unless a provided PR template requires another structure.
- Be concise, but include important facts, design decisions, results, and follow-ups when applicable.
- Use first person plural or neutral engineering voice when appropriate.`;

type ContentBlock = {
    type?: string;
    text?: string;
    name?: string;
    arguments?: Record<string, unknown>;
};

type SessionEntry = {
    type?: string;
    message?: {
        role?: string;
        content?: unknown;
    };
};

function truncate(value: string, max = MAX_BLOCK_CHARS): string {
    if (value.length <= max) return value;
    return `${value.slice(0, max)}\n...[truncated ${value.length - max} chars]`;
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

// Include tool calls because they often contain the concrete files/commands that
// explain what implementation work happened, even when assistant prose is terse.
function extractToolCallLines(content: unknown): string[] {
    if (!Array.isArray(content)) return [];

    const lines: string[] = [];
    for (const item of content) {
        if (!item || typeof item !== "object") continue;
        const block = item as ContentBlock;
        if (block.type !== "toolCall" || typeof block.name !== "string") continue;

        const args = JSON.stringify(block.arguments ?? {});
        lines.push(`Tool ${block.name}: ${truncate(args)}`);
    }
    return lines;
}

function buildConversationText(entries: SessionEntry[]): string {
    const sections: string[] = [];
    let total = 0;

    for (const entry of entries) {
        if (entry.type !== "message" || !entry.message?.role) continue;

        const role = entry.message.role;
        if (role !== "user" && role !== "assistant") continue;

        const label = role === "user" ? "User" : "Assistant";
        const lines: string[] = [];
        const text = extractTextParts(entry.message.content).join("\n").trim();
        if (text) lines.push(`${label}: ${truncate(text)}`);

        if (role === "assistant") {
            lines.push(...extractToolCallLines(entry.message.content));
        }

        if (lines.length === 0) continue;

        const section = lines.join("\n");
        if (total + section.length > MAX_CONVERSATION_CHARS) {
            const remaining = MAX_CONVERSATION_CHARS - total;
            if (remaining > 500) {
                sections.push(truncate(section, remaining));
            }
            sections.push("...[conversation truncated]");
            break;
        }

        sections.push(section);
        total += section.length;
    }

    return sections.join("\n\n");
}

// Match GitHub's common single-file PR template location; absence is normal.
async function readPrTemplate(cwd: string): Promise<string | undefined> {
    try {
        const templatePath = path.join(cwd, ".github", "PULL_REQUEST_TEMPLATE.md");
        const template = await readFile(templatePath, "utf8");
        return template.trim() || undefined;
    } catch (error) {
        const code = (error as NodeJS.ErrnoException).code;
        if (code === "ENOENT" || code === "ENOTDIR") return undefined;
        throw error;
    }
}

function buildUserPrompt(conversationText: string, prTemplate?: string): string {
    const templateSection = prTemplate
        ? [
              "Use this GitHub PR template for the description if possible:",
              "<pull_request_template>",
              prTemplate,
              "</pull_request_template>",
              "",
          ].join("\n")
        : "";

    return [
        "Summarize the current conversation into a concise GitHub-ready PR description, together with a suggested title.",
        "",
        templateSection,
        "Output format:",
        "Title: <suggested PR title>",
        "",
        "<PR description markdown>",
        "",
        "Conversation:",
        "<conversation>",
        conversationText,
        "</conversation>",
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
function runWithInput(file: string, args: string[], input: string): Promise<void> {
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
                reject(new Error(stderr.trim() || `${file} exited with code ${code}`));
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
  /usr/bin/osascript -e 'tell application "Ghostty" to activate' \\
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
        description: "Create a GitHub-ready PR title/description and open it in Ghostty/neovim",
        handler: async (_args, ctx) => {
            if (!ctx.model) {
                ctx.ui.notify("No model selected", "error");
                return;
            }

            const conversationText = buildConversationText(ctx.sessionManager.getBranch() as SessionEntry[]);
            if (!conversationText.trim()) {
                ctx.ui.notify("No conversation text found", "warning");
                return;
            }

            ctx.ui.notify("Generating PR summary...", "info");

            let summary = "";
            try {
                const auth = await ctx.modelRegistry.getApiKeyAndHeaders(ctx.model);
                if (!auth.ok || !auth.apiKey) {
                    throw new Error(auth.ok ? `No API key for ${ctx.model.provider}` : auth.error);
                }

                const prTemplate = await readPrTemplate(ctx.cwd);
                const userMessage: UserMessage = {
                    role: "user",
                    content: [{ type: "text", text: buildUserPrompt(conversationText, prTemplate) }],
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
                        .filter((c): c is { type: "text"; text: string } => c.type === "text")
                        .map((c) => c.text)
                        .join("\n"),
                );

                if (!summary.trim()) {
                    throw new Error("Model returned an empty summary");
                }
            } catch (error) {
                ctx.ui.notify(`Failed to generate PR summary: ${(error as Error).message}`, "error");
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
                ctx.ui.notify(`Opened PR summary in Ghostty/neovim: ${summaryPath}`, "info");
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
