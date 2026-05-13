/**
 * Text object definitions for vim operators.
 * Each text object returns a range { start, end } within the buffer.
 */

import type { Position } from "./motions.js";

export interface TextObjectRange {
  start: Position;
  end: Position;
  linewise: boolean;
}

export type TextObjectFn = (
  lines: string[],
  cursor: Position,
) => TextObjectRange | null;

// --- Character classification helpers ---

function isWordChar(ch: string): boolean {
  return /[a-zA-Z0-9_]/.test(ch);
}

function isWhitespace(ch: string): boolean {
  return ch === " " || ch === "\t";
}

// --- Word text objects ---

/**
 * `iw` - Inner word: the word under the cursor (no surrounding whitespace).
 */
export const innerWord: TextObjectFn = (lines, cursor) => {
  const line = lines[cursor.line] || "";
  if (line.length === 0) return null;

  const col = Math.min(cursor.col, line.length - 1);
  const ch = line[col]!;

  let start = col;
  let end = col;

  if (isWordChar(ch)) {
    while (start > 0 && isWordChar(line[start - 1]!)) start--;
    while (end < line.length - 1 && isWordChar(line[end + 1]!)) end++;
  } else if (isWhitespace(ch)) {
    while (start > 0 && isWhitespace(line[start - 1]!)) start--;
    while (end < line.length - 1 && isWhitespace(line[end + 1]!)) end++;
  } else {
    // Punctuation
    while (start > 0 && !isWordChar(line[start - 1]!) && !isWhitespace(line[start - 1]!)) start--;
    while (end < line.length - 1 && !isWordChar(line[end + 1]!) && !isWhitespace(line[end + 1]!)) end++;
  }

  return {
    start: { line: cursor.line, col: start },
    end: { line: cursor.line, col: end },
    linewise: false,
  };
};

/**
 * `aw` - A word: the word under the cursor plus trailing (or leading) whitespace.
 */
export const aWord: TextObjectFn = (lines, cursor) => {
  const inner = innerWord(lines, cursor);
  if (!inner) return null;

  const line = lines[cursor.line] || "";
  let { start, end } = { start: inner.start.col, end: inner.end.col };

  // Try to include trailing whitespace first
  if (end + 1 < line.length && isWhitespace(line[end + 1]!)) {
    end++;
    while (end + 1 < line.length && isWhitespace(line[end + 1]!)) end++;
  } else if (start > 0 && isWhitespace(line[start - 1]!)) {
    // No trailing whitespace, include leading whitespace
    start--;
    while (start > 0 && isWhitespace(line[start - 1]!)) start--;
  }

  return {
    start: { line: cursor.line, col: start },
    end: { line: cursor.line, col: end },
    linewise: false,
  };
};

/**
 * `iW` - Inner WORD (whitespace-delimited).
 */
export const innerWORD: TextObjectFn = (lines, cursor) => {
  const line = lines[cursor.line] || "";
  if (line.length === 0) return null;

  const col = Math.min(cursor.col, line.length - 1);
  const ch = line[col]!;

  let start = col;
  let end = col;

  if (isWhitespace(ch)) {
    while (start > 0 && isWhitespace(line[start - 1]!)) start--;
    while (end < line.length - 1 && isWhitespace(line[end + 1]!)) end++;
  } else {
    while (start > 0 && !isWhitespace(line[start - 1]!)) start--;
    while (end < line.length - 1 && !isWhitespace(line[end + 1]!)) end++;
  }

  return {
    start: { line: cursor.line, col: start },
    end: { line: cursor.line, col: end },
    linewise: false,
  };
};

/**
 * `aW` - A WORD plus trailing/leading whitespace.
 */
export const aWORD: TextObjectFn = (lines, cursor) => {
  const inner = innerWORD(lines, cursor);
  if (!inner) return null;

  const line = lines[cursor.line] || "";
  let { start, end } = { start: inner.start.col, end: inner.end.col };

  if (end + 1 < line.length && isWhitespace(line[end + 1]!)) {
    end++;
    while (end + 1 < line.length && isWhitespace(line[end + 1]!)) end++;
  } else if (start > 0 && isWhitespace(line[start - 1]!)) {
    start--;
    while (start > 0 && isWhitespace(line[start - 1]!)) start--;
  }

  return {
    start: { line: cursor.line, col: start },
    end: { line: cursor.line, col: end },
    linewise: false,
  };
};

// --- Quote text objects ---

function makeQuoteTextObject(quoteChar: string, inner: boolean): TextObjectFn {
  return (lines, cursor) => {
    const line = lines[cursor.line] || "";
    const col = cursor.col;

    // Find the opening and closing quotes on the current line
    // Strategy: find all quote positions, pair them up, find pair containing cursor
    const quotePositions: number[] = [];
    for (let i = 0; i < line.length; i++) {
      if (line[i] === quoteChar && (i === 0 || line[i - 1] !== "\\")) {
        quotePositions.push(i);
      }
    }

    // Try to find a pair that contains the cursor
    for (let i = 0; i < quotePositions.length - 1; i += 2) {
      const open = quotePositions[i]!;
      const close = quotePositions[i + 1]!;

      if (col >= open && col <= close) {
        if (inner) {
          // Inner: between quotes (exclusive)
          if (close - open <= 1) {
            // Empty quotes - return a zero-width range at the position after open quote
            return {
              start: { line: cursor.line, col: open + 1 },
              end: { line: cursor.line, col: open },
              linewise: false,
            };
          }
          return {
            start: { line: cursor.line, col: open + 1 },
            end: { line: cursor.line, col: close - 1 },
            linewise: false,
          };
        } else {
          // Around: including quotes
          return {
            start: { line: cursor.line, col: open },
            end: { line: cursor.line, col: close },
            linewise: false,
          };
        }
      }
    }

    // If cursor is before the first pair, use first pair
    if (quotePositions.length >= 2 && col < quotePositions[0]!) {
      const open = quotePositions[0]!;
      const close = quotePositions[1]!;
      if (inner) {
        if (close - open <= 1) {
          return {
            start: { line: cursor.line, col: open + 1 },
            end: { line: cursor.line, col: open },
            linewise: false,
          };
        }
        return {
          start: { line: cursor.line, col: open + 1 },
          end: { line: cursor.line, col: close - 1 },
          linewise: false,
        };
      }
      return {
        start: { line: cursor.line, col: open },
        end: { line: cursor.line, col: close },
        linewise: false,
      };
    }

    return null; // No matching quotes found
  };
}

export const innerDoubleQuote = makeQuoteTextObject('"', true);
export const aDoubleQuote = makeQuoteTextObject('"', false);
export const innerSingleQuote = makeQuoteTextObject("'", true);
export const aSingleQuote = makeQuoteTextObject("'", false);
export const innerBacktick = makeQuoteTextObject("`", true);
export const aBacktick = makeQuoteTextObject("`", false);

// --- Bracket/delimiter text objects ---

function makeBracketTextObject(
  openChar: string,
  closeChar: string,
  inner: boolean,
): TextObjectFn {
  return (lines, cursor) => {
    // Search backward for the opening bracket (handling nesting)
    let depth = 0;
    let openLine = cursor.line;
    let openCol = cursor.col;
    let found = false;

    // Search backward from cursor
    outer_back: for (let ln = cursor.line; ln >= 0; ln--) {
      const lineText = lines[ln] || "";
      const startCol = ln === cursor.line ? cursor.col : lineText.length - 1;

      for (let c = startCol; c >= 0; c--) {
        const ch = lineText[c];
        if (ch === closeChar && !(ln === cursor.line && c === cursor.col)) {
          depth++;
        } else if (ch === openChar) {
          if (depth === 0) {
            openLine = ln;
            openCol = c;
            found = true;
            break outer_back;
          }
          depth--;
        }
      }
    }

    if (!found) return null;

    // Search forward for the matching closing bracket
    depth = 0;
    let closeLine = cursor.line;
    let closeCol = cursor.col;
    found = false;

    outer_fwd: for (let ln = openLine; ln < lines.length; ln++) {
      const lineText = lines[ln] || "";
      const startCol = ln === openLine ? openCol + 1 : 0;

      for (let c = startCol; c < lineText.length; c++) {
        const ch = lineText[c];
        if (ch === openChar) {
          depth++;
        } else if (ch === closeChar) {
          if (depth === 0) {
            closeLine = ln;
            closeCol = c;
            found = true;
            break outer_fwd;
          }
          depth--;
        }
      }
    }

    if (!found) return null;

    if (inner) {
      // Inner: between the brackets (exclusive of brackets themselves)
      // If open and close are on the same line and adjacent, empty range
      if (openLine === closeLine && closeCol - openCol <= 1) {
        return {
          start: { line: openLine, col: openCol + 1 },
          end: { line: closeLine, col: openCol },
          linewise: false,
        };
      }
      return {
        start: { line: openLine, col: openCol + 1 },
        end: { line: closeLine, col: closeCol - 1 },
        linewise: false,
      };
    } else {
      // Around: including the brackets
      return {
        start: { line: openLine, col: openCol },
        end: { line: closeLine, col: closeCol },
        linewise: false,
      };
    }
  };
}

export const innerParen = makeBracketTextObject("(", ")", true);
export const aParen = makeBracketTextObject("(", ")", false);
export const innerBrace = makeBracketTextObject("{", "}", true);
export const aBrace = makeBracketTextObject("{", "}", false);
export const innerBracket = makeBracketTextObject("[", "]", true);
export const aBracket = makeBracketTextObject("[", "]", false);
export const innerAngle = makeBracketTextObject("<", ">", true);
export const aAngle = makeBracketTextObject("<", ">", false);

/**
 * Resolve a text object key sequence like "iw", "a(", etc.
 * `prefix` is 'i' or 'a', `key` is the object identifier.
 */
export function resolveTextObject(
  prefix: string,
  key: string,
): TextObjectFn | null {
  const isInner = prefix === "i";

  switch (key) {
    case "w":
      return isInner ? innerWord : aWord;
    case "W":
      return isInner ? innerWORD : aWORD;
    case '"':
      return isInner ? innerDoubleQuote : aDoubleQuote;
    case "'":
      return isInner ? innerSingleQuote : aSingleQuote;
    case "`":
      return isInner ? innerBacktick : aBacktick;
    case "(":
    case ")":
    case "b":
      return isInner ? innerParen : aParen;
    case "{":
    case "}":
    case "B":
      return isInner ? innerBrace : aBrace;
    case "[":
    case "]":
      return isInner ? innerBracket : aBracket;
    case "<":
    case ">":
      return isInner ? innerAngle : aAngle;
    default:
      return null;
  }
}
