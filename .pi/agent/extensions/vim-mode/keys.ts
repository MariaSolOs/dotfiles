/**
 * Key parsing utilities for vim keybindings.
 */

/** Check if a key is a printable character */
export function isPrintable(data: string): boolean {
  return data.length === 1 && data.charCodeAt(0) >= 32;
}

/** Check if key is a digit (for count prefix) */
export function isDigit(data: string): boolean {
  return data.length === 1 && data >= "0" && data <= "9";
}

/** Escape sequences for cursor movement */
export const ESCAPE_SEQS = {
  up: "\x1b[A",
  down: "\x1b[B",
  right: "\x1b[C",
  left: "\x1b[D",
  home: "\x01",     // Ctrl+A
  end: "\x05",      // Ctrl+E
  delete: "\x1b[3~",
  backspace: "\x7f",
  newline: "\n",
} as const;
