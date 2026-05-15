/**
 * Local vim-mode extension for Pi.
 *
 * Adapted from burneikis/pi-vim (MIT):
 * https://github.com/burneikis/pi-vim
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { VimEditor } from "./vim-editor.js";

export default function (pi: ExtensionAPI) {
    pi.on("session_start", (_event, ctx) => {
        ctx.ui.setEditorComponent(
            (tui, theme, keybindings) => new VimEditor(tui, theme, keybindings),
        );
    });
}
