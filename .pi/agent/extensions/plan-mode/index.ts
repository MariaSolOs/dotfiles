import { execFile } from "node:child_process";
import { access, mkdir, mkdtemp, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import { setTimeout as sleep } from "node:timers/promises";
import type {
    ExtensionAPI,
    ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const STATE_ENTRY = "local-plan-mode:state";
const STATUS_KEY = "local-plan-mode";
const WIDGET_KEY = "local-plan-mode-plan";

// Prefer hiding mutating tools from the model entirely; the tool_call hook below
// is still the final safety net in case another extension re-enables them.
const READ_ONLY_TOOL_CANDIDATES = [
    "read",
    "bash",
    "grep",
    "find",
    "ls",
    "lsp",
    "ast_search",
    "web_search",
    "fetch_content",
    "get_search_content",
    "request_user_input",
    "set_plan",
    "review_plan",
];

const WRITE_TOOLS = new Set([
    "write",
    "edit",
    "ast_rewrite",
    "apply_patch",
    "create_file",
    "delete_file",
]);

// Conservative bash policy: allow common inspection commands, block obvious
// mutation patterns, and ask the user for one-off approval when uncertain.
const BLOCKED_WORDS =
    /\b(rm|mv|cp|mkdir|rmdir|touch|chmod|chown|sudo|kill|pkill|reboot|shutdown|launchctl|brew\s+install|npm\s+(install|i|add|update|remove|uninstall|publish)|pnpm\s+(install|add|update|remove|publish)|yarn\s+(install|add|remove|upgrade|publish)|pip\s+install|git\s+(add|commit|push|pull|merge|rebase|reset|checkout|switch|restore|clean|stash|tag))\b/i;
const WRITE_SHELL =
    /(\s|^)(>|>>|2>|&>|tee\b)|[`$][(]|\b(xargs\s+rm|curl\b.*\|\s*(sh|bash)|wget\b.*\|\s*(sh|bash))\b/i;
const SAFE_BASE = new Set([
    "ls",
    "pwd",
    "cat",
    "head",
    "tail",
    "less",
    "more",
    "grep",
    "rg",
    "ag",
    "ack",
    "find",
    "fd",
    "tree",
    "wc",
    "file",
    "stat",
    "du",
    "df",
    "which",
    "type",
    "whereis",
    "env",
    "printenv",
    "uname",
    "whoami",
    "date",
    "uptime",
    "sort",
    "uniq",
    "cut",
    "sed",
    "awk",
    "jq",
    "git",
    "npm",
    "pnpm",
    "yarn",
]);
const SAFE_GIT = new Set([
    "status",
    "log",
    "diff",
    "show",
    "branch",
    "grep",
    "ls-files",
    "rev-parse",
    "remote",
]);
const SAFE_PACKAGE = new Set([
    "list",
    "ls",
    "outdated",
    "info",
    "view",
    "why",
    "audit",
]);

type State = {
    active: boolean;
    planFile?: string;
    lastPlan?: string;
    approvedCommands: string[];
    restoreTools?: string[];
};

function defaultState(): State {
    return { active: false, approvedCommands: [] };
}

function textFromContent(content: unknown): string {
    if (typeof content === "string") return content;
    if (!Array.isArray(content)) return "";
    return content
        .filter(
            (item): item is { type: string; text: string } =>
                !!item &&
                typeof item === "object" &&
                (item as any).type === "text" &&
                typeof (item as any).text === "string",
        )
        .map((item) => item.text)
        .join("\n");
}

// Used as a fallback when the model calls review_plan without passing the plan.
function latestAssistantText(ctx: ExtensionContext): string {
    const entries =
        ctx.sessionManager.getBranch?.() ?? ctx.sessionManager.getEntries();
    for (let i = entries.length - 1; i >= 0; i--) {
        const entry: any = entries[i];
        const msg = entry.message ?? entry;
        if (msg?.role === "assistant") return textFromContent(msg.content);
    }
    return "";
}

function slug(input: string): string {
    return (
        input
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, "-")
            .replace(/^-+|-+$/g, "")
            .slice(0, 64) || "plan"
    );
}

// Keep plans outside repositories by default so they do not become accidental
// project changes or commits.
function resolvePlanFile(ctx: ExtensionContext, existing?: string): string {
    if (existing) return existing;
    const sessionFile = ctx.sessionManager.getSessionFile?.();
    const base = sessionFile
        ? path.basename(sessionFile).replace(/\.[^.]+$/, "")
        : `${Date.now()}`;
    return path.join(
        os.homedir(),
        ".pi",
        "agent",
        "plans",
        `${slug(base)}.plan.md`,
    );
}

function commandExecutable(segment: string): string {
    const trimmed = segment.trim();
    const match = trimmed.match(/^([A-Za-z0-9_.\/-]+)/);
    return match ? path.basename(match[1]) : "";
}

function isReadOnlyCommand(command: string): boolean {
    const normalized = command.replace(/\\\n/g, " ").trim();
    if (!normalized) return false;
    if (BLOCKED_WORDS.test(normalized) || WRITE_SHELL.test(normalized))
        return false;
    // Avoid compound commands; supporting them safely requires shell parsing.
    if (/[;&]|\|\|/.test(normalized)) return false;

    for (const segment of normalized.split("|")) {
        const exe = commandExecutable(segment);
        if (!SAFE_BASE.has(exe)) return false;
        if (exe === "git") {
            const sub = segment.trim().split(/\s+/)[1] ?? "";
            if (!SAFE_GIT.has(sub)) return false;
        }
        if (exe === "npm" || exe === "pnpm" || exe === "yarn") {
            const sub = segment.trim().split(/\s+/)[1] ?? "";
            if (!SAFE_PACKAGE.has(sub)) return false;
        }
    }
    return true;
}

// The model often wraps plans in markdown fences or starts with a Plan heading;
// trim surrounding explanation before handing text to the human reviewer.
function extractPlan(text: string): string {
    const fence = text.match(/```(?:markdown|md)?\n([\s\S]*?)```/i);
    if (fence?.[1]?.toLowerCase().includes("plan")) return fence[1].trim();
    const idx = text.search(/^#{0,3}\s*plan\s*:?\s*$/im);
    return (idx >= 0 ? text.slice(idx) : text).trim();
}

function textContent(text: string) {
    return { type: "text" as const, text };
}

function shellQuote(value: string): string {
    return "'" + value.replace(/'/g, "'\\''") + "'";
}

function appleScriptString(value: string): string {
    return JSON.stringify(value);
}

function execFilePromise(command: string, args: string[]): Promise<void> {
    return new Promise((resolve, reject) => {
        execFile(command, args, (error) => {
            if (error) reject(error);
            else resolve();
        });
    });
}

async function fileExists(file: string): Promise<boolean> {
    try {
        await access(file);
        return true;
    } catch {
        return false;
    }
}

async function waitForReviewTab(doneFile: string, cancelFile: string) {
    while (true) {
        if (await fileExists(doneFile)) return true;
        if (await fileExists(cancelFile)) return false;
        await sleep(250);
    }
}

async function runAppleScript(script: string): Promise<void> {
    await execFilePromise("osascript", ["-e", script]);
}

async function focusPreviousGhosttyTab(): Promise<void> {
    await runAppleScript(`
        tell application "Ghostty" to activate
        delay 0.05
        tell application "System Events"
            tell process "ghostty"
                keystroke "[" using {command down, shift down}
            end tell
        end tell
    `);
}

async function openGhosttyReviewTab(
    planFile: string,
    ctx: ExtensionContext,
): Promise<
    | {
          approve: () => Promise<void>;
          cancel: () => Promise<void>;
          editedText: () => Promise<string>;
      }
    | undefined
> {
    if (process.platform !== "darwin" || process.env.TERM_PROGRAM !== "ghostty")
        return undefined;

    const tempDir = await mkdtemp(path.join(os.tmpdir(), "pi-plan-review-"));
    const doneFile = path.join(tempDir, "done");
    const approveFile = path.join(tempDir, "approved");
    const cancelFile = path.join(tempDir, "cancelled");
    const editor = process.env.VISUAL || process.env.EDITOR || "nvim";
    const title = `pi plan review ${path.basename(tempDir)}`;
    const tabScript = [
        `printf '\\033]0;%s\\007' ${shellQuote(title)}`,
        `${shellQuote(editor)} ${shellQuote(planFile)}`,
        "status=$?",
        `if [ "$status" -eq 0 ]; then touch ${shellQuote(doneFile)}; else touch ${shellQuote(cancelFile)}; fi`,
        `while [ ! -e ${shellQuote(approveFile)} ] && [ ! -e ${shellQuote(cancelFile)} ]; do sleep 0.2; done`,
    ].join("; ");
    const command = `/bin/zsh -lc ${shellQuote(tabScript)}`;
    const script = `
        set oldClipboard to the clipboard
        set the clipboard to ${appleScriptString(command)}
        tell application "Ghostty" to activate
        delay 0.05
        tell application "System Events"
            tell process "ghostty"
                keystroke "t" using {option down, shift down}
                delay 0.2
                keystroke "v" using {command down}
                key code 36
            end tell
        end tell
        delay 0.05
        set the clipboard to oldClipboard
    `;

    try {
        await runAppleScript(script);
    } catch (error) {
        ctx.ui.notify(
            `Could not open Ghostty review tab; falling back to inline editor. ${
                error instanceof Error ? error.message : String(error)
            }`,
            "warning",
        );
        return undefined;
    }

    ctx.ui.notify(
        "Plan opened in a Ghostty tab. Save and quit the editor to continue approval in Pi.",
        "info",
    );
    const completed = await waitForReviewTab(doneFile, cancelFile);
    if (!completed) return undefined;

    try {
        await focusPreviousGhosttyTab();
    } catch {
        ctx.ui.notify(
            "Plan edit finished. Return to the Pi tab to approve it.",
            "info",
        );
    }

    return {
        approve: async () => {
            await writeFile(approveFile, "approved\n", "utf8");
        },
        cancel: async () => {
            await writeFile(cancelFile, "cancelled\n", "utf8");
        },
        editedText: async () => readFile(planFile, "utf8"),
    };
}

export default function planMode(pi: ExtensionAPI) {
    let state: State = defaultState();

    const allToolNames = () => pi.getAllTools().map((tool) => tool.name);
    const activeToolNames = () => pi.getActiveTools();
    const planToolNames = () => {
        const available = new Set(allToolNames());
        const names = READ_ONLY_TOOL_CANDIDATES.filter((name) =>
            available.has(name),
        );
        return names.length
            ? names
            : activeToolNames().filter((name) => !WRITE_TOOLS.has(name));
    };

    function persist(ctx: ExtensionContext) {
        // Custom entries are not sent to the model, but survive reload/resume.
        pi.appendEntry(STATE_ENTRY, { ...state, timestamp: Date.now() });
        refreshUi(ctx);
    }

    function refreshUi(ctx: ExtensionContext) {
        if (!ctx.hasUI) return;
        ctx.ui.setStatus(
            STATUS_KEY,
            state.active ? ctx.ui.theme.fg("warning", "⏸ plan") : undefined,
        );
        if (!state.active) {
            ctx.ui.setWidget(WIDGET_KEY, undefined);
            return;
        }
        const lines = [ctx.ui.theme.fg("warning", "Plan mode: read-only")];
        if (state.planFile)
            lines.push(ctx.ui.theme.fg("muted", state.planFile));
        if (state.lastPlan) {
            lines.push("");
            lines.push(...state.lastPlan.split("\n").slice(0, 8));
            if (state.lastPlan.split("\n").length > 8)
                lines.push(ctx.ui.theme.fg("dim", "…"));
        }
        ctx.ui.setWidget(WIDGET_KEY, lines);
    }

    function syncTools() {
        // Re-apply on each turn because tool availability can change after reloads
        // or when other extensions register tools dynamically.
        if (state.active) {
            pi.setActiveTools(planToolNames());
        } else if (state.restoreTools?.length) {
            pi.setActiveTools(state.restoreTools);
            state.restoreTools = undefined;
        }
    }

    async function writePlan(ctx: ExtensionContext, plan: string) {
        const planFile = resolvePlanFile(ctx, state.planFile);
        await mkdir(path.dirname(planFile), { recursive: true });
        await writeFile(planFile, plan.trimEnd() + "\n", "utf8");
        state.planFile = planFile;
        state.lastPlan = plan.trim();
        persist(ctx);
        return planFile;
    }

    function enter(ctx: ExtensionContext) {
        if (!state.active) {
            state.restoreTools = activeToolNames();
            state.active = true;
            state.planFile = resolvePlanFile(ctx, state.planFile);
            state.approvedCommands = state.approvedCommands ?? [];
        }
        syncTools();
        persist(ctx);
        ctx.ui.notify(
            `Plan mode enabled. Plan file: ${state.planFile}`,
            "info",
        );
    }

    function exit(ctx: ExtensionContext) {
        state.active = false;
        syncTools();
        persist(ctx);
        ctx.ui.notify("Plan mode disabled. Normal tools restored.", "info");
    }

    // The model writes the canonical plan through a tool instead of directly
    // editing files, keeping plan writes narrow and intentional.
    pi.registerTool({
        name: "set_plan",
        label: "Set Plan",
        description:
            "Save or replace the current plan-mode markdown plan file. Use after drafting or materially revising a plan.",
        promptSnippet:
            "Save the canonical markdown plan while plan mode is active",
        promptGuidelines: [
            "Use set_plan in plan mode after drafting or materially revising the plan.",
        ],
        parameters: Type.Object({
            plan: Type.String({ description: "Complete markdown plan text" }),
        }),
        async execute(_id, params: { plan: string }, _signal, _onUpdate, ctx) {
            if (!state.active)
                return {
                    isError: true,
                    content: [
                        textContent("set_plan is only available in plan mode."),
                    ],
                    details: {},
                };
            const file = await writePlan(ctx, params.plan);
            return {
                content: [textContent(`Plan saved to ${file}`)],
                details: { file, plan: params.plan },
            };
        },
    });

    // A blocking clarification tool nudges the model to resolve ambiguity before
    // producing an implementation plan.
    pi.registerTool({
        name: "request_user_input",
        label: "Ask User",
        description:
            "Ask the user clarifying planning questions before finalizing the plan.",
        promptSnippet: "Ask blocking clarification questions during plan mode",
        promptGuidelines: [
            "Use request_user_input in plan mode when user goals, scope, risk tolerance, or acceptance criteria are ambiguous.",
        ],
        parameters: Type.Object({
            question: Type.String(),
            options: Type.Optional(Type.Array(Type.String())),
        }),
        async execute(
            _id,
            params: { question: string; options?: string[] },
            _signal,
            _onUpdate,
            ctx,
        ) {
            if (params.options?.length) {
                const choice = await ctx.ui.select(params.question, [
                    ...params.options,
                    "Other / custom",
                ]);
                if (choice && choice !== "Other / custom")
                    return {
                        content: [textContent(choice)],
                        details: { answer: choice },
                    };
            }
            const answer = await ctx.ui.input(params.question, "Your answer");
            return {
                content: [textContent(answer || "No answer provided.")],
                details: { answer: answer || "" },
            };
        },
    });

    // Final handoff: let the user edit/approve the plan, then queue execution in
    // normal mode so implementation gets the full tool set back.
    pi.registerTool({
        name: "review_plan",
        label: "Review Plan",
        description:
            "Open the current plan in an editor for human review. The user can approve it or return edited feedback.",
        promptSnippet:
            "Ask the user to review the current plan before implementation",
        promptGuidelines: [
            "Use review_plan after set_plan and before implementation when plan mode is active.",
        ],
        parameters: Type.Object({ plan: Type.Optional(Type.String()) }),
        async execute(_id, params: { plan?: string }, _signal, _onUpdate, ctx) {
            const draft =
                params.plan || state.lastPlan || latestAssistantText(ctx);
            const initialPlan = extractPlan(draft);
            const initialFile = await writePlan(ctx, initialPlan);
            const reviewTab = await openGhosttyReviewTab(initialFile, ctx);
            const edited = reviewTab
                ? await reviewTab.editedText()
                : await ctx.ui.editor(
                      "Review/edit plan, then save to approve",
                      initialPlan,
                  );
            if (!edited?.trim()) {
                await reviewTab?.cancel();
                return {
                    isError: true,
                    content: [textContent("Plan review cancelled or empty.")],
                    details: {},
                };
            }
            const file = await writePlan(ctx, edited);
            const approved = await ctx.ui.confirm(
                "Approve plan?",
                "Exit plan mode and begin implementation?",
            );
            if (approved) {
                await reviewTab?.approve();
                exit(ctx);
                pi.sendUserMessage(
                    `Plan approved. Implement this plan now:\n\n${edited}`,
                    { deliverAs: "followUp" },
                );
                return {
                    content: [
                        textContent(
                            `Plan approved and saved to ${file}. Implementation queued.`,
                        ),
                    ],
                    details: { file, approved: true },
                };
            }
            await reviewTab?.cancel();
            return {
                content: [
                    textContent(
                        `Plan saved to ${file}. Continue planning with the user's edits.`,
                    ),
                ],
                details: { file, approved: false },
            };
        },
    });

    pi.registerCommand("plan", {
        description: "Toggle plan mode on or off. Usage: /plan",
        handler: async (args, ctx) => {
            if (args.trim()) {
                ctx.ui.notify("Usage: /plan", "warning");
                return;
            }

            if (state.active) return exit(ctx);
            return enter(ctx);
        },
    });

    pi.on("session_start", async (_event, ctx) => {
        const entries = ctx.sessionManager.getEntries();
        for (const entry of entries) {
            if (
                (entry as any).type === "custom" &&
                (entry as any).customType === STATE_ENTRY
            ) {
                state = { ...defaultState(), ...((entry as any).data ?? {}) };
            }
        }
        if (state.active) state.planFile = resolvePlanFile(ctx, state.planFile);
        syncTools();
        refreshUi(ctx);
    });

    pi.on("before_agent_start", async (event, ctx) => {
        syncTools();
        if (!state.active) return;
        const planFile = resolvePlanFile(ctx, state.planFile);
        state.planFile = planFile;
        refreshUi(ctx);
        return {
            systemPrompt: `${event.systemPrompt}\n\n[PLAN MODE ACTIVE - READ ONLY]\nYou are in planning mode. Do not modify the repository or system state.\n\nWorkflow:\n1. Inspect relevant code/config/tests first; no evidence-free planning.\n2. Use request_user_input for blocking ambiguity.\n3. Produce a concise, concrete markdown plan with files/components, ordered steps, validation, risks, and rollback notes.\n4. Save the canonical plan with set_plan to: ${planFile}\n5. Call review_plan for user approval before implementation.\n\nHard restrictions: no write/edit tools, no mutating shell commands, no dependency installs, no git mutations.`,
        };
    });

    pi.on("tool_call", async (event, ctx) => {
        if (!state.active) return;
        if (WRITE_TOOLS.has(event.toolName)) {
            return {
                block: true,
                reason: "Plan mode is active: write/edit tools are blocked. Use /plan to leave plan mode.",
            };
        }
        if (event.toolName === "bash") {
            const command = String((event.input as any)?.command ?? "");
            if (
                state.approvedCommands.includes(command) ||
                isReadOnlyCommand(command)
            )
                return;
            const allow = await ctx.ui.confirm(
                "Plan mode: bash command is not clearly read-only",
                `$ ${command}\n\nAllow this command once?`,
            );
            if (allow) {
                state.approvedCommands.push(command);
                persist(ctx);
                return;
            }
            return {
                block: true,
                reason: "Plan mode blocked bash command because it is not on the read-only allowlist.",
            };
        }
    });

    pi.on("message_end", async (event, ctx) => {
        if (!state.active || event.message.role !== "assistant") return;
        const text = textFromContent((event.message as any).content);
        if (/^#{0,3}\s*plan\s*:?\s*$/im.test(text) && !state.lastPlan) {
            state.lastPlan = extractPlan(text);
            persist(ctx);
        }
    });
}
