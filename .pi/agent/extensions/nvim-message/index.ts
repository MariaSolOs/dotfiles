import type {
    ExtensionAPI,
    SessionEntry,
} from "@earendil-works/pi-coding-agent";
import { openMarkdownPane, prepareEditorPane } from "../gh-summary/editor.js";

// Text of the most recent assistant message on the active branch. Messages
// made only of tool calls or thinking are skipped so the result is the last
// prose reply the agent wrote, exactly as the model emitted it (raw Markdown).
function lastAssistantText(entries: SessionEntry[]): string | undefined {
    for (let i = entries.length - 1; i >= 0; i--) {
        const entry = entries[i];
        if (entry.type !== "message" || entry.message.role !== "assistant") {
            continue;
        }
        const text = entry.message.content
            .flatMap((block) => (block.type === "text" ? [block.text] : []))
            .join("\n\n");
        if (text.trim()) return text;
    }
    return undefined;
}

export default function nvimMessageExtension(pi: ExtensionAPI) {
    pi.registerCommand("nvim-message", {
        description:
            "Open the last agent message as raw Markdown in a right-hand Ghostty/neovim pane",
        handler: async (_args, ctx) => {
            const markdown = lastAssistantText(ctx.sessionManager.getBranch());
            if (!markdown) {
                ctx.ui.notify("No agent message found", "warning");
                return;
            }

            const run = async (file: string, argv: string[]) => {
                const result = await pi.exec(file, argv, { timeout: 30_000 });
                if (result.code !== 0 || result.killed) {
                    throw new Error(
                        result.stderr.trim() || `${file} failed or timed out`,
                    );
                }
                return result.stdout;
            };

            // Reuse /gh-summary's Ghostty split (native on macOS, Hyprland
            // shortcuts on Linux). The pane's wrapper deletes the temporary
            // copy when nvim exits; nothing is read back, so no handoff.
            try {
                const pane = await prepareEditorPane(run);
                await openMarkdownPane(run, pane, markdown, "agent-message");
            } catch (error) {
                ctx.ui.notify(
                    `Failed to open Ghostty/neovim: ${(error as Error).message}`,
                    "error",
                );
            }
        },
    });
}
