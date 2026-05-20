/**
 * Register system for yank/delete/paste.
 *
 * Registers:
 * - `"` (unnamed/default) - last delete, change, or yank
 * - `+` / `*` - system clipboard (aliased to each other)
 *
 * Explicit register selection is limited to the unnamed register and clipboard
 * aliases. Named, numbered, append, and black-hole registers are unsupported.
 */

export interface RegisterContent {
    text: string;
    linewise: boolean;
}

const registers: Map<string, RegisterContent> = new Map();

/**
 * Check if an explicitly selected register name is supported.
 */
export function isValidRegister(name: string): boolean {
    return name === '"' || name === "+" || name === "*";
}

/**
 * Get the content of a register.
 */
export function getRegister(name: string): RegisterContent | undefined {
    return registers.get(name);
}

/**
 * Store text after a yank operation.
 * Clipboard yanks update both clipboard aliases and the unnamed register;
 * all other yanks update the unnamed register.
 */
export function yankToRegister(
    name: string,
    text: string,
    linewise: boolean,
): void {
    // Handle clipboard registers
    if (name === "+" || name === "*") {
        const content: RegisterContent = { text, linewise };
        registers.set("+", content);
        registers.set("*", content);
        registers.set('"', content);
        return;
    }

    const content: RegisterContent = { text, linewise };

    registers.set('"', content);
}

/**
 * Store text after a delete/change operation.
 * Clipboard deletes/changes update both clipboard aliases and the unnamed
 * register; all other deletes/changes update the unnamed register.
 */
export function deleteToRegister(
    name: string,
    text: string,
    linewise: boolean,
): void {
    // Handle clipboard registers
    if (name === "+" || name === "*") {
        const content: RegisterContent = { text, linewise };
        registers.set("+", content);
        registers.set("*", content);
        registers.set('"', content);
        return;
    }

    const content: RegisterContent = { text, linewise };

    registers.set('"', content);
}
