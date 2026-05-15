/**
 * Motion definitions for vim navigation.
 * Each motion computes a target cursor position given text, cursor, and count.
 */

export interface Position {
    line: number;
    col: number;
}

export interface MotionResult {
    position: Position;
    /** Whether this motion operates on whole lines (for operators) */
    linewise: boolean;
    /** Whether the end position is included in operator ranges */
    inclusive: boolean;
}

export type MotionFn = (
    lines: string[],
    cursor: Position,
    count: number,
) => MotionResult;

// --- Character classification helpers ---

function isWordChar(ch: string): boolean {
    return /[a-zA-Z0-9_]/.test(ch);
}

function isPunctuation(ch: string): boolean {
    return !isWordChar(ch) && ch !== " " && ch !== "\t" && ch !== "";
}

function isWhitespace(ch: string): boolean {
    return ch === " " || ch === "\t";
}

function isBlankLine(line: string): boolean {
    return /^\s*$/.test(line);
}

function clampCol(line: string, col: number): number {
    if (!line || line.length === 0) return 0;
    return Math.max(0, Math.min(col, line.length - 1));
}

function clampLine(lines: string[], line: number): number {
    return Math.max(0, Math.min(line, lines.length - 1));
}

// --- Word motions (small word: alphanumeric/_ vs punctuation vs whitespace) ---

/**
 * `w` - Move to start of next word.
 * A word boundary is a transition between character classes, or moving past whitespace.
 */
export const wordForward: MotionFn = (lines, cursor, count) => {
    let { line, col } = cursor;
    let inclusive = false;

    for (let n = 0; n < count; n++) {
        const result = nextWordStart(lines, line, col);
        line = result.line;
        col = result.col;
        inclusive = result.inclusive ?? false;
    }

    return { position: { line, col }, linewise: false, inclusive };
};

type WordStartResult = Position & { inclusive?: boolean };

function nextWordStart(
    lines: string[],
    line: number,
    col: number,
): WordStartResult {
    if (lines.length === 0) return { line: 0, col: 0 };

    let text = lines[line] || "";

    // If at end of file, stay for movement, but make operator ranges inclusive
    // so `dw`/`cw` on the final character still affects that character.
    if (line >= lines.length - 1 && col >= text.length - 1) {
        return { line, col: Math.max(0, text.length - 1), inclusive: true };
    }

    const ch = text[col] || "";

    // Skip current word characters of same class
    if (isWordChar(ch)) {
        while (col < text.length && isWordChar(text[col]!)) col++;
    } else if (isPunctuation(ch)) {
        while (col < text.length && isPunctuation(text[col]!)) col++;
    }

    // Skip whitespace (possibly across lines)
    while (true) {
        while (col < text.length && isWhitespace(text[col]!)) col++;
        if (col < text.length) break;
        // Move to next line
        line++;
        if (line >= lines.length) {
            line = lines.length - 1;
            return {
                line,
                col: Math.max(0, (lines[line] || "").length - 1),
                inclusive: true,
            };
        }
        text = lines[line] || "";
        col = 0;
        // If the new line is non-empty, we stop at col 0
        if (text.length > 0) break;
    }

    return { line, col };
}

/**
 * `b` - Move to start of previous word.
 */
export const wordBackward: MotionFn = (lines, cursor, count) => {
    let { line, col } = cursor;

    for (let n = 0; n < count; n++) {
        const result = prevWordStart(lines, line, col);
        line = result.line;
        col = result.col;
    }

    return { position: { line, col }, linewise: false, inclusive: false };
};

function prevWordStart(lines: string[], line: number, col: number): Position {
    if (lines.length === 0) return { line: 0, col: 0 };

    let text = lines[line] || "";

    // Move back one character to start searching
    col--;

    // Skip whitespace backwards (possibly across lines)
    while (true) {
        while (col >= 0 && isWhitespace(text[col]!)) col--;
        if (col >= 0) break;
        // Move to previous line
        line--;
        if (line < 0) return { line: 0, col: 0 };
        text = lines[line] || "";
        col = text.length - 1;
    }

    // Now skip backwards through the word
    if (col >= 0 && isWordChar(text[col]!)) {
        while (col > 0 && isWordChar(text[col - 1]!)) col--;
    } else if (col >= 0 && isPunctuation(text[col]!)) {
        while (col > 0 && isPunctuation(text[col - 1]!)) col--;
    }

    return { line, col: Math.max(0, col) };
}

/**
 * `e` - Move to end of current/next word.
 */
export const wordEnd: MotionFn = (lines, cursor, count) => {
    let { line, col } = cursor;

    for (let n = 0; n < count; n++) {
        const result = nextWordEnd(lines, line, col);
        line = result.line;
        col = result.col;
    }

    return { position: { line, col }, linewise: false, inclusive: true };
};

function nextWordEnd(lines: string[], line: number, col: number): Position {
    if (lines.length === 0) return { line: 0, col: 0 };

    let text = lines[line] || "";

    // Move forward one character to start searching
    col++;

    // Skip whitespace (possibly across lines)
    while (true) {
        while (col < text.length && isWhitespace(text[col]!)) col++;
        if (col < text.length) break;
        line++;
        if (line >= lines.length) {
            line = lines.length - 1;
            return { line, col: Math.max(0, (lines[line] || "").length - 1) };
        }
        text = lines[line] || "";
        col = 0;
    }

    // Move forward through word characters of same class
    if (isWordChar(text[col]!)) {
        while (col < text.length - 1 && isWordChar(text[col + 1]!)) col++;
    } else if (isPunctuation(text[col]!)) {
        while (col < text.length - 1 && isPunctuation(text[col + 1]!)) col++;
    }

    return { line, col };
}

// --- WORD motions (whitespace-delimited) ---

/**
 * `W` - Move to start of next WORD (whitespace-delimited).
 */
export const WORDForward: MotionFn = (lines, cursor, count) => {
    let { line, col } = cursor;
    let inclusive = false;

    for (let n = 0; n < count; n++) {
        const result = nextWORDStart(lines, line, col);
        line = result.line;
        col = result.col;
        inclusive = result.inclusive ?? false;
    }

    return { position: { line, col }, linewise: false, inclusive };
};

function nextWORDStart(
    lines: string[],
    line: number,
    col: number,
): WordStartResult {
    if (lines.length === 0) return { line: 0, col: 0 };

    let text = lines[line] || "";

    // Skip non-whitespace
    while (col < text.length && !isWhitespace(text[col]!)) col++;

    // Skip whitespace (possibly across lines)
    while (true) {
        while (col < text.length && isWhitespace(text[col]!)) col++;
        if (col < text.length) break;
        line++;
        if (line >= lines.length) {
            line = lines.length - 1;
            return {
                line,
                col: Math.max(0, (lines[line] || "").length - 1),
                inclusive: true,
            };
        }
        text = lines[line] || "";
        col = 0;
        if (text.length > 0) break;
    }

    return { line, col };
}

/**
 * `B` - Move to start of previous WORD.
 */
export const WORDBackward: MotionFn = (lines, cursor, count) => {
    let { line, col } = cursor;

    for (let n = 0; n < count; n++) {
        const result = prevWORDStart(lines, line, col);
        line = result.line;
        col = result.col;
    }

    return { position: { line, col }, linewise: false, inclusive: false };
};

function prevWORDStart(lines: string[], line: number, col: number): Position {
    if (lines.length === 0) return { line: 0, col: 0 };

    let text = lines[line] || "";
    col--;

    // Skip whitespace backwards
    while (true) {
        while (col >= 0 && isWhitespace(text[col]!)) col--;
        if (col >= 0) break;
        line--;
        if (line < 0) return { line: 0, col: 0 };
        text = lines[line] || "";
        col = text.length - 1;
    }

    // Skip non-whitespace backwards
    while (col > 0 && !isWhitespace(text[col - 1]!)) col--;

    return { line, col: Math.max(0, col) };
}

/**
 * `E` - Move to end of current/next WORD.
 */
export const WORDEnd: MotionFn = (lines, cursor, count) => {
    let { line, col } = cursor;

    for (let n = 0; n < count; n++) {
        const result = nextWORDEnd(lines, line, col);
        line = result.line;
        col = result.col;
    }

    return { position: { line, col }, linewise: false, inclusive: true };
};

function nextWORDEnd(lines: string[], line: number, col: number): Position {
    if (lines.length === 0) return { line: 0, col: 0 };

    let text = lines[line] || "";
    col++;

    // Skip whitespace
    while (true) {
        while (col < text.length && isWhitespace(text[col]!)) col++;
        if (col < text.length) break;
        line++;
        if (line >= lines.length) {
            line = lines.length - 1;
            return { line, col: Math.max(0, (lines[line] || "").length - 1) };
        }
        text = lines[line] || "";
        col = 0;
    }

    // Skip non-whitespace forward
    while (col < text.length - 1 && !isWhitespace(text[col + 1]!)) col++;

    return { line, col };
}

// --- Line-level motions ---

/**
 * `gg` - Go to first line (or line N with count).
 */
export const goToFirstLine: MotionFn = (lines, _cursor, count) => {
    // count is the line number (1-indexed) if explicitly given, otherwise line 1
    const targetLine = clampLine(lines, count - 1);
    const text = lines[targetLine] || "";
    const match = text.match(/^\s*/);
    const col = match ? match[0].length : 0;
    return {
        position: { line: targetLine, col },
        linewise: true,
        inclusive: false,
    };
};

/**
 * `G` - Go to last line (or line N with count).
 */
export const goToLastLine: MotionFn = (lines, _cursor, count) => {
    // If count was explicitly provided it's passed as count, otherwise go to last line
    const targetLine = clampLine(lines, count - 1);
    const text = lines[targetLine] || "";
    const match = text.match(/^\s*/);
    const col = match ? match[0].length : 0;
    return {
        position: { line: targetLine, col },
        linewise: true,
        inclusive: false,
    };
};

/**
 * `^` - First non-whitespace character on line.
 */
export const firstNonBlank: MotionFn = (lines, cursor, _count) => {
    const text = lines[cursor.line] || "";
    const match = text.match(/^\s*/);
    const col = match ? match[0].length : 0;
    return {
        position: { line: cursor.line, col },
        linewise: false,
        inclusive: false,
    };
};

/**
 * `0` - Start of line.
 */
export const lineStart: MotionFn = (_lines, cursor, _count) => {
    return {
        position: { line: cursor.line, col: 0 },
        linewise: false,
        inclusive: false,
    };
};

/**
 * `$` - End of line.
 */
export const lineEnd: MotionFn = (lines, cursor, count) => {
    // With count > 1, go down count-1 lines then to end
    const targetLine = clampLine(lines, cursor.line + count - 1);
    const text = lines[targetLine] || "";
    const col = Math.max(0, text.length - 1);
    return {
        position: { line: targetLine, col },
        linewise: false,
        inclusive: true,
    };
};

// --- Find character motions ---

/** Last f/F/t/T search for `;` and `,` repeat */
let lastCharSearch: {
    char: string;
    direction: "forward" | "backward";
    type: "f" | "t";
} | null = null;

export function getLastCharSearch() {
    return lastCharSearch;
}

/**
 * `f{char}` - Find char forward on current line (inclusive).
 */
export function findCharForward(char: string): MotionFn {
    return (lines, cursor, count) => {
        lastCharSearch = { char, direction: "forward", type: "f" };
        const text = lines[cursor.line] || "";
        let col = cursor.col;

        for (let n = 0; n < count; n++) {
            col++;
            while (col < text.length && text[col] !== char) col++;
            if (col >= text.length) {
                // Not found - stay at current position
                return {
                    position: { line: cursor.line, col: cursor.col },
                    linewise: false,
                    inclusive: true,
                };
            }
        }

        return {
            position: { line: cursor.line, col },
            linewise: false,
            inclusive: true,
        };
    };
}

/**
 * `F{char}` - Find char backward on current line (inclusive).
 */
export function findCharBackward(char: string): MotionFn {
    return (lines, cursor, count) => {
        lastCharSearch = { char, direction: "backward", type: "f" };
        const text = lines[cursor.line] || "";
        let col = cursor.col;

        for (let n = 0; n < count; n++) {
            col--;
            while (col >= 0 && text[col] !== char) col--;
            if (col < 0) {
                return {
                    position: { line: cursor.line, col: cursor.col },
                    linewise: false,
                    inclusive: true,
                };
            }
        }

        return {
            position: { line: cursor.line, col },
            linewise: false,
            inclusive: true,
        };
    };
}

/**
 * `t{char}` - Till char forward (one before char, inclusive).
 */
export function tillCharForward(char: string): MotionFn {
    return (lines, cursor, count) => {
        lastCharSearch = { char, direction: "forward", type: "t" };
        const text = lines[cursor.line] || "";
        let col = cursor.col;

        for (let n = 0; n < count; n++) {
            const searchStart = col + 1;
            col = searchStart;
            while (col < text.length && text[col] !== char) col++;
            if (col >= text.length) {
                return {
                    position: { line: cursor.line, col: cursor.col },
                    linewise: false,
                    inclusive: true,
                };
            }
        }

        // Stop one before the found character
        return {
            position: { line: cursor.line, col: col - 1 },
            linewise: false,
            inclusive: true,
        };
    };
}

/**
 * `T{char}` - Till char backward (one after char, inclusive).
 */
export function tillCharBackward(char: string): MotionFn {
    return (lines, cursor, count) => {
        lastCharSearch = { char, direction: "backward", type: "t" };
        const text = lines[cursor.line] || "";
        let col = cursor.col;

        for (let n = 0; n < count; n++) {
            col--;
            while (col >= 0 && text[col] !== char) col--;
            if (col < 0) {
                return {
                    position: { line: cursor.line, col: cursor.col },
                    linewise: false,
                    inclusive: true,
                };
            }
        }

        // Stop one after the found character
        return {
            position: { line: cursor.line, col: col + 1 },
            linewise: false,
            inclusive: true,
        };
    };
}

/**
 * `;` - Repeat last f/F/t/T in same direction.
 */
export const repeatCharSearch: MotionFn = (lines, cursor, count) => {
    if (!lastCharSearch)
        return { position: cursor, linewise: false, inclusive: true };

    const { char, direction, type } = lastCharSearch;
    if (direction === "forward") {
        const fn = type === "f" ? findCharForward(char) : tillCharForward(char);
        // Restore lastCharSearch since the helper overwrites it
        const saved = { ...lastCharSearch };
        const result = fn(lines, cursor, count);
        lastCharSearch = saved;
        return result;
    } else {
        const fn =
            type === "f" ? findCharBackward(char) : tillCharBackward(char);
        const saved = { ...lastCharSearch };
        const result = fn(lines, cursor, count);
        lastCharSearch = saved;
        return result;
    }
};

/**
 * `,` - Repeat last f/F/t/T in opposite direction.
 */
export const reverseCharSearch: MotionFn = (lines, cursor, count) => {
    if (!lastCharSearch)
        return { position: cursor, linewise: false, inclusive: true };

    const { char, direction, type } = lastCharSearch;
    // Reverse direction
    if (direction === "forward") {
        const fn =
            type === "f" ? findCharBackward(char) : tillCharBackward(char);
        const saved = { ...lastCharSearch };
        const result = fn(lines, cursor, count);
        lastCharSearch = saved;
        return result;
    } else {
        const fn = type === "f" ? findCharForward(char) : tillCharForward(char);
        const saved = { ...lastCharSearch };
        const result = fn(lines, cursor, count);
        lastCharSearch = saved;
        return result;
    }
};

// --- Paragraph motions ---

/**
 * `{` - Move to previous blank line (paragraph boundary).
 */
export const paragraphBackward: MotionFn = (lines, cursor, count) => {
    let line = cursor.line;

    for (let n = 0; n < count; n++) {
        // Skip current blank lines
        while (line > 0 && isBlankLine(lines[line]!)) line--;
        // Find next blank line
        while (line > 0 && !isBlankLine(lines[line]!)) line--;
    }

    return { position: { line, col: 0 }, linewise: true, inclusive: false };
};

/**
 * `}` - Move to next blank line (paragraph boundary).
 */
export const paragraphForward: MotionFn = (lines, cursor, count) => {
    let line = cursor.line;
    const lastLine = lines.length - 1;

    for (let n = 0; n < count; n++) {
        // Skip current blank lines
        while (line < lastLine && isBlankLine(lines[line]!)) line++;
        // Find next blank line
        while (line < lastLine && !isBlankLine(lines[line]!)) line++;
    }

    return { position: { line, col: 0 }, linewise: true, inclusive: false };
};

// --- Matching bracket ---

const BRACKET_PAIRS: Record<string, string> = {
    "(": ")",
    ")": "(",
    "[": "]",
    "]": "[",
    "{": "}",
    "}": "{",
};

const OPEN_BRACKETS = new Set(["(", "[", "{"]);

/**
 * `%` - Move to matching bracket.
 */
export const matchingBracket: MotionFn = (lines, cursor, _count) => {
    const text = lines[cursor.line] || "";

    // Find the first bracket at or after cursor on current line
    let bracketCol = cursor.col;
    while (bracketCol < text.length && !BRACKET_PAIRS[text[bracketCol]!]) {
        bracketCol++;
    }

    if (bracketCol >= text.length) {
        // No bracket found on line from cursor
        return { position: cursor, linewise: false, inclusive: true };
    }

    const bracket = text[bracketCol]!;
    const match = BRACKET_PAIRS[bracket]!;
    const isOpen = OPEN_BRACKETS.has(bracket);
    let depth = 1;

    if (isOpen) {
        // Search forward
        let line = cursor.line;
        let col = bracketCol + 1;
        while (line < lines.length) {
            const lineText = lines[line]!;
            while (col < lineText.length) {
                if (lineText[col] === bracket) depth++;
                else if (lineText[col] === match) depth--;
                if (depth === 0) {
                    return {
                        position: { line, col },
                        linewise: false,
                        inclusive: true,
                    };
                }
                col++;
            }
            line++;
            col = 0;
        }
    } else {
        // Search backward
        let line = cursor.line;
        let col = bracketCol - 1;
        while (line >= 0) {
            const lineText = lines[line]!;
            while (col >= 0) {
                if (lineText[col] === bracket) depth++;
                else if (lineText[col] === match) depth--;
                if (depth === 0) {
                    return {
                        position: { line, col },
                        linewise: false,
                        inclusive: true,
                    };
                }
                col--;
            }
            line--;
            if (line >= 0) col = lines[line]!.length - 1;
        }
    }

    // No match found
    return { position: cursor, linewise: false, inclusive: true };
};
