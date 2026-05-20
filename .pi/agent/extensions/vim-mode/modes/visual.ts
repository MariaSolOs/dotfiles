/**
 * Visual mode handler.
 * Supports character-wise (v) and line-wise (V) visual selection.
 * Motions extend the selection, operators act on it.
 */

import type { VimState } from "../state.js";
import { resetOperatorState } from "../state.js";
import { isDigit, ESCAPE_SEQS } from "../keys.js";
import { matchesKey } from "@earendil-works/pi-tui";
import {
    wordForward,
    wordBackward,
    wordEnd,
    WORDForward,
    WORDBackward,
    WORDEnd,
    goToFirstLine,
    goToLastLine,
    firstNonBlank,
    lineStart,
    lineEnd,
    findCharForward,
    findCharBackward,
    tillCharForward,
    tillCharBackward,
    repeatCharSearch,
    reverseCharSearch,
    paragraphBackward,
    paragraphForward,
    matchingBracket,
    type MotionFn,
} from "../motions.js";
import {
    applyOperator,
    deleteRange,
    extractText,
    type OperatorRange,
} from "../operators.js";
import { resolveTextObject } from "../text-objects.js";
import {
    isValidRegister,
    getRegister,
    deleteToRegister,
} from "../registers.js";
import type { Position } from "../motions.js";
import { searchNext, searchPrev, searchWordUnderCursor } from "../search.js";

export interface VisualModeContext {
    state: VimState;
    superHandleInput: (data: string) => void;
    getText: () => string;
    getCursor: () => { line: number; col: number };
    setText: (text: string) => void;
    moveCursorTo: (line: number, col: number) => void;
}

/**
 * Compute the operator range for the current visual selection.
 */
export function getVisualRange(
    state: VimState,
    cursor: Position,
    lines: string[],
): OperatorRange {
    const anchor = state.visualAnchor!;
    const isLinewise = state.mode === "visual-line";

    let start: Position;
    let end: Position;

    if (
        anchor.line < cursor.line ||
        (anchor.line === cursor.line && anchor.col <= cursor.col)
    ) {
        start = anchor;
        end = cursor;
    } else {
        start = cursor;
        end = anchor;
    }

    if (isLinewise) {
        return {
            start: { line: start.line, col: 0 },
            end: { line: end.line, col: (lines[end.line] || "").length },
            linewise: true,
            inclusive: true,
        };
    }

    return {
        start,
        end,
        linewise: false,
        inclusive: true,
    };
}

/**
 * Execute a motion in visual mode - moves cursor, extending selection.
 */
function executeVisualMotion(
    motion: MotionFn,
    ctx: VisualModeContext,
    count: number,
): void {
    const lines = ctx.getText().split("\n");
    const cursor = ctx.getCursor();
    const result = motion(lines, cursor, count);
    ctx.moveCursorTo(result.position.line, result.position.col);
}

/**
 * Apply an operator to the visual selection and return to normal mode.
 */
function applyVisualOperator(ctx: VisualModeContext, operator: string): void {
    const lines = ctx.getText().split("\n");
    const cursor = ctx.getCursor();
    const range = getVisualRange(ctx.state, cursor, lines);
    const register = ctx.state.register;

    const result = applyOperator(operator, lines, range, register);

    ctx.setText(result.newLines.join("\n"));
    ctx.moveCursorTo(result.cursor.line, result.cursor.col);

    ctx.state.visualAnchor = null;
    ctx.state.mode = result.enterInsert ? "insert" : "normal";
    resetOperatorState(ctx.state);
}

/**
 * Handle input in visual mode (both character-wise and line-wise).
 */
export function handleVisualMode(
    data: string,
    ctx: VisualModeContext,
): boolean {
    const { state } = ctx;

    // --- Escape / Ctrl+[ → return to normal ---
    if (matchesKey(data, "escape") || data === "\x1b" || data === "\x03") {
        state.visualAnchor = null;
        state.mode = "normal";
        resetOperatorState(state);
        return true;
    }

    // --- Pending register selection (after `"`) ---
    if (state.pendingRegister) {
        state.pendingRegister = false;
        if (data.length === 1 && isValidRegister(data)) {
            state.register = data;
        } else {
            // Unsupported register, cancel/reset without selecting it
            resetOperatorState(state);
        }
        return true;
    }

    // --- Pending text object key (after 'i' or 'a') ---
    if (state.pendingTextObjectPrefix) {
        const prefix = state.pendingTextObjectPrefix;
        state.pendingTextObjectPrefix = null;

        const textObjFn = resolveTextObject(prefix, data);
        if (textObjFn) {
            const lines = ctx.getText().split("\n");
            const cursor = ctx.getCursor();
            const range = textObjFn(lines, cursor);

            if (range) {
                // In visual mode, text objects set the selection to the text object range
                state.visualAnchor = {
                    line: range.start.line,
                    col: range.start.col,
                };
                ctx.moveCursorTo(range.end.line, range.end.col);
            }
        }
        resetOperatorState(state);
        return true;
    }

    // --- Pending character input for f/F/t/T ---
    if (state.pendingCharMotion) {
        const pending = state.pendingCharMotion;
        state.pendingCharMotion = null;

        if (data.length === 1 && data.charCodeAt(0) >= 32) {
            const count = state.count || 1;
            let motionFn: MotionFn;

            switch (pending) {
                case "f":
                    motionFn = findCharForward(data);
                    break;
                case "F":
                    motionFn = findCharBackward(data);
                    break;
                case "t":
                    motionFn = tillCharForward(data);
                    break;
                case "T":
                    motionFn = tillCharBackward(data);
                    break;
                default:
                    resetOperatorState(state);
                    return true;
            }

            executeVisualMotion(motionFn, ctx, count);
            resetOperatorState(state);
            return true;
        }

        resetOperatorState(state);
        return true;
    }

    // --- Pending `g` prefix ---
    if (state.pendingG) {
        state.pendingG = false;

        if (data === "g") {
            const count = state.count || 1;
            const countExplicit = state.countStarted;
            executeVisualMotion(goToFirstLine, ctx, countExplicit ? count : 1);
            resetOperatorState(state);
            return true;
        }

        resetOperatorState(state);
        return true;
    }

    // --- Count prefix ---
    if (isDigit(data) && (data !== "0" || state.countStarted)) {
        state.count = state.count * 10 + parseInt(data, 10);
        state.countStarted = true;
        return true;
    }

    const count = state.count || 1;
    const countExplicit = state.countStarted;

    // --- Operators apply to visual selection ---
    if (data === "d" || data === "x") {
        applyVisualOperator(ctx, "d");
        return true;
    }

    if (data === "c" || data === "s") {
        applyVisualOperator(ctx, "c");
        return true;
    }

    if (data === "y") {
        applyVisualOperator(ctx, "y");
        return true;
    }

    if (data === ">") {
        applyVisualOperator(ctx, ">");
        return true;
    }

    if (data === "<") {
        applyVisualOperator(ctx, "<");
        return true;
    }

    if (data === "D") {
        // In visual mode, D deletes the selection (same as d)
        applyVisualOperator(ctx, "d");
        return true;
    }

    if (data === "C") {
        applyVisualOperator(ctx, "c");
        return true;
    }

    if (data === "Y") {
        // In visual mode, Y yanks the selection
        applyVisualOperator(ctx, "y");
        return true;
    }

    // --- Paste in visual mode (replaces selection with register contents) ---
    if (data === "p" || data === "P") {
        const reg = getRegister(state.register);
        if (reg) {
            const lines = ctx.getText().split("\n");
            const cursor = ctx.getCursor();
            const range = getVisualRange(state, cursor, lines);

            // Delete selection
            const deletedText = extractText(lines, range);
            const deleteResult = deleteRange(lines, range);

            // Insert the register content at the delete position
            const newLines = deleteResult.newLines;
            const pos = deleteResult.cursor;

            if (reg.linewise) {
                const pasteLines = reg.text.split("\n");
                if (range.linewise) {
                    newLines.splice(pos.line, 0, ...pasteLines);
                } else {
                    newLines.splice(pos.line + 1, 0, ...pasteLines);
                }
                ctx.setText(newLines.join("\n"));
                const targetLine = range.linewise ? pos.line : pos.line + 1;
                const match = (pasteLines[0] || "").match(/^\s*/);
                ctx.moveCursorTo(targetLine, match ? match[0].length : 0);
            } else {
                const line = newLines[pos.line] || "";
                const pasteLines = reg.text.split("\n");

                if (pasteLines.length === 1) {
                    newLines[pos.line] =
                        line.substring(0, pos.col) +
                        reg.text +
                        line.substring(pos.col);
                    ctx.setText(newLines.join("\n"));
                    ctx.moveCursorTo(pos.line, pos.col + reg.text.length - 1);
                } else {
                    const before = line.substring(0, pos.col);
                    const after = line.substring(pos.col);
                    const merged = [
                        before + pasteLines[0],
                        ...pasteLines.slice(1, -1),
                        pasteLines[pasteLines.length - 1] + after,
                    ];
                    newLines.splice(pos.line, 1, ...merged);
                    ctx.setText(newLines.join("\n"));
                    const lastIdx = pos.line + pasteLines.length - 1;
                    const lastCol =
                        (pasteLines[pasteLines.length - 1] || "").length - 1;
                    ctx.moveCursorTo(lastIdx, Math.max(0, lastCol));
                }
            }

            // Store deleted text in unnamed register (vim behavior: deleted text goes to "")
            deleteToRegister('"', deletedText, range.linewise);
        }

        state.visualAnchor = null;
        state.mode = "normal";
        resetOperatorState(state);
        return true;
    }

    // --- Register selection prefix ---
    if (data === '"') {
        state.pendingRegister = true;
        return true;
    }

    // --- Text object prefixes ---
    if (data === "i" || data === "a") {
        state.pendingTextObjectPrefix = data;
        return true;
    }

    // --- Mode switching ---
    if (data === "v") {
        if (state.mode === "visual") {
            // v in visual → back to normal
            state.visualAnchor = null;
            state.mode = "normal";
        } else {
            // V (visual-line) → switch to visual (character-wise)
            state.mode = "visual";
        }
        resetOperatorState(state);
        return true;
    }

    if (data === "V") {
        if (state.mode === "visual-line") {
            // V in visual-line → back to normal
            state.visualAnchor = null;
            state.mode = "normal";
        } else {
            // visual → switch to visual-line
            state.mode = "visual-line";
        }
        resetOperatorState(state);
        return true;
    }

    // --- `o` - swap cursor and anchor ---
    if (data === "o" || data === "O") {
        if (state.visualAnchor) {
            const cursor = ctx.getCursor();
            const anchor = { ...state.visualAnchor };
            state.visualAnchor = { line: cursor.line, col: cursor.col };
            ctx.moveCursorTo(anchor.line, anchor.col);
        }
        resetOperatorState(state);
        return true;
    }

    // --- Join lines (J) ---
    if (data === "J") {
        const lines = ctx.getText().split("\n");
        const cursor = ctx.getCursor();
        const range = getVisualRange(state, cursor, lines);
        const startLine = range.start.line;
        const endLine = range.end.line;

        if (endLine > startLine) {
            const newLines = [...lines];
            let joinLine = startLine;
            for (let i = startLine; i < endLine; i++) {
                const currentLine = newLines[joinLine]!;
                const nextLine = (newLines[joinLine + 1] || "").replace(
                    /^\s+/,
                    "",
                );
                const joinCol = currentLine.length;
                newLines[joinLine] =
                    currentLine + (nextLine.length > 0 ? " " + nextLine : "");
                newLines.splice(joinLine + 1, 1);
            }
            ctx.setText(newLines.join("\n"));
            ctx.moveCursorTo(startLine, 0);
        }

        state.visualAnchor = null;
        state.mode = "normal";
        resetOperatorState(state);
        return true;
    }

    // --- Toggle case (~) ---
    if (data === "~") {
        const lines = ctx.getText().split("\n");
        const cursor = ctx.getCursor();
        const range = getVisualRange(state, cursor, lines);
        const newLines = [...lines];

        if (range.linewise) {
            for (let ln = range.start.line; ln <= range.end.line; ln++) {
                newLines[ln] = toggleCaseLine(newLines[ln] || "");
            }
        } else if (range.start.line === range.end.line) {
            const line = newLines[range.start.line] || "";
            newLines[range.start.line] =
                line.substring(0, range.start.col) +
                toggleCaseLine(
                    line.substring(range.start.col, range.end.col + 1),
                ) +
                line.substring(range.end.col + 1);
        } else {
            // Multi-line character-wise
            const firstLine = newLines[range.start.line] || "";
            newLines[range.start.line] =
                firstLine.substring(0, range.start.col) +
                toggleCaseLine(firstLine.substring(range.start.col));
            for (let ln = range.start.line + 1; ln < range.end.line; ln++) {
                newLines[ln] = toggleCaseLine(newLines[ln] || "");
            }
            const lastLine = newLines[range.end.line] || "";
            newLines[range.end.line] =
                toggleCaseLine(lastLine.substring(0, range.end.col + 1)) +
                lastLine.substring(range.end.col + 1);
        }

        ctx.setText(newLines.join("\n"));
        ctx.moveCursorTo(range.start.line, range.start.col);

        state.visualAnchor = null;
        state.mode = "normal";
        resetOperatorState(state);
        return true;
    }

    // --- Motions ---
    switch (data) {
        case "h":
            for (let i = 0; i < count; i++)
                ctx.superHandleInput(ESCAPE_SEQS.left);
            resetOperatorState(state);
            return true;

        case "j":
            for (let i = 0; i < count; i++)
                ctx.superHandleInput(ESCAPE_SEQS.down);
            resetOperatorState(state);
            return true;

        case "k":
            for (let i = 0; i < count; i++)
                ctx.superHandleInput(ESCAPE_SEQS.up);
            resetOperatorState(state);
            return true;

        case "l":
            for (let i = 0; i < count; i++)
                ctx.superHandleInput(ESCAPE_SEQS.right);
            resetOperatorState(state);
            return true;

        case "0":
            executeVisualMotion(lineStart, ctx, 1);
            resetOperatorState(state);
            return true;

        case "$":
            executeVisualMotion(lineEnd, ctx, count);
            resetOperatorState(state);
            return true;

        case "^":
            executeVisualMotion(firstNonBlank, ctx, 1);
            resetOperatorState(state);
            return true;

        case "w":
            executeVisualMotion(wordForward, ctx, count);
            resetOperatorState(state);
            return true;

        case "b":
            executeVisualMotion(wordBackward, ctx, count);
            resetOperatorState(state);
            return true;

        case "e":
            executeVisualMotion(wordEnd, ctx, count);
            resetOperatorState(state);
            return true;

        case "W":
            executeVisualMotion(WORDForward, ctx, count);
            resetOperatorState(state);
            return true;

        case "B":
            executeVisualMotion(WORDBackward, ctx, count);
            resetOperatorState(state);
            return true;

        case "E":
            executeVisualMotion(WORDEnd, ctx, count);
            resetOperatorState(state);
            return true;

        case "f":
        case "F":
        case "t":
        case "T":
            state.pendingCharMotion = data;
            return true;

        case ";":
            executeVisualMotion(repeatCharSearch, ctx, count);
            resetOperatorState(state);
            return true;

        case ",":
            executeVisualMotion(reverseCharSearch, ctx, count);
            resetOperatorState(state);
            return true;

        case "g":
            state.pendingG = true;
            return true;

        case "G":
            if (countExplicit) {
                executeVisualMotion(goToLastLine, ctx, count);
            } else {
                const lines = ctx.getText().split("\n");
                executeVisualMotion(goToLastLine, ctx, lines.length);
            }
            resetOperatorState(state);
            return true;

        case "{":
            executeVisualMotion(paragraphBackward, ctx, count);
            resetOperatorState(state);
            return true;

        case "}":
            executeVisualMotion(paragraphForward, ctx, count);
            resetOperatorState(state);
            return true;

        case "%":
            executeVisualMotion(matchingBracket, ctx, 1);
            resetOperatorState(state);
            return true;

        // === Search motions ===
        case "n":
            executeVisualMotion(searchNext, ctx, count);
            resetOperatorState(state);
            return true;

        case "N":
            executeVisualMotion(searchPrev, ctx, count);
            resetOperatorState(state);
            return true;

        case "*": {
            const sLines = ctx.getText().split("\n");
            const sCursor = ctx.getCursor();
            const sResult = searchWordUnderCursor(sLines, sCursor, "forward");
            ctx.moveCursorTo(sResult.position.line, sResult.position.col);
            resetOperatorState(state);
            return true;
        }

        case "#": {
            const sLines = ctx.getText().split("\n");
            const sCursor = ctx.getCursor();
            const sResult = searchWordUnderCursor(sLines, sCursor, "backward");
            ctx.moveCursorTo(sResult.position.line, sResult.position.col);
            resetOperatorState(state);
            return true;
        }

        default:
            break;
    }

    // Pass control sequences through
    resetOperatorState(state);
    if (data.length === 1 && data.charCodeAt(0) < 32) {
        ctx.superHandleInput(data);
        return true;
    }
    if (data.length > 1 && data.startsWith("\x1b")) {
        ctx.superHandleInput(data);
        return true;
    }

    return true;
}

function toggleCaseLine(s: string): string {
    let result = "";
    for (const ch of s) {
        result += ch === ch.toLowerCase() ? ch.toUpperCase() : ch.toLowerCase();
    }
    return result;
}
