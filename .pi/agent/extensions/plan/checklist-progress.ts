/**
 * Markdown checklist progress helpers for /plan execution.
 *
 * These helpers are intentionally pure: callers pass markdown text in and get
 * parsed items or updated markdown text out. They recognize indented GitHub
 * task-list items while preserving every byte of unrelated content when marking
 * a step complete.
 */

export interface ChecklistItem {
    /** 1-based step number in document order. */
    step: number;
    text: string;
    completed: boolean;
    /** 0-based line index in the markdown source. */
    lineIndex: number;
}

export interface MarkStepCompleteResult {
    content: string;
    changed: boolean;
    item?: ChecklistItem;
    error?: string;
}

type ParsedLine = {
    line: string;
    ending: string;
};

// Supports indented task-list bullets like:
//   - [ ] text
//   * [x] text
//   + [ ] text
//   1. [ ] text
//   1) [x] text
const TASK_ITEM_PATTERN = /^(\s*)(?:[-*+]|\d+[.)])(\s+)\[([ xX])\](\s*)(.*)$/;

function splitLinesPreservingEndings(content: string): ParsedLine[] {
    if (content.length === 0) return [];
    return content
        .match(/.*(?:\r\n|\n|\r|$)/g)!
        .filter(
            (part, index, parts) => part.length > 0 || index < parts.length - 1,
        )
        .map((part) => {
            const endingMatch = part.match(/(\r\n|\n|\r)$/);
            const ending = endingMatch?.[0] ?? "";
            return {
                line: ending ? part.slice(0, -ending.length) : part,
                ending,
            };
        });
}

function joinLines(lines: ParsedLine[]): string {
    return lines.map((part) => part.line + part.ending).join("");
}

function parseChecklistLine(line: string): {
    completed: boolean;
    text: string;
} | null {
    const match = line.match(TASK_ITEM_PATTERN);
    if (!match) return null;
    return {
        completed: match[3] !== " ",
        text: match[5].trim(),
    };
}

export function parseChecklist(content: string): ChecklistItem[] {
    const items: ChecklistItem[] = [];
    const lines = splitLinesPreservingEndings(content);

    lines.forEach((part, lineIndex) => {
        const parsed = parseChecklistLine(part.line);
        if (!parsed) return;
        items.push({
            step: items.length + 1,
            text: parsed.text,
            completed: parsed.completed,
            lineIndex,
        });
    });

    return items;
}

export function findChecklistItem(
    items: readonly ChecklistItem[],
    step: number,
): ChecklistItem | undefined {
    return items.find((item) => item.step === step);
}

export function markStepComplete(
    content: string,
    step: number,
): MarkStepCompleteResult {
    if (!Number.isInteger(step) || step < 1) {
        return {
            content,
            changed: false,
            error: "Step must be a positive integer.",
        };
    }

    const items = parseChecklist(content);
    const item = findChecklistItem(items, step);
    if (!item) {
        return {
            content,
            changed: false,
            error: `Step ${step} was not found in the plan checklist.`,
        };
    }

    if (item.completed) {
        return { content, changed: false, item };
    }

    const lines = splitLinesPreservingEndings(content);
    const line = lines[item.lineIndex];
    if (!line) {
        return {
            content,
            changed: false,
            item,
            error: `Step ${step} could not be updated because its source line was not found.`,
        };
    }

    // Replace only the checkbox marker on the matched task-list line.
    const updatedLine = line.line.replace(
        /^(\s*)(?:[-*+]|\d+[.)])(\s+)\[ \]/,
        (match) => match.replace("[ ]", "[x]"),
    );

    if (updatedLine === line.line) {
        return {
            content,
            changed: false,
            item,
            error: `Step ${step} could not be updated because its checkbox is not open.`,
        };
    }

    lines[item.lineIndex] = { ...line, line: updatedLine };
    return {
        content: joinLines(lines),
        changed: true,
        item: { ...item, completed: true },
    };
}
