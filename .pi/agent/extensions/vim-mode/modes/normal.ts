/**
 * Normal mode handler.
 * Implements vim motions, operators, text objects, mode switching, count prefixes, and pending key states.
 */

import type { VimState } from "../state.js";
import { resetOperatorState } from "../state.js";
import { isDigit, ESCAPE_SEQS } from "../keys.js";
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
    type MotionResult,
} from "../motions.js";
import {
    motionToRange,
    textObjectToRange,
    applyOperator,
    type OperatorRange,
} from "../operators.js";
import { resolveTextObject } from "../text-objects.js";
import { getRegister, isValidRegister } from "../registers.js";
import {
    startRecording,
    recordKey,
    markInsertEntry,
    finalizeRecording,
    getLastChange,
    isCurrentlyRecording,
} from "../repeat.js";
import { resetReplaceState } from "./replace.js";
import { searchNext, searchPrev, searchWordUnderCursor } from "../search.js";

export interface NormalModeContext {
    state: VimState;
    superHandleInput: (data: string) => void;
    getText: () => string;
    getCursor: () => { line: number; col: number };
    setText: (text: string) => void;
    moveCursorTo: (line: number, col: number) => void;
    undo: () => void;
    redo: () => void;
}

/**
 * Execute a motion and move the cursor to the result.
 * If an operator is pending, apply the operator to the motion range instead.
 */
function executeMotion(
    motion: MotionFn,
    ctx: NormalModeContext,
    count: number,
): void {
    const lines = ctx.getText().split("\n");
    const cursor = ctx.getCursor();
    const result = motion(lines, cursor, count);

    if (ctx.state.pendingOperator) {
        applyOperatorWithMotion(ctx, lines, cursor, result);
    } else {
        ctx.moveCursorTo(result.position.line, result.position.col);
    }
}

/**
 * Apply a pending operator using a motion result.
 */
function applyOperatorWithMotion(
    ctx: NormalModeContext,
    lines: string[],
    cursor: { line: number; col: number },
    motionResult: MotionResult,
): void {
    const range = motionToRange(cursor, motionResult);
    applyOperatorToRange(ctx, lines, range);
}

/**
 * Apply a pending operator to a given range.
 */
function applyOperatorToRange(
    ctx: NormalModeContext,
    lines: string[],
    range: OperatorRange,
): void {
    const operator = ctx.state.pendingOperator!;
    const register = ctx.state.register;

    const result = applyOperator(operator, lines, range, register);

    ctx.setText(result.newLines.join("\n"));
    ctx.moveCursorTo(result.cursor.line, result.cursor.col);

    if (result.enterInsert) {
        ctx.state.mode = "insert";
        // Mark insert entry for dot-repeat (e.g., `cw` enters insert)
        if (isCurrentlyRecording()) {
            markInsertEntry();
        }
    } else {
        // Operator completed without entering insert — finalize recording
        finalizeChangeRecording(ctx.state);
    }

    resetOperatorState(ctx.state);
}

/**
 * Apply a linewise operator for doubled operators (dd, cc, yy, >>, <<).
 */
function applyLinewiseOperator(
    ctx: NormalModeContext,
    operator: string,
    count: number,
): void {
    const lines = ctx.getText().split("\n");
    const cursor = ctx.getCursor();
    const endLine = Math.min(cursor.line + count - 1, lines.length - 1);

    const range: OperatorRange = {
        start: { line: cursor.line, col: 0 },
        end: { line: endLine, col: (lines[endLine] || "").length },
        linewise: true,
        inclusive: true,
    };

    const register = ctx.state.register;
    const result = applyOperator(operator, lines, range, register);

    ctx.setText(result.newLines.join("\n"));
    ctx.moveCursorTo(result.cursor.line, result.cursor.col);

    if (result.enterInsert) {
        ctx.state.mode = "insert";
        if (isCurrentlyRecording()) {
            markInsertEntry();
        }
    } else {
        finalizeChangeRecording(ctx.state);
    }

    resetOperatorState(ctx.state);
}

/**
 * Handle input in normal mode.
 * Returns true if the key was handled.
 */
export function handleNormalMode(
    data: string,
    ctx: NormalModeContext,
): boolean {
    const { state } = ctx;

    // --- Pending register selection (after `"`) ---
    if (state.pendingRegister) {
        state.pendingRegister = false;
        if (data.length === 1 && isValidRegister(data)) {
            state.register = data;
            // Record for dot-repeat
            if (isCurrentlyRecording()) {
                recordKey('"');
                recordKey(data);
            }
        } else {
            // Invalid register, cancel
            resetOperatorState(state);
            state.register = '"';
        }
        return true;
    }

    // --- Pending text object key (after 'i' or 'a' in operator-pending mode) ---
    if (state.pendingTextObjectPrefix) {
        const prefix = state.pendingTextObjectPrefix;
        state.pendingTextObjectPrefix = null;

        const textObjFn = resolveTextObject(prefix, data);
        if (textObjFn) {
            const lines = ctx.getText().split("\n");
            const cursor = ctx.getCursor();
            const range = textObjFn(lines, cursor);

            if (range) {
                if (state.pendingOperator) {
                    // Record the text object key for dot-repeat
                    if (isCurrentlyRecording()) {
                        recordKey(prefix);
                        recordKey(data);
                    }
                    applyOperatorToRange(ctx, lines, textObjectToRange(range));
                } else {
                    // Text objects without operator don't do anything in normal mode
                    resetOperatorState(state);
                }
            } else {
                resetOperatorState(state);
            }
        } else {
            resetOperatorState(state);
        }
        return true;
    }

    // --- Pending character input for f/F/t/T/r ---
    if (state.pendingCharMotion) {
        const pending = state.pendingCharMotion;
        state.pendingCharMotion = null;

        // Only accept single printable characters
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
                case "r":
                    // Replace character under cursor (only without pending operator)
                    if (!state.pendingOperator) {
                        beginChangeRecording(state, `r${data}`, count);
                        replaceChar(data, ctx, count);
                        finalizeChangeRecording(state);
                    }
                    resetOperatorState(state);
                    return true;
                default:
                    resetOperatorState(state);
                    return true;
            }

            // Record char motion key for dot-repeat
            if (isCurrentlyRecording()) {
                recordKey(pending);
                recordKey(data);
            }
            executeMotion(motionFn, ctx, count);
            if (!state.pendingOperator) {
                resetOperatorState(state);
            }
            return true;
        }

        // Non-printable cancels the pending motion
        resetOperatorState(state);
        return true;
    }

    // --- Pending `g` prefix ---
    if (state.pendingG) {
        state.pendingG = false;

        if (data === "g") {
            // `gg` - go to first line (or line N)
            const count = state.count || 1;
            const countExplicit = state.countStarted;
            if (isCurrentlyRecording()) {
                recordKey("g");
                recordKey("g");
            }
            executeMotion(goToFirstLine, ctx, countExplicit ? count : 1);
            if (!state.pendingOperator) {
                resetOperatorState(state);
            }
            return true;
        }

        // Unrecognized g-command, cancel
        resetOperatorState(state);
        return true;
    }

    // Count prefix handling: 1-9 start a count, 0 continues if already started
    if (isDigit(data) && (data !== "0" || state.countStarted)) {
        state.count = state.count * 10 + parseInt(data, 10);
        state.countStarted = true;
        return true;
    }

    const count = state.count || 1;
    const countExplicit = state.countStarted;

    // --- Register selection prefix (`"`) ---
    if (data === '"') {
        state.pendingRegister = true;
        return true;
    }

    // --- Dot-repeat (`.`) ---
    if (data === ".") {
        replayLastChange(ctx, countExplicit ? count : 0);
        resetOperatorState(state);
        return true;
    }

    // --- Operators ---
    if (
        data === "d" ||
        data === "c" ||
        data === "y" ||
        data === ">" ||
        data === "<"
    ) {
        if (state.pendingOperator === data) {
            // Doubled operator (dd, cc, yy, >>, <<) → linewise on current line(s)
            // Recording was already started when the first operator key was pressed
            if (isCurrentlyRecording()) {
                recordKey(data);
            }
            applyLinewiseOperator(ctx, data, count);
            return true;
        }
        if (state.pendingOperator) {
            // Different operator while one is pending → cancel
            resetOperatorState(state);
            return true;
        }
        // Set pending operator — recording starts but we wait for the motion key
        // Don't record yank (y) — it's not a change
        if (data !== "y" && !state.isReplaying && !isCurrentlyRecording()) {
            startRecording();
            // Record count digits if any
            if (countExplicit) {
                recordKey(String(count));
            }
            recordKey(data);
        }
        state.pendingOperator = data;
        // Don't reset count - it carries over to the motion
        return true;
    }

    // --- Shortcut operators (D, C, Y) ---
    if (data === "D") {
        // D = d$ (delete to end of line)
        beginChangeRecording(state, "D", count);
        state.pendingOperator = "d";
        executeMotion(lineEnd, ctx, 1);
        finalizeChangeRecording(state);
        return true;
    }

    if (data === "C") {
        // C = c$ (change to end of line)
        beginChangeRecording(state, "C", count);
        state.pendingOperator = "c";
        executeMotion(lineEnd, ctx, 1);
        // Don't finalize — enters insert mode, finalized on Escape
        return true;
    }

    if (data === "Y") {
        // Y = yy (yank whole line) — yank is not a "change" (no dot-repeat)
        applyLinewiseOperator(ctx, "y", count);
        return true;
    }

    // --- Paste commands ---
    if (data === "p" || data === "P") {
        beginChangeRecording(state, data, count);
        const reg = getRegister(state.register);
        if (reg) {
            paste(ctx, reg.text, reg.linewise, data === "P");
        }
        finalizeChangeRecording(state);
        resetOperatorState(state);
        return true;
    }

    // --- Text object prefixes (only valid in operator-pending mode) ---
    if ((data === "i" || data === "a") && state.pendingOperator) {
        state.pendingTextObjectPrefix = data;
        return true;
    }

    switch (data) {
        // === Basic directional motions ===
        case "h":
            if (state.pendingOperator) {
                if (isCurrentlyRecording()) recordKey(data);
                executeMotionForOperator("h", ctx, count);
            } else {
                for (let i = 0; i < count; i++)
                    ctx.superHandleInput(ESCAPE_SEQS.left);
                resetOperatorState(state);
            }
            return true;

        case "j":
            if (state.pendingOperator) {
                if (isCurrentlyRecording()) recordKey(data);
                // j with operator is linewise
                const lines = ctx.getText().split("\n");
                const cursor = ctx.getCursor();
                const endLine = Math.min(cursor.line + count, lines.length - 1);
                const range: OperatorRange = {
                    start: { line: cursor.line, col: 0 },
                    end: { line: endLine, col: (lines[endLine] || "").length },
                    linewise: true,
                    inclusive: true,
                };
                applyOperatorToRange(ctx, lines, range);
            } else {
                for (let i = 0; i < count; i++)
                    ctx.superHandleInput(ESCAPE_SEQS.down);
                resetOperatorState(state);
            }
            return true;

        case "k":
            if (state.pendingOperator) {
                if (isCurrentlyRecording()) recordKey(data);
                // k with operator is linewise
                const lines = ctx.getText().split("\n");
                const cursor = ctx.getCursor();
                const startLine = Math.max(cursor.line - count, 0);
                const range: OperatorRange = {
                    start: { line: startLine, col: 0 },
                    end: {
                        line: cursor.line,
                        col: (lines[cursor.line] || "").length,
                    },
                    linewise: true,
                    inclusive: true,
                };
                applyOperatorToRange(ctx, lines, range);
            } else {
                for (let i = 0; i < count; i++)
                    ctx.superHandleInput(ESCAPE_SEQS.up);
                resetOperatorState(state);
            }
            return true;

        case "l":
            if (state.pendingOperator) {
                if (isCurrentlyRecording()) recordKey(data);
                executeMotionForOperator("l", ctx, count);
            } else {
                for (let i = 0; i < count; i++)
                    ctx.superHandleInput(ESCAPE_SEQS.right);
                resetOperatorState(state);
            }
            return true;

        // === Line motions ===
        case "0":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(lineStart, ctx, 1);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        case "$":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(lineEnd, ctx, count);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        case "^":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(firstNonBlank, ctx, 1);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        // === Word motions ===
        case "w":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(wordForward, ctx, count);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        case "b":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(wordBackward, ctx, count);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        case "e":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(wordEnd, ctx, count);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        case "W":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(WORDForward, ctx, count);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        case "B":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(WORDBackward, ctx, count);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        case "E":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(WORDEnd, ctx, count);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        // === Find/Till character motions ===
        case "f":
        case "F":
        case "t":
        case "T":
            state.pendingCharMotion = data;
            return true;

        // === Repeat char search ===
        case ";":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(repeatCharSearch, ctx, count);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        case ",":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(reverseCharSearch, ctx, count);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        // === Line-level motions ===
        case "g":
            state.pendingG = true;
            return true;

        case "G":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            // G without count → last line, G with count → line N
            if (countExplicit) {
                executeMotion(goToLastLine, ctx, count);
            } else {
                const lines = ctx.getText().split("\n");
                executeMotion(goToLastLine, ctx, lines.length);
            }
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        // === Paragraph motions ===
        case "{":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(paragraphBackward, ctx, count);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        case "}":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(paragraphForward, ctx, count);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        // === Matching bracket ===
        case "%":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(matchingBracket, ctx, 1);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        // === Search motions ===
        case "n":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(searchNext, ctx, count);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        case "N":
            if (state.pendingOperator && isCurrentlyRecording())
                recordKey(data);
            executeMotion(searchPrev, ctx, count);
            if (!state.pendingOperator) resetOperatorState(state);
            return true;

        case "*": {
            const lines = ctx.getText().split("\n");
            const cursor = ctx.getCursor();
            const result = searchWordUnderCursor(lines, cursor, "forward");
            if (state.pendingOperator) {
                if (isCurrentlyRecording()) recordKey(data);
                applyOperatorWithMotion(ctx, lines, cursor, result);
            } else {
                ctx.moveCursorTo(result.position.line, result.position.col);
            }
            resetOperatorState(state);
            return true;
        }

        case "#": {
            const lines = ctx.getText().split("\n");
            const cursor = ctx.getCursor();
            const result = searchWordUnderCursor(lines, cursor, "backward");
            if (state.pendingOperator) {
                if (isCurrentlyRecording()) recordKey(data);
                applyOperatorWithMotion(ctx, lines, cursor, result);
            } else {
                ctx.moveCursorTo(result.position.line, result.position.col);
            }
            resetOperatorState(state);
            return true;
        }

        // === Insert mode entry ===
        case "i":
            beginChangeRecording(state, "i", count);
            markInsertEntry();
            state.mode = "insert";
            resetOperatorState(state);
            return true;

        case "a":
            beginChangeRecording(state, "a", count);
            markInsertEntry();
            state.mode = "insert";
            ctx.superHandleInput(ESCAPE_SEQS.right);
            resetOperatorState(state);
            return true;

        case "I": {
            beginChangeRecording(state, "I", count);
            markInsertEntry();
            // Insert at first non-whitespace
            const lines = ctx.getText().split("\n");
            const cursor = ctx.getCursor();
            const line = lines[cursor.line] || "";
            const match = line.match(/^\s*/);
            const targetCol = match ? match[0].length : 0;
            ctx.moveCursorTo(cursor.line, targetCol);
            state.mode = "insert";
            resetOperatorState(state);
            return true;
        }

        case "A":
            beginChangeRecording(state, "A", count);
            markInsertEntry();
            ctx.superHandleInput(ESCAPE_SEQS.end);
            state.mode = "insert";
            resetOperatorState(state);
            return true;

        case "o": {
            beginChangeRecording(state, "o", count);
            markInsertEntry();
            // Open line below
            const lines = ctx.getText().split("\n");
            const cursor = ctx.getCursor();
            lines.splice(cursor.line + 1, 0, "");
            ctx.setText(lines.join("\n"));
            ctx.moveCursorTo(cursor.line + 1, 0);
            state.mode = "insert";
            resetOperatorState(state);
            return true;
        }

        case "O": {
            beginChangeRecording(state, "O", count);
            markInsertEntry();
            // Open line above
            const lines = ctx.getText().split("\n");
            const cursor = ctx.getCursor();
            lines.splice(cursor.line, 0, "");
            ctx.setText(lines.join("\n"));
            ctx.moveCursorTo(cursor.line, 0);
            state.mode = "insert";
            resetOperatorState(state);
            return true;
        }

        // === Visual mode entry ===
        case "v": {
            state.mode = "visual";
            const cursor = ctx.getCursor();
            state.visualAnchor = { line: cursor.line, col: cursor.col };
            resetOperatorState(state);
            return true;
        }

        case "V": {
            state.mode = "visual-line";
            const cursor = ctx.getCursor();
            state.visualAnchor = { line: cursor.line, col: cursor.col };
            resetOperatorState(state);
            return true;
        }

        // === Basic editing ===
        case "x": {
            beginChangeRecording(state, "x", count);
            // x = dl (delete char under cursor)
            for (let i = 0; i < count; i++) {
                ctx.superHandleInput(ESCAPE_SEQS.delete);
            }
            finalizeChangeRecording(state);
            resetOperatorState(state);
            return true;
        }

        case "X": {
            beginChangeRecording(state, "X", count);
            for (let i = 0; i < count; i++) {
                ctx.superHandleInput(ESCAPE_SEQS.backspace);
            }
            finalizeChangeRecording(state);
            resetOperatorState(state);
            return true;
        }

        case "r":
            // Replace character - wait for next char
            state.pendingCharMotion = "r";
            return true;

        case "R":
            // Enter replace mode (overtype)
            beginChangeRecording(state, "R", count);
            markInsertEntry();
            resetReplaceState();
            state.mode = "replace";
            resetOperatorState(state);
            return true;

        // === Undo / Redo ===
        case "u":
            // Undo
            ctx.undo();
            resetOperatorState(state);
            return true;

        case "\x12":
            // Ctrl+r (redo)
            ctx.redo();
            resetOperatorState(state);
            return true;

        // === Join lines ===
        case "J": {
            beginChangeRecording(state, "J", count);
            const lines = ctx.getText().split("\n");
            const cursor = ctx.getCursor();
            const joinCount = Math.min(count, lines.length - cursor.line - 1);

            if (joinCount > 0) {
                for (let i = 0; i < joinCount; i++) {
                    const lineIdx = cursor.line;
                    if (lineIdx + 1 < lines.length) {
                        const currentLine = lines[lineIdx]!;
                        const nextLine = (lines[lineIdx + 1] || "").replace(
                            /^\s+/,
                            "",
                        );
                        const joinCol = currentLine.length;
                        lines[lineIdx] =
                            currentLine +
                            (nextLine.length > 0 ? " " + nextLine : "");
                        lines.splice(lineIdx + 1, 1);
                    }
                }
                const joinCol = (lines[cursor.line] || "").length;
                ctx.setText(lines.join("\n"));
                // Place cursor at the join point
                const finalLine = lines[cursor.line] || "";
                ctx.moveCursorTo(
                    cursor.line,
                    Math.min(joinCol, Math.max(0, finalLine.length - 1)),
                );
            }
            finalizeChangeRecording(state);
            resetOperatorState(state);
            return true;
        }

        // === Toggle case ===
        case "~": {
            beginChangeRecording(state, "~", count);
            const lines = ctx.getText().split("\n");
            const cursor = ctx.getCursor();
            const line = lines[cursor.line] || "";

            if (cursor.col < line.length) {
                const end = Math.min(cursor.col + count, line.length);
                let toggled = "";
                for (let i = cursor.col; i < end; i++) {
                    const ch = line[i]!;
                    toggled +=
                        ch === ch.toLowerCase()
                            ? ch.toUpperCase()
                            : ch.toLowerCase();
                }
                lines[cursor.line] =
                    line.substring(0, cursor.col) +
                    toggled +
                    line.substring(end);
                ctx.setText(lines.join("\n"));
                ctx.moveCursorTo(
                    cursor.line,
                    Math.min(
                        end,
                        Math.max(0, (lines[cursor.line] || "").length - 1),
                    ),
                );
            }
            finalizeChangeRecording(state);
            resetOperatorState(state);
            return true;
        }

        default:
            break;
    }

    // If we have a pending operator and got an unrecognized key, cancel
    if (state.pendingOperator) {
        resetOperatorState(state);
        return true;
    }

    // If we have an unrecognized key, reset count and pass control sequences through
    resetOperatorState(state);

    // Pass control sequences to super for app keybindings (ctrl+d, etc.)
    if (data.length === 1 && data.charCodeAt(0) < 32) {
        ctx.superHandleInput(data);
        return true;
    }

    // Pass escape sequences through
    if (data.length > 1 && data.startsWith("\x1b")) {
        ctx.superHandleInput(data);
        return true;
    }

    // Ignore unrecognized printable characters in normal mode
    return true;
}

/**
 * Execute a simple h/l motion for operator-pending mode.
 */
function executeMotionForOperator(
    key: string,
    ctx: NormalModeContext,
    count: number,
): void {
    const lines = ctx.getText().split("\n");
    const cursor = ctx.getCursor();
    const line = lines[cursor.line] || "";

    let targetCol: number;
    if (key === "h") {
        targetCol = Math.max(0, cursor.col - count);
    } else {
        // l
        targetCol = Math.min(line.length - 1, cursor.col + count);
    }

    const motionResult: MotionResult = {
        position: { line: cursor.line, col: targetCol },
        linewise: false,
        inclusive: key === "l",
    };

    applyOperatorWithMotion(ctx, lines, cursor, motionResult);
}

/**
 * Begin recording a change for dot-repeat, unless already recording or replaying.
 */
function beginChangeRecording(
    state: VimState,
    key: string,
    count: number,
): void {
    if (state.isReplaying) return;
    if (isCurrentlyRecording()) return;
    startRecording();
    if (count > 1) {
        recordKey(String(count));
    }
    // For compound keys like "r{char}", record all chars
    for (const ch of key) {
        recordKey(ch);
    }
}

/**
 * Finalize recording if we're recording and not replaying.
 */
function finalizeChangeRecording(state: VimState): void {
    if (state.isReplaying) return;
    if (isCurrentlyRecording()) {
        finalizeRecording();
    }
}

/**
 * Replay the last recorded change (dot-repeat).
 * If countOverride > 0, use it instead of the recorded count.
 */
function replayLastChange(ctx: NormalModeContext, countOverride: number): void {
    const change = getLastChange();
    if (!change) return;

    const { state } = ctx;
    state.isReplaying = true;

    try {
        // Replay the normal-mode keys
        for (const key of change.keys) {
            // If this is a count and we have an override, skip the recorded count
            // (The count is embedded in the keys as a string number)
            handleNormalMode(key, ctx);
        }

        // If the change entered insert or replace mode, type the recorded text then escape
        if (
            change.enteredInsert &&
            (state.mode === "insert" || state.mode === "replace")
        ) {
            const wasReplace = state.mode === "replace";
            if (wasReplace) {
                // In replace mode, we need to overtype characters
                const lines = ctx.getText().split("\n");
                const cursor = ctx.getCursor();
                let line = lines[cursor.line] || "";
                let col = cursor.col;

                for (const ch of change.insertedText) {
                    if (ch === "\n") {
                        // Split line at cursor for newline
                        const before = line.substring(0, col);
                        const after = line.substring(col);
                        lines[cursor.line] = before;
                        lines.splice(cursor.line + 1, 0, after);
                        cursor.line++;
                        col = 0;
                        line = lines[cursor.line] || "";
                    } else if (col < line.length) {
                        // Overtype
                        line =
                            line.substring(0, col) +
                            ch +
                            line.substring(col + 1);
                        lines[cursor.line] = line;
                        col++;
                    } else {
                        // Append at end
                        line = line + ch;
                        lines[cursor.line] = line;
                        col++;
                    }
                }
                ctx.setText(lines.join("\n"));
                ctx.moveCursorTo(cursor.line, Math.max(0, col - 1));
            } else {
                for (const ch of change.insertedText) {
                    if (ch === "\n") {
                        ctx.superHandleInput("\n");
                    } else {
                        ctx.superHandleInput(ch);
                    }
                }
            }
            // Exit insert/replace mode
            state.mode = "normal";
            if (!wasReplace && ctx.getCursor().col > 0) {
                ctx.superHandleInput("\x1b[D"); // left
            }
        }
    } finally {
        state.isReplaying = false;
    }
}

/**
 * Replace character under cursor with given char, repeated `count` times.
 */
function replaceChar(
    char: string,
    ctx: NormalModeContext,
    count: number,
): void {
    const lines = ctx.getText().split("\n");
    const cursor = ctx.getCursor();
    const line = lines[cursor.line] || "";

    // Replace `count` characters starting at cursor
    const end = Math.min(cursor.col + count, line.length);
    if (cursor.col >= line.length) return;

    const newLine =
        line.substring(0, cursor.col) +
        char.repeat(end - cursor.col) +
        line.substring(end);
    lines[cursor.line] = newLine;
    ctx.setText(lines.join("\n"));
    // Cursor stays at the last replaced character (or cursor.col if count=1)
    ctx.moveCursorTo(cursor.line, end - 1);
}

/**
 * Paste text from register.
 */
function paste(
    ctx: NormalModeContext,
    text: string,
    linewise: boolean,
    before: boolean,
): void {
    const lines = ctx.getText().split("\n");
    const cursor = ctx.getCursor();

    if (linewise) {
        const pasteLines = text.split("\n");
        if (before) {
            // P: paste above current line
            lines.splice(cursor.line, 0, ...pasteLines);
            ctx.setText(lines.join("\n"));
            const targetLineText = lines[cursor.line] || "";
            const match = targetLineText.match(/^\s*/);
            ctx.moveCursorTo(cursor.line, match ? match[0].length : 0);
        } else {
            // p: paste below current line
            lines.splice(cursor.line + 1, 0, ...pasteLines);
            ctx.setText(lines.join("\n"));
            const targetLine = cursor.line + 1;
            const targetLineText = lines[targetLine] || "";
            const match = targetLineText.match(/^\s*/);
            ctx.moveCursorTo(targetLine, match ? match[0].length : 0);
        }
    } else {
        // Character-wise paste
        const line = lines[cursor.line] || "";
        if (before) {
            // P: paste before cursor
            const newLine =
                line.substring(0, cursor.col) +
                text +
                line.substring(cursor.col);
            lines[cursor.line] = newLine;
            ctx.setText(lines.join("\n"));

            if (text.includes("\n")) {
                // Multi-line paste: cursor goes to start of pasted text
                ctx.moveCursorTo(cursor.line, cursor.col);
            } else {
                // Single line: cursor goes to last pasted character
                ctx.moveCursorTo(cursor.line, cursor.col + text.length - 1);
            }
        } else {
            // p: paste after cursor
            const insertCol = Math.min(cursor.col + 1, line.length);
            const pasteLines = text.split("\n");

            if (pasteLines.length === 1) {
                const newLine =
                    line.substring(0, insertCol) +
                    text +
                    line.substring(insertCol);
                lines[cursor.line] = newLine;
                ctx.setText(lines.join("\n"));
                ctx.moveCursorTo(cursor.line, insertCol + text.length - 1);
            } else {
                // Multi-line character-wise paste
                const before = line.substring(0, insertCol);
                const after = line.substring(insertCol);
                const firstPasteLine = before + pasteLines[0];
                const lastPasteLine = pasteLines[pasteLines.length - 1] + after;

                const newLines = [
                    firstPasteLine,
                    ...pasteLines.slice(1, -1),
                    lastPasteLine,
                ];
                lines.splice(cursor.line, 1, ...newLines);
                ctx.setText(lines.join("\n"));

                // Cursor at end of pasted text
                const lastPasteLineIdx = cursor.line + pasteLines.length - 1;
                const lastPasteCol =
                    (pasteLines[pasteLines.length - 1] || "").length - 1;
                ctx.moveCursorTo(lastPasteLineIdx, Math.max(0, lastPasteCol));
            }
        }
    }
}
