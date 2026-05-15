/**
 * Replace mode handler (R command).
 * Overtypes characters at cursor position instead of inserting.
 * Backspace restores the original character.
 * Escape returns to normal mode.
 */

import type { VimState } from "../state.js";
import { matchesKey } from "@earendil-works/pi-tui";
import {
    isCurrentlyRecording,
    isRecordingInsertMode,
    recordInsertText,
    recordInsertBackspace,
    finalizeRecording,
} from "../repeat.js";

export interface ReplaceModeContext {
    state: VimState;
    getCursor: () => { line: number; col: number };
    getText: () => string;
    setText: (text: string) => void;
    moveCursorTo: (line: number, col: number) => void;
    superHandleInput: (data: string) => void;
}

/** Stack of original characters replaced during this replace session, for backspace undo */
let replacedChars: string[] = [];

/**
 * Reset replace mode state (call when entering replace mode).
 */
export function resetReplaceState(): void {
    replacedChars = [];
}

/**
 * Handle input in replace mode.
 */
export function handleReplaceMode(
    data: string,
    ctx: ReplaceModeContext,
): boolean {
    // Escape or Ctrl+[ → switch to normal mode
    if (matchesKey(data, "escape") || data === "\x1b") {
        ctx.state.mode = "normal";
        // Move cursor left one position (vim behavior)
        if (ctx.getCursor().col > 0) {
            ctx.superHandleInput("\x1b[D");
        }
        if (isCurrentlyRecording()) {
            finalizeRecording();
        }
        replacedChars = [];
        return true;
    }

    // Ctrl+C → switch to normal mode
    if (data === "\x03") {
        ctx.state.mode = "normal";
        if (isCurrentlyRecording()) {
            finalizeRecording();
        }
        replacedChars = [];
        return true;
    }

    // Backspace → restore the original character and move back
    if (data === "\x7f") {
        const cursor = ctx.getCursor();
        if (cursor.col > 0 && replacedChars.length > 0) {
            const originalChar = replacedChars.pop()!;
            const lines = ctx.getText().split("\n");
            const line = lines[cursor.line] || "";
            // Restore original character at previous position
            const col = cursor.col - 1;
            lines[cursor.line] =
                line.substring(0, col) + originalChar + line.substring(col + 1);
            ctx.setText(lines.join("\n"));
            ctx.moveCursorTo(cursor.line, col);

            if (isCurrentlyRecording() && isRecordingInsertMode()) {
                recordInsertBackspace();
            }
        }
        return true;
    }

    // Enter/Return → move to start of next line (like vim)
    if (data === "\n" || data === "\r") {
        const lines = ctx.getText().split("\n");
        const cursor = ctx.getCursor();
        // Insert a newline (splitting the line)
        const line = lines[cursor.line] || "";
        const before = line.substring(0, cursor.col);
        const after = line.substring(cursor.col);
        lines.splice(cursor.line, 1, before, after);
        ctx.setText(lines.join("\n"));
        ctx.moveCursorTo(cursor.line + 1, 0);
        replacedChars.push(""); // marker for newline (can't undo back past this simply)

        if (isCurrentlyRecording() && isRecordingInsertMode()) {
            recordInsertText("\n");
        }
        return true;
    }

    // Printable character → overtype
    if (data.length === 1 && data.charCodeAt(0) >= 32) {
        const lines = ctx.getText().split("\n");
        const cursor = ctx.getCursor();
        const line = lines[cursor.line] || "";

        if (cursor.col < line.length) {
            // Replace character at cursor
            replacedChars.push(line[cursor.col]!);
            lines[cursor.line] =
                line.substring(0, cursor.col) +
                data +
                line.substring(cursor.col + 1);
            ctx.setText(lines.join("\n"));
            ctx.moveCursorTo(cursor.line, cursor.col + 1);
        } else {
            // At end of line: append (like insert)
            replacedChars.push(""); // nothing to restore
            lines[cursor.line] = line + data;
            ctx.setText(lines.join("\n"));
            ctx.moveCursorTo(cursor.line, cursor.col + 1);
        }

        if (isCurrentlyRecording() && isRecordingInsertMode()) {
            recordInsertText(data);
        }
        return true;
    }

    // Pass other control sequences through
    ctx.superHandleInput(data);
    return true;
}
