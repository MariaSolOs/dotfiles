// @ts-nocheck
// @generated — DO NOT EDIT. Source: packages/shared/checklist.ts
/**
 * Checklist parsing and progress tracking utilities.
 *
 * Shared between Pi extension and OpenCode plugin for plan execution tracking.
 */

export interface ChecklistItem {
    /** 1-based step number, compatible with markCompletedSteps/extractDoneSteps. */
    step: number;
    text: string;
    completed: boolean;
}

/**
 * Parse standard markdown checkboxes from file content.
 *
 * Matches lines like:
 *   - [ ] Step description
 *   - [x] Completed step
 *   * [ ] Alternative bullet
 */
export function parseChecklist(content: string): ChecklistItem[] {
    const items: ChecklistItem[] = [];
    const pattern = /^[-*]\s*\[([ xX])\]\s+(.+)$/gm;

    for (const match of content.matchAll(pattern)) {
        const completed = match[1] !== " ";
        const text = match[2].trim();
        if (text.length > 0) {
            items.push({ step: items.length + 1, text, completed });
        }
    }
    return items;
}

export function extractDoneSteps(message: string): number[] {
    const steps: number[] = [];
    for (const match of message.matchAll(/\[DONE:(\d+)\]/gi)) {
        const step = Number(match[1]);
        if (Number.isFinite(step)) steps.push(step);
    }
    return steps;
}

export function markCompletedSteps(
    text: string,
    items: ChecklistItem[],
): number {
    const doneSteps = extractDoneSteps(text);
    for (const step of doneSteps) {
        const item = items.find((t) => t.step === step);
        if (item) item.completed = true;
    }
    return doneSteps.length;
}
