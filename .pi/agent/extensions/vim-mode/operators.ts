/**
 * Operator system for vim.
 * Operators (d, c, y, >, <) combine with motions and text objects to act on ranges.
 */

import type { Position, MotionResult } from "./motions.js";
import type { TextObjectRange } from "./text-objects.js";
import { deleteToRegister, yankToRegister } from "./registers.js";

export interface OperatorRange {
  start: Position;
  end: Position;
  linewise: boolean;
  /** Whether end position is included (inclusive motion) */
  inclusive: boolean;
}

/**
 * Convert a motion result (from cursor) into an operator range.
 */
export function motionToRange(
  cursor: Position,
  motion: MotionResult,
): OperatorRange {
  const motionPos = motion.position;

  // Determine start/end (motion can go backward)
  let start: Position;
  let end: Position;

  if (
    motionPos.line < cursor.line ||
    (motionPos.line === cursor.line && motionPos.col < cursor.col)
  ) {
    start = motionPos;
    end = cursor;
  } else {
    start = cursor;
    end = motionPos;
  }

  return {
    start,
    end,
    linewise: motion.linewise,
    inclusive: motion.inclusive,
  };
}

/**
 * Convert a text object range into an operator range.
 */
export function textObjectToRange(range: TextObjectRange): OperatorRange {
  return {
    start: range.start,
    end: range.end,
    linewise: range.linewise,
    inclusive: true, // Text objects are always inclusive
  };
}

/**
 * Extract text from a range within the buffer lines.
 */
export function extractText(
  lines: string[],
  range: OperatorRange,
): string {
  if (range.linewise) {
    const startLine = range.start.line;
    const endLine = range.end.line;
    return lines.slice(startLine, endLine + 1).join("\n");
  }

  if (range.start.line === range.end.line) {
    const line = lines[range.start.line] || "";
    const endCol = range.inclusive ? range.end.col + 1 : range.end.col;
    return line.substring(range.start.col, endCol);
  }

  // Multi-line, character-wise
  const result: string[] = [];
  const firstLine = lines[range.start.line] || "";
  result.push(firstLine.substring(range.start.col));

  for (let i = range.start.line + 1; i < range.end.line; i++) {
    result.push(lines[i] || "");
  }

  const lastLine = lines[range.end.line] || "";
  const endCol = range.inclusive ? range.end.col + 1 : range.end.col;
  result.push(lastLine.substring(0, endCol));

  return result.join("\n");
}

/**
 * Delete text in a range and return the new lines + cursor position.
 */
export function deleteRange(
  lines: string[],
  range: OperatorRange,
): { newLines: string[]; cursor: Position } {
  const newLines = [...lines];

  if (range.linewise) {
    const startLine = range.start.line;
    const endLine = range.end.line;
    const deleteCount = endLine - startLine + 1;
    newLines.splice(startLine, deleteCount);

    // Ensure at least one empty line
    if (newLines.length === 0) {
      newLines.push("");
    }

    const cursorLine = Math.min(startLine, newLines.length - 1);
    const cursorLineText = newLines[cursorLine] || "";
    const match = cursorLineText.match(/^\s*/);
    const cursorCol = match ? match[0].length : 0;

    return { newLines, cursor: { line: cursorLine, col: cursorCol } };
  }

  // Character-wise delete
  if (range.start.line === range.end.line) {
    const line = newLines[range.start.line] || "";
    const endCol = range.inclusive ? range.end.col + 1 : range.end.col;
    newLines[range.start.line] =
      line.substring(0, range.start.col) + line.substring(endCol);

    const resultLine = newLines[range.start.line] || "";
    const cursorCol = Math.min(
      range.start.col,
      Math.max(0, resultLine.length - 1),
    );

    return {
      newLines,
      cursor: { line: range.start.line, col: cursorCol },
    };
  }

  // Multi-line character-wise delete
  const firstLine = newLines[range.start.line] || "";
  const lastLine = newLines[range.end.line] || "";
  const endCol = range.inclusive ? range.end.col + 1 : range.end.col;

  const merged =
    firstLine.substring(0, range.start.col) + lastLine.substring(endCol);
  newLines.splice(
    range.start.line,
    range.end.line - range.start.line + 1,
    merged,
  );

  if (newLines.length === 0) {
    newLines.push("");
  }

  const cursorCol = Math.min(
    range.start.col,
    Math.max(0, (newLines[range.start.line] || "").length - 1),
  );

  return {
    newLines,
    cursor: { line: range.start.line, col: Math.max(0, cursorCol) },
  };
}

/**
 * Indent lines in a range.
 */
export function indentRange(
  lines: string[],
  range: OperatorRange,
  shiftWidth: number = 2,
): { newLines: string[]; cursor: Position } {
  const newLines = [...lines];
  const indent = " ".repeat(shiftWidth);

  const startLine = range.start.line;
  const endLine = range.linewise
    ? range.end.line
    : range.end.line;

  for (let i = startLine; i <= endLine; i++) {
    if ((newLines[i] || "").length > 0) {
      newLines[i] = indent + (newLines[i] || "");
    }
  }

  const cursorLineText = newLines[startLine] || "";
  const match = cursorLineText.match(/^\s*/);
  const cursorCol = match ? match[0].length : 0;

  return { newLines, cursor: { line: startLine, col: cursorCol } };
}

/**
 * Dedent lines in a range.
 */
export function dedentRange(
  lines: string[],
  range: OperatorRange,
  shiftWidth: number = 2,
): { newLines: string[]; cursor: Position } {
  const newLines = [...lines];

  const startLine = range.start.line;
  const endLine = range.linewise
    ? range.end.line
    : range.end.line;

  for (let i = startLine; i <= endLine; i++) {
    const line = newLines[i] || "";
    let removed = 0;
    while (removed < shiftWidth && removed < line.length && line[removed] === " ") {
      removed++;
    }
    // Also handle tabs
    if (removed === 0 && line.length > 0 && line[0] === "\t") {
      removed = 1;
    }
    newLines[i] = line.substring(removed);
  }

  const cursorLineText = newLines[startLine] || "";
  const match = cursorLineText.match(/^\s*/);
  const cursorCol = match ? match[0].length : 0;

  return { newLines, cursor: { line: startLine, col: cursorCol } };
}

/**
 * Apply an operator to a range.
 * Returns the new buffer state and cursor position.
 */
export function applyOperator(
  operator: string,
  lines: string[],
  range: OperatorRange,
  register: string,
): {
  newLines: string[];
  cursor: Position;
  enterInsert: boolean;
} {
  const text = extractText(lines, range);

  switch (operator) {
    case "d": {
      deleteToRegister(register, text, range.linewise);
      const result = deleteRange(lines, range);
      return { ...result, enterInsert: false };
    }

    case "c": {
      deleteToRegister(register, text, range.linewise);
      if (range.linewise) {
        // For linewise change, replace lines with a single empty line and enter insert
        const newLines = [...lines];
        const startLine = range.start.line;
        const endLine = range.end.line;
        newLines.splice(startLine, endLine - startLine + 1, "");
        return {
          newLines,
          cursor: { line: startLine, col: 0 },
          enterInsert: true,
        };
      }
      const result = deleteRange(lines, range);
      // For change, cursor position is at the start of the deleted range
      return {
        newLines: result.newLines,
        cursor: { line: range.start.line, col: range.start.col },
        enterInsert: true,
      };
    }

    case "y": {
      yankToRegister(register, text, range.linewise);
      // Yank doesn't modify text, cursor goes to start of range
      return {
        newLines: [...lines],
        cursor: { line: range.start.line, col: range.start.col },
        enterInsert: false,
      };
    }

    case ">": {
      const result = indentRange(lines, range);
      return { ...result, enterInsert: false };
    }

    case "<": {
      const result = dedentRange(lines, range);
      return { ...result, enterInsert: false };
    }

    default:
      return { newLines: [...lines], cursor: range.start, enterInsert: false };
  }
}
