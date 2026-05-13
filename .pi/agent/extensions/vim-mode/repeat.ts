/**
 * Dot-repeat (.) system for vim.
 *
 * Records each "change" as a replayable sequence:
 * - operator + motion/textobj keys
 * - insert session entry key + inserted text
 * - simple edits (x, X, r{char}, ~, J, p, P)
 *
 * The `.` command replays the last change, optionally with a new count.
 */

export interface RecordedChange {
  /** Normal mode keys that initiated this change (e.g., ["d", "2", "w"], ["c", "i", "w"]) */
  keys: string[];
  /** Text typed during insert mode session, if the change entered insert mode */
  insertedText: string;
  /** Whether insert mode was entered as part of this change */
  enteredInsert: boolean;
}

let lastChange: RecordedChange | null = null;
let currentRecording: RecordedChange | null = null;
let isRecordingInsert = false;

/**
 * Start recording a new change. Call this when a change-initiating key is pressed.
 */
export function startRecording(): void {
  currentRecording = {
    keys: [],
    insertedText: "",
    enteredInsert: false,
  };
  isRecordingInsert = false;
}

/**
 * Add a key to the current recording.
 */
export function recordKey(key: string): void {
  if (currentRecording) {
    currentRecording.keys.push(key);
  }
}

/**
 * Mark that the current change entered insert mode.
 */
export function markInsertEntry(): void {
  if (currentRecording) {
    currentRecording.enteredInsert = true;
    isRecordingInsert = true;
  }
}

/**
 * Record text typed during insert mode.
 */
export function recordInsertText(text: string): void {
  if (currentRecording && isRecordingInsert) {
    currentRecording.insertedText += text;
  }
}

/**
 * Record a backspace during insert mode (remove last char from insertedText).
 */
export function recordInsertBackspace(): void {
  if (currentRecording && isRecordingInsert && currentRecording.insertedText.length > 0) {
    currentRecording.insertedText = currentRecording.insertedText.slice(0, -1);
  }
}

/**
 * Finalize the current recording and save it as the last change.
 * Call this when a change completes (operator applied, or Escape from insert).
 */
export function finalizeRecording(): void {
  if (currentRecording && currentRecording.keys.length > 0) {
    lastChange = currentRecording;
  }
  currentRecording = null;
  isRecordingInsert = false;
}

/**
 * Check if we're currently recording a change.
 */
export function isCurrentlyRecording(): boolean {
  return currentRecording !== null;
}

/**
 * Check if we're in the insert-recording phase.
 */
export function isRecordingInsertMode(): boolean {
  return isRecordingInsert;
}

/**
 * Get the last recorded change for dot-repeat.
 */
export function getLastChange(): RecordedChange | null {
  return lastChange;
}

/**
 * Discard the current recording without saving.
 */
export function discardRecording(): void {
  currentRecording = null;
  isRecordingInsert = false;
}
