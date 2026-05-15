/**
 * Search system for vim.
 *
 * Supports:
 * - `/pattern` forward search
 * - `?pattern` backward search
 * - `n` / `N` repeat search forward / backward
 * - `*` / `#` search word under cursor forward / backward
 *
 * Search can also be used as a motion with operators (e.g., d/pattern).
 */

import { matchesKey } from "@earendil-works/pi-tui";
import type { MotionFn, MotionResult, Position } from "./motions.js";

export interface SearchState {
    /** Last search pattern (string, not regex) */
    lastPattern: string | null;
    /** Direction of the last search */
    lastDirection: "forward" | "backward";
    /** Current command-line input buffer for / or ? */
    inputBuffer: string;
    /** Whether we're currently in search command-line mode */
    active: boolean;
    /** The prompt character (/ or ?) */
    prompt: string;
    /** Mode to return to after search completes (normal or visual/visual-line) */
    returnMode: "normal" | "visual" | "visual-line";
}

/** Global search state */
const searchState: SearchState = {
    lastPattern: null,
    lastDirection: "forward",
    inputBuffer: "",
    active: false,
    prompt: "/",
    returnMode: "normal",
};

export function getSearchState(): SearchState {
    return searchState;
}

/**
 * Begin a search command-line session.
 */
export function beginSearch(
    direction: "forward" | "backward",
    returnMode: "normal" | "visual" | "visual-line" = "normal",
): void {
    searchState.active = true;
    searchState.inputBuffer = "";
    searchState.prompt = direction === "forward" ? "/" : "?";
    searchState.lastDirection = direction;
    searchState.returnMode = returnMode;
}

/**
 * Handle a key during search command-line input.
 * Returns:
 *   "continue" - keep accepting input
 *   "confirm"  - user pressed Enter, execute the search
 *   "cancel"   - user pressed Escape, cancel
 */
export function handleSearchInput(
    data: string,
): "continue" | "confirm" | "cancel" {
    // Escape or Ctrl+[ → cancel search
    if (matchesKey(data, "escape") || data === "\x1b" || data === "\x1b[") {
        searchState.active = false;
        searchState.inputBuffer = "";
        return "cancel";
    }

    // Enter → confirm search
    if (data === "\r" || data === "\n") {
        if (searchState.inputBuffer.length > 0) {
            searchState.lastPattern = searchState.inputBuffer;
        }
        searchState.active = false;
        return "confirm";
    }

    // Backspace
    if (data === "\x7f") {
        if (searchState.inputBuffer.length > 0) {
            searchState.inputBuffer = searchState.inputBuffer.slice(0, -1);
        } else {
            // Backspace on empty input cancels search
            searchState.active = false;
            return "cancel";
        }
        return "continue";
    }

    // Ctrl+U → clear input
    if (data === "\x15") {
        searchState.inputBuffer = "";
        return "continue";
    }

    // Printable character
    if (data.length === 1 && data.charCodeAt(0) >= 32) {
        searchState.inputBuffer += data;
        return "continue";
    }

    // Ignore other control sequences
    return "continue";
}

/**
 * Get the current search prompt string for rendering (e.g., "/pattern").
 */
export function getSearchPrompt(): string {
    return searchState.prompt + searchState.inputBuffer;
}

/**
 * Find all matches of a pattern in the text lines.
 * Returns positions of all match starts.
 */
function findAllMatches(lines: string[], pattern: string): Position[] {
    if (!pattern) return [];

    const matches: Position[] = [];
    // Escape regex special chars for literal search
    const escaped = pattern.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    let regex: RegExp;
    try {
        regex = new RegExp(escaped, "gi");
    } catch {
        return [];
    }

    for (let line = 0; line < lines.length; line++) {
        const text = lines[line] || "";
        let m: RegExpExecArray | null;
        regex.lastIndex = 0;
        while ((m = regex.exec(text)) !== null) {
            matches.push({ line, col: m.index });
            // Prevent infinite loop on zero-length matches
            if (m[0].length === 0) regex.lastIndex++;
        }
    }

    return matches;
}

/**
 * Find the next match after the given cursor position in the given direction.
 * Wraps around the buffer.
 */
export function findNextMatch(
    lines: string[],
    cursor: Position,
    pattern: string,
    direction: "forward" | "backward",
): Position | null {
    const matches = findAllMatches(lines, pattern);
    if (matches.length === 0) return null;

    if (direction === "forward") {
        // Find first match strictly after cursor
        for (const m of matches) {
            if (
                m.line > cursor.line ||
                (m.line === cursor.line && m.col > cursor.col)
            ) {
                return m;
            }
        }
        // Wrap: return first match
        return matches[0]!;
    } else {
        // Find last match strictly before cursor
        for (let i = matches.length - 1; i >= 0; i--) {
            const m = matches[i]!;
            if (
                m.line < cursor.line ||
                (m.line === cursor.line && m.col < cursor.col)
            ) {
                return m;
            }
        }
        // Wrap: return last match
        return matches[matches.length - 1]!;
    }
}

/**
 * Get the word under the cursor (for * and # commands).
 * A word is a sequence of word characters [a-zA-Z0-9_].
 */
export function getWordUnderCursor(
    lines: string[],
    cursor: Position,
): string | null {
    const line = lines[cursor.line] || "";
    if (cursor.col >= line.length) return null;

    const ch = line[cursor.col]!;
    // Must be on a word character
    if (!/[a-zA-Z0-9_]/.test(ch)) return null;

    // Expand left
    let start = cursor.col;
    while (start > 0 && /[a-zA-Z0-9_]/.test(line[start - 1]!)) start--;

    // Expand right
    let end = cursor.col;
    while (end < line.length - 1 && /[a-zA-Z0-9_]/.test(line[end + 1]!)) end++;

    return line.substring(start, end + 1);
}

// --- Motion functions for search ---

/**
 * Create a motion for `n` (repeat last search).
 */
export const searchNext: MotionFn = (lines, cursor, count) => {
    if (!searchState.lastPattern) {
        return { position: cursor, linewise: false, inclusive: false };
    }

    let pos = cursor;
    for (let i = 0; i < count; i++) {
        const result = findNextMatch(
            lines,
            pos,
            searchState.lastPattern,
            searchState.lastDirection,
        );
        if (result) {
            pos = result;
        } else {
            break;
        }
    }

    return { position: pos, linewise: false, inclusive: false };
};

/**
 * Create a motion for `N` (repeat last search in reverse direction).
 */
export const searchPrev: MotionFn = (lines, cursor, count) => {
    if (!searchState.lastPattern) {
        return { position: cursor, linewise: false, inclusive: false };
    }

    const reverseDir =
        searchState.lastDirection === "forward" ? "backward" : "forward";

    let pos = cursor;
    for (let i = 0; i < count; i++) {
        const result = findNextMatch(
            lines,
            pos,
            searchState.lastPattern,
            reverseDir,
        );
        if (result) {
            pos = result;
        } else {
            break;
        }
    }

    return { position: pos, linewise: false, inclusive: false };
};

/**
 * Execute the confirmed search as a motion.
 * Uses the pattern from the search state.
 */
export function executeSearchMotion(
    lines: string[],
    cursor: Position,
): MotionResult {
    if (!searchState.lastPattern) {
        return { position: cursor, linewise: false, inclusive: false };
    }

    const result = findNextMatch(
        lines,
        cursor,
        searchState.lastPattern,
        searchState.lastDirection,
    );
    if (result) {
        return { position: result, linewise: false, inclusive: false };
    }

    return { position: cursor, linewise: false, inclusive: false };
}

/**
 * Set up search for word under cursor (* or #).
 */
export function searchWordUnderCursor(
    lines: string[],
    cursor: Position,
    direction: "forward" | "backward",
): MotionResult {
    const word = getWordUnderCursor(lines, cursor);
    if (!word) {
        return { position: cursor, linewise: false, inclusive: false };
    }

    searchState.lastPattern = word;
    searchState.lastDirection = direction;

    const result = findNextMatch(lines, cursor, word, direction);
    if (result) {
        return { position: result, linewise: false, inclusive: false };
    }

    return { position: cursor, linewise: false, inclusive: false };
}
