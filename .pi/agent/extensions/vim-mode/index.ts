/**
 * Local vim-mode extension for Pi.
 *
 * Adapted from burneikis/pi-vim (MIT):
 * https://github.com/burneikis/pi-vim
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { VimEditor } from "./vim-editor.js";

export default function (pi: ExtensionAPI) {
    pi.on("session_start", (event, ctx) => {
        ctx.ui.setEditorComponent((tui, theme, keybindings) => {
            const editor = new VimEditor(tui, theme, keybindings);

            // Reload rebuilds history before installing the replacement editor,
            // and Pi only copies its text, not its history. Restore the active
            // branch here; other session starts populate history after this hook.
            if (event.reason === "reload") {
                for (const entry of ctx.sessionManager.getBranch()) {
                    if (
                        entry.type !== "message" ||
                        entry.message.role !== "user"
                    ) {
                        continue;
                    }
                    const { content } = entry.message;
                    const text =
                        typeof content === "string"
                            ? content
                            : content
                                  .filter((block) => block.type === "text")
                                  .map((block) => block.text)
                                  .join("\n");
                    editor.addToHistory(text);
                }
            }

            return editor;
        });
    });
}
