// @ts-nocheck
/**
 * Plan Pi Extension — File-based plan mode with visual browser review.
 *
 * During planning the agent writes any markdown file anywhere inside cwd and
 * calls plan_submit_plan with the path. The user reviews in the
 * browser UI and can approve, deny with annotations, or request changes.
 *
 * Features:
 * - /plan command to toggle
 * - --plan flag to start in planning mode
 * - Bash unrestricted during planning (prompt-guided)
 * - Writes restricted to markdown files inside cwd during planning
 * - plan_submit_plan tool with browser-based visual approval
 * - plan_complete_step tool for live execution progress tracking
 * - /plan-review command for code review
 * - /plan-annotate command for markdown annotation
 */

import {
    existsSync,
    readFileSync,
    statSync,
    unlinkSync,
    writeFileSync,
} from "node:fs";
import { basename, resolve } from "node:path";
import type { ThinkingLevel } from "@earendil-works/pi-agent-core";
import { Type } from "@earendil-works/pi-ai";
import {
    DynamicBorder,
    type ExtensionAPI,
    type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import {
    Container,
    type SelectItem,
    SelectList,
    Text,
} from "@earendil-works/pi-tui";
import {
    buildPromptVariables,
    formatTodoList,
    loadPlanConfig,
    renderTemplate,
    resolvePhaseProfile,
} from "./config.js";
import {
    type ChecklistItem,
    markStepComplete,
    parseChecklist,
} from "./checklist-progress.js";
import { hasMarkdownFiles, resolveUserPath } from "./generated/resolve-file.js";
import { FILE_BROWSER_EXCLUDED } from "./generated/reference-common.js";
import { htmlToMarkdown } from "./generated/html-to-markdown.js";
import {
    urlToMarkdown,
    isConvertedSource,
} from "./generated/url-to-markdown.js";
import { loadConfig, resolveUseJina } from "./generated/config.js";
import { readImprovementHook } from "./generated/improvement-hooks.js";
import { composeImproveContext } from "./generated/pfm-reminder.js";
import {
    getReviewApprovedPrompt,
    getReviewDeniedSuffix,
    getPlanDeniedPrompt,
    getPlanApprovedPrompt,
    getPlanApprovedWithNotesPrompt,
    getPlanAutoApprovedPrompt,
    getPlanToolName,
    buildPlanFileRule,
    getAnnotateFileFeedbackPrompt,
    getAnnotateMessageFeedbackPrompt,
} from "./generated/prompts.js";
import { parseAnnotateArgs } from "./generated/annotate-args.js";
import { parseReviewArgs } from "./generated/review-args.js";
import { resolveAtReference } from "./generated/at-reference.js";
import {
    hasPlanBrowserHtml,
    hasReviewBrowserHtml,
    getStartupErrorMessage,
    openArchiveBrowserAction,
    startCodeReviewBrowserSession,
    startLastMessageAnnotationSession,
    startMarkdownAnnotationSession,
    openPlanReviewBrowser,
    registerPlanEventListeners,
} from "./plan-events.js";
import {
    getAssistantMessageText,
    getLastAssistantMessageSnapshot,
    hasSessionMovedPastEntry,
} from "./assistant-message.js";
import {
    getPiSessionIdentity,
    isCurrentPiSessionDifferentFrom,
    notifyCurrentPiSession,
    type PiSessionIdentity,
    registerCurrentPiSession,
    sendUserMessageToCurrentPiSession,
    withCurrentPiSessionFallbackHeader,
} from "./current-pi-session.js";
import {
    getToolsForPhase,
    isPlanWritePathAllowed,
    PLAN_ASK_QUESTION_TOOL,
    PLAN_COMPLETE_STEP_TOOL,
    PLAN_SUBMIT_TOOL,
    type Phase,
    stripPlanningOnlyTools,
} from "./tool-scope.ts";

// ── Types ──────────────────────────────────────────────────────────────

type SavedPhaseState = {
    activeTools: string[];
    model?: { provider: string; id: string };
    thinkingLevel: ThinkingLevel;
};

type CompactApprovedPlanContext = {
    planText: string;
    planFilePath: string;
    approvalEntryId?: string;
};

type PersistedPlanState = {
    phase: Phase;
    lastSubmittedPath?: string;
    savedState?: SavedPhaseState;
    compactApprovedPlanContext?: CompactApprovedPlanContext;
};

type PlanAskQuestionDetails = {
    question: string;
    answers: string[];
    answer: string | null;
    cancelled?: boolean;
    ok: boolean;
};

function getPlanReviewAvailabilityWarning(options: {
    hasUI: boolean;
    hasPlanHtml: boolean;
}): string | null {
    const { hasUI, hasPlanHtml } = options;
    if (hasUI && hasPlanHtml) return null;
    if (!hasUI && !hasPlanHtml) {
        return "Plan: interactive plan review is unavailable in this session (no UI support and missing built assets). Plans will auto-approve on exit_plan_mode.";
    }
    if (!hasUI) {
        return "Plan: interactive plan review is unavailable in this session (no UI support). Plans will auto-approve on exit_plan_mode.";
    }
    return "Plan: interactive plan review assets are missing. Rebuild the extension to restore the browser UI. Plans will auto-approve on exit_plan_mode.";
}

function safeNotify(
    ctx: ExtensionContext,
    message: string,
    type: "info" | "warning" | "error" = "info",
    origin?: PiSessionIdentity,
): void {
    try {
        ctx.ui.notify(message, type);
    } catch (err) {
        if (notifyCurrentPiSession(message, type, origin)) return;
        console.error(
            `Plan notification failed: ${err instanceof Error ? err.message : String(err)}`,
        );
    }
}

function reportBackgroundError(
    ctx: ExtensionContext,
    message: string,
    err: unknown,
    origin?: PiSessionIdentity,
): void {
    const detail = getStartupErrorMessage(err);
    console.error(`${message}: ${detail}`);
    safeNotify(ctx, `${message}: ${detail}`, "error", origin);
}

function excerptText(text: string, maxChars = 1000): string {
    const trimmed = text.trim();
    if (trimmed.length <= maxChars) return trimmed;
    return `${trimmed.slice(0, maxChars).trimEnd()}...`;
}

function blockquote(text: string): string {
    return text
        .split("\n")
        .map((line) => `> ${line}`)
        .join("\n");
}

function anchorMessageFeedback(
    feedback: string,
    originalMessage: string,
): string {
    return `This feedback applies to the earlier assistant response excerpted below:

${blockquote(excerptText(originalMessage))}

User feedback:
${feedback}`;
}

function shouldAnchorLastMessageFeedback(
    ctx: ExtensionContext,
    entryId: string,
    origin: PiSessionIdentity,
): boolean {
    if (isCurrentPiSessionDifferentFrom(origin)) return true;
    try {
        return hasSessionMovedPastEntry(ctx, entryId);
    } catch {
        return true;
    }
}

function reportCurrentSessionSendFailure(
    errorMessage: string,
    err: unknown,
    origin: PiSessionIdentity,
): void {
    const detail = getStartupErrorMessage(err);
    console.error(`${errorMessage}: ${detail}`);
    notifyCurrentPiSession(`${errorMessage}: ${detail}`, "error", origin);
}

function trySendUserMessageToDifferentCurrentSession(
    content: Parameters<ExtensionAPI["sendUserMessage"]>[0],
    options: Parameters<ExtensionAPI["sendUserMessage"]>[1],
    errorMessage: string,
    origin: PiSessionIdentity,
): boolean {
    const result = sendUserMessageToCurrentPiSession(
        withCurrentPiSessionFallbackHeader(content),
        options,
        origin,
    );
    if (result.ok) return true;
    if (result.reason === "send-failed") {
        reportCurrentSessionSendFailure(errorMessage, result.error, origin);
        return true;
    }
    return false;
}

function sendUserMessageWithCurrentSessionFallback(
    pi: ExtensionAPI,
    content: Parameters<ExtensionAPI["sendUserMessage"]>[0],
    options: Parameters<ExtensionAPI["sendUserMessage"]>[1],
    errorMessage: string,
    origin: PiSessionIdentity,
): void {
    if (
        trySendUserMessageToDifferentCurrentSession(
            content,
            options,
            errorMessage,
            origin,
        )
    )
        return;

    try {
        pi.sendUserMessage(content, options);
        return;
    } catch (err) {
        if (
            trySendUserMessageToDifferentCurrentSession(
                content,
                options,
                errorMessage,
                origin,
            )
        )
            return;
        throw err;
    }
}

export default function plan(pi: ExtensionAPI): void {
    const currentPiSession = registerCurrentPiSession(pi);
    let phase: Phase = "idle";
    void registerPlanEventListeners(pi);
    let lastSubmittedPath: string | null = null;
    let checklistItems: ChecklistItem[] = [];
    let savedState: SavedPhaseState | null = null;
    let planConfig = {};
    let justApprovedPlan = false;
    let compactApprovedPlanContext: CompactApprovedPlanContext | null = null;
    let activeContext: ExtensionContext | null = null;

    pi.on("session_start", (_event, ctx) => {
        currentPiSession.update(ctx);
        activeContext = ctx;
    });

    pi.on("session_shutdown", () => {
        currentPiSession.clear();
        activeContext = null;
    });

    // ── Flags ────────────────────────────────────────────────────────────

    pi.registerFlag("plan", {
        description: "Start in plan mode (restricted exploration and planning)",
        type: "boolean",
        default: false,
    });

    // ── Helpers ──────────────────────────────────────────────────────────

    function getPhaseProfile():
        | ReturnType<typeof resolvePhaseProfile>
        | undefined {
        if (phase === "planning" || phase === "executing") {
            return resolvePhaseProfile(planConfig, phase);
        }
        return undefined;
    }

    function updateStatus(ctx: ExtensionContext): void {
        const profile = getPhaseProfile();
        if (phase === "executing" && checklistItems.length > 0) {
            const completed = checklistItems.filter((t) => t.completed).length;
            ctx.ui.setStatus(
                "plan",
                ctx.ui.theme.fg(
                    "accent",
                    `📋 ${completed}/${checklistItems.length}`,
                ),
            );
        } else if (phase === "planning" && profile?.statusLabel) {
            ctx.ui.setStatus(
                "plan",
                ctx.ui.theme.fg("warning", profile.statusLabel),
            );
        } else if (phase === "executing" && profile?.statusLabel) {
            ctx.ui.setStatus(
                "plan",
                ctx.ui.theme.fg("accent", profile.statusLabel),
            );
        } else {
            ctx.ui.setStatus("plan", undefined);
        }
    }

    function updateWidget(ctx: ExtensionContext): void {
        if (phase === "executing" && checklistItems.length > 0) {
            const lines = checklistItems.map((item) => {
                if (item.completed) {
                    return (
                        ctx.ui.theme.fg("success", "☑ ") +
                        ctx.ui.theme.fg(
                            "muted",
                            ctx.ui.theme.strikethrough(item.text),
                        )
                    );
                }
                return `${ctx.ui.theme.fg("muted", "☐ ")}${item.text}`;
            });
            ctx.ui.setWidget("plan-progress", lines);
        } else {
            ctx.ui.setWidget("plan-progress", undefined);
        }
    }

    function captureSavedState(ctx: ExtensionContext): void {
        savedState = {
            activeTools: pi.getActiveTools(),
            model: ctx.model
                ? { provider: ctx.model.provider, id: ctx.model.id }
                : undefined,
            thinkingLevel: pi.getThinkingLevel(),
        };
    }

    function persistState(): void {
        pi.appendEntry("plan", {
            phase,
            lastSubmittedPath,
            savedState,
            compactApprovedPlanContext,
        });
    }

    function getLatestSessionEntryId(
        ctx: ExtensionContext,
    ): string | undefined {
        const entries = ctx.sessionManager.getEntries() as { id?: string }[];
        return [...entries].reverse().find((entry) => entry.id)?.id;
    }

    function enableCompactApprovedPlanContext(
        ctx: ExtensionContext,
        planText: string,
        planFilePath: string,
    ): void {
        compactApprovedPlanContext = {
            planText,
            planFilePath,
            approvalEntryId: getLatestSessionEntryId(ctx),
        };
    }

    function compactApprovedPlanMessage(context: CompactApprovedPlanContext) {
        return {
            customType: "plan-compact-context",
            role: "user",
            content: [
                {
                    type: "text",
                    text: `[PLAN - APPROVED COMPACT CONTEXT]\nThe planning conversation has been compacted. Use the approved plan below as the prior context for execution.\n\nPlan file: ${context.planFilePath}\n\n${context.planText}`,
                },
            ],
        };
    }

    function messageKey(value: unknown): string | null {
        try {
            return JSON.stringify(value);
        } catch {
            return null;
        }
    }

    function isRecord(value: unknown): value is Record<string, unknown> {
        return typeof value === "object" && value !== null;
    }

    function getContentItems(message: Record<string, unknown>): unknown[] {
        return Array.isArray(message.content) ? message.content : [];
    }

    function isToolProtocolItem(item: unknown): boolean {
        if (!isRecord(item)) return false;
        const type = item.type;
        return (
            type === "function_call" ||
            type === "function_call_output" ||
            type === "tool_use" ||
            type === "tool_result" ||
            type === "toolCall" ||
            "tool_use_id" in item ||
            "tool_call_id" in item ||
            ("call_id" in item && ("output" in item || "result" in item))
        );
    }

    function isToolProtocolMessage(message: unknown): boolean {
        if (!isRecord(message)) return false;
        return (
            message.role === "tool" ||
            message.role === "toolResult" ||
            message.type === "function_call_output" ||
            "tool_calls" in message ||
            "function_call" in message ||
            "tool_call_id" in message ||
            getContentItems(message).some(isToolProtocolItem)
        );
    }

    function stripToolProtocol(value: unknown): unknown {
        if (Array.isArray(value)) {
            return value
                .filter(
                    (item) =>
                        !isToolProtocolItem(item) &&
                        !isToolProtocolMessage(item),
                )
                .map(stripToolProtocol);
        }

        if (!isRecord(value)) return value;
        if (isToolProtocolMessage(value) || isToolProtocolItem(value)) {
            return undefined;
        }

        let changed = false;
        const next: Record<string, unknown> = { ...value };
        for (const [key, child] of Object.entries(value)) {
            if (key !== "input" && key !== "messages" && key !== "content") {
                continue;
            }
            const stripped = stripToolProtocol(child);
            if (stripped !== child) {
                changed = true;
                if (stripped === undefined) delete next[key];
                else next[key] = stripped;
            }
        }
        return changed ? next : value;
    }

    function getPostApprovalContextMessages(messages: unknown[]): unknown[] {
        const context = compactApprovedPlanContext;
        if (!context?.approvalEntryId || !activeContext) return [];

        const branch = activeContext.sessionManager.getBranch() as {
            id?: string;
            type?: string;
            message?: unknown;
        }[];
        const boundaryIndex = branch.findIndex(
            (entry) => entry.id === context.approvalEntryId,
        );
        if (boundaryIndex === -1) return [];

        // Compacting replaces the pre-approval conversation with a synthetic
        // approved-plan message. Tool protocol messages after the boundary can
        // reference tool calls that were removed by that replacement, which
        // causes providers such as Codex to reject the request. Keep only
        // normal chat messages from after approval.
        const postApprovalMessages = branch
            .slice(boundaryIndex + 1)
            .filter((entry) => entry.type === "message" && entry.message)
            .map((entry) => entry.message)
            .filter((message) => !isToolProtocolMessage(message));
        const postApprovalObjects = new Set(postApprovalMessages);
        const postApprovalKeys = new Set(
            postApprovalMessages
                .map((message) => messageKey(message))
                .filter((key): key is string => key !== null),
        );

        return messages.filter((message) => {
            if (isToolProtocolMessage(message)) return false;
            if (postApprovalObjects.has(message)) return true;
            const key = messageKey(message);
            return key !== null && postApprovalKeys.has(key);
        });
    }

    async function applyModelRef(
        ref: { provider: string; id: string },
        ctx: ExtensionContext,
        reason: string,
    ): Promise<void> {
        const model = ctx.modelRegistry.find(ref.provider, ref.id);
        if (!model) {
            ctx.ui.notify(
                `Plan: ${reason} model ${ref.provider}/${ref.id} not found.`,
                "warning",
            );
            return;
        }

        const success = await pi.setModel(model);
        if (!success) {
            ctx.ui.notify(
                `Plan: no API key for ${ref.provider}/${ref.id}.`,
                "warning",
            );
        }
    }

    async function restoreSavedState(ctx: ExtensionContext): Promise<void> {
        if (!savedState) return;

        pi.setActiveTools(stripPlanningOnlyTools(savedState.activeTools));
        if (savedState.model) {
            await applyModelRef(savedState.model, ctx, "restore");
        }
        pi.setThinkingLevel(savedState.thinkingLevel);
    }

    async function applyPhaseConfig(
        ctx: ExtensionContext,
        opts: { restoreSavedState?: boolean } = {},
    ): Promise<void> {
        const profile = getPhaseProfile();
        if (opts.restoreSavedState !== false && savedState) {
            await restoreSavedState(ctx);
        }

        if (phase === "planning" || phase === "executing") {
            const baseTools = stripPlanningOnlyTools(
                savedState?.activeTools ?? pi.getActiveTools(),
            );
            const toolSet = new Set(baseTools);
            for (const tool of profile?.activeTools ?? []) toolSet.add(tool);
            pi.setActiveTools(getToolsForPhase([...toolSet], phase));
        }

        if (profile?.model) {
            await applyModelRef(profile.model, ctx, phase);
        }

        if (profile?.thinking) {
            pi.setThinkingLevel(profile.thinking);
        }

        updateStatus(ctx);
        updateWidget(ctx);
    }

    async function enterPlanning(ctx: ExtensionContext): Promise<void> {
        phase = "planning";
        checklistItems = [];
        captureSavedState(ctx);
        await applyPhaseConfig(ctx, { restoreSavedState: false });
        persistState();
        ctx.ui.notify("Plan: planning mode enabled.");
        const warning = getPlanReviewAvailabilityWarning({
            hasUI: ctx.hasUI,
            hasPlanHtml: hasPlanBrowserHtml(),
        });
        if (warning) {
            ctx.ui.notify(warning, "warning");
        }
    }

    async function exitToIdle(ctx: ExtensionContext): Promise<void> {
        phase = "idle";
        checklistItems = [];
        lastSubmittedPath = null;
        compactApprovedPlanContext = null;

        await restoreSavedState(ctx);
        savedState = null;
        updateStatus(ctx);
        updateWidget(ctx);
        persistState();
        ctx.ui.notify("Plan: disabled. Full access restored.");
    }

    async function togglePlanMode(ctx: ExtensionContext): Promise<void> {
        if (phase === "idle") {
            await enterPlanning(ctx);
        } else {
            await exitToIdle(ctx);
        }
    }

    // ── Commands & Shortcuts ─────────────────────────────────────────────

    pi.registerCommand("plan", {
        description: "Toggle plan planning mode",
        handler: async (_args, ctx) => {
            await togglePlanMode(ctx);
        },
    });

    pi.registerCommand("plan-status", {
        description: "Show plan status",
        handler: async (_args, ctx) => {
            const parts = [`Phase: ${phase}`];
            if (lastSubmittedPath) {
                parts.push(`Plan file: ${lastSubmittedPath}`);
            }
            if (checklistItems.length > 0) {
                const done = checklistItems.filter((t) => t.completed).length;
                parts.push(`Progress: ${done}/${checklistItems.length}`);
            }
            ctx.ui.notify(parts.join("\n"), "info");
        },
    });

    pi.registerCommand("plan-review", {
        description:
            "Open interactive code review for current Git changes or a PR URL",
        handler: async (args, ctx) => {
            if (!hasReviewBrowserHtml()) {
                ctx.ui.notify(
                    "Code review UI not available. Run 'bun run build' in the pi-extension directory.",
                    "error",
                );
                return;
            }

            currentPiSession.update(ctx);
            const origin = getPiSessionIdentity(ctx);

            try {
                const reviewArgs = parseReviewArgs(args ?? "");
                const isPRReview = reviewArgs.prUrl !== undefined;
                const session = await startCodeReviewBrowserSession(ctx, {
                    prUrl: reviewArgs.prUrl,
                    vcsType: reviewArgs.vcsType,
                    useLocal: reviewArgs.useLocal,
                });
                ctx.ui.notify(
                    "Code review opened. You can keep chatting while it runs.",
                    "info",
                );
                void session
                    .waitForDecision()
                    .then((result) => {
                        try {
                            if (result.exit) {
                                safeNotify(
                                    ctx,
                                    "Code review session closed.",
                                    "info",
                                    origin,
                                );
                                return;
                            }
                            if (result.approved) {
                                sendUserMessageWithCurrentSessionFallback(
                                    pi,
                                    getReviewApprovedPrompt("pi", loadConfig()),
                                    { deliverAs: "followUp" },
                                    "Plan code review feedback could not be sent",
                                    origin,
                                );
                                return;
                            }
                            if (!result.feedback) {
                                safeNotify(
                                    ctx,
                                    "Code review closed (no feedback).",
                                    "info",
                                    origin,
                                );
                                return;
                            }
                            if (isPRReview) {
                                // Platform PR actions (approve/comment) return approved:false with a
                                // status message — don't tell the agent to "address" a platform action.
                                sendUserMessageWithCurrentSessionFallback(
                                    pi,
                                    result.feedback,
                                    { deliverAs: "followUp" },
                                    "Plan code review feedback could not be sent",
                                    origin,
                                );
                                return;
                            }
                            sendUserMessageWithCurrentSessionFallback(
                                pi,
                                `${result.feedback}${getReviewDeniedSuffix("pi", loadConfig())}`,
                                { deliverAs: "followUp" },
                                "Plan code review feedback could not be sent",
                                origin,
                            );
                        } catch (err) {
                            reportBackgroundError(
                                ctx,
                                "Plan code review feedback could not be sent",
                                err,
                                origin,
                            );
                        }
                    })
                    .catch((err) => {
                        reportBackgroundError(
                            ctx,
                            "Plan code review session failed",
                            err,
                            origin,
                        );
                    });
            } catch (err) {
                ctx.ui.notify(
                    `Failed to start code review UI: ${getStartupErrorMessage(err)}`,
                    "error",
                );
            }
        },
    });

    pi.registerCommand("plan-annotate", {
        description: "Open markdown file or folder in annotation UI",
        handler: async (args, ctx) => {
            // #570: split --gate / --json from the path. --json is silently
            // accepted (Pi writes back via sendUserMessage, not stdout).
            // `rawFilePath` keeps any leading `@` for the literal-@ fallback
            // (scoped-package-style names).
            const {
                filePath,
                rawFilePath,
                gate,
                renderHtml: renderHtmlFlag,
            } = parseAnnotateArgs(args ?? "");
            if (!filePath) {
                ctx.ui.notify(
                    "Usage: /plan-annotate <file.md | file.html | https://... | folder/> [--gate] [--json]",
                    "error",
                );
                return;
            }
            if (!hasPlanBrowserHtml()) {
                ctx.ui.notify(
                    "Annotation UI not available. Run 'bun run build' in the pi-extension directory.",
                    "error",
                );
                return;
            }

            let markdown: string;
            let rawHtml: string | undefined;
            let absolutePath: string;
            let folderPath: string | undefined;
            let mode: "annotate" | "annotate-folder" | undefined;
            let sourceInfo: string | undefined;
            let sourceConverted = false;
            let isFolder = false;

            // --- URL annotation ---
            const isUrl = /^https?:\/\//i.test(filePath);

            if (isUrl) {
                const useJina = resolveUseJina(false, loadConfig());
                ctx.ui.notify(
                    `Fetching: ${filePath}${useJina ? " (via Jina Reader)" : " (via fetch+Turndown)"}...`,
                    "info",
                );
                try {
                    const result = await urlToMarkdown(filePath, { useJina });
                    markdown = result.markdown;
                    sourceConverted = isConvertedSource(result.source);
                } catch (err) {
                    ctx.ui.notify(
                        `Failed to fetch URL: ${err instanceof Error ? err.message : String(err)}`,
                        "error",
                    );
                    return;
                }
                absolutePath = filePath;
                sourceInfo = filePath;
            } else {
                // Pick the interpretation of the user input that actually exists:
                // stripped form first (reference-mode primary), literal as fallback
                // for scoped-package-style names. Falls back to the stripped form
                // for the error message if neither exists.
                const resolvedCandidate = resolveAtReference(
                    rawFilePath,
                    (c) => {
                        const abs = resolveUserPath(c, ctx.cwd);
                        return existsSync(abs);
                    },
                );
                if (resolvedCandidate === null) {
                    absolutePath = resolveUserPath(filePath, ctx.cwd);
                    ctx.ui.notify(`File not found: ${absolutePath}`, "error");
                    return;
                }
                absolutePath = resolveUserPath(resolvedCandidate, ctx.cwd);

                try {
                    isFolder = statSync(absolutePath).isDirectory();
                } catch {
                    ctx.ui.notify(`Cannot access: ${absolutePath}`, "error");
                    return;
                }

                if (isFolder) {
                    if (
                        !hasMarkdownFiles(
                            absolutePath,
                            FILE_BROWSER_EXCLUDED,
                            /\.(mdx?|html?)$/i,
                        )
                    ) {
                        ctx.ui.notify(
                            `No markdown or HTML files found in ${absolutePath}`,
                            "error",
                        );
                        return;
                    }
                    markdown = "";
                    folderPath = absolutePath;
                    mode = "annotate-folder";
                    ctx.ui.notify(
                        `Opening annotation UI for folder ${filePath}...`,
                        "info",
                    );
                } else if (/\.html?$/i.test(absolutePath)) {
                    // HTML file annotation — convert to markdown via Turndown
                    const fileSize = statSync(absolutePath).size;
                    if (fileSize > 10 * 1024 * 1024) {
                        ctx.ui.notify(
                            `File too large (${Math.round(fileSize / 1024 / 1024)}MB, max 10MB)`,
                            "error",
                        );
                        return;
                    }
                    const html = readFileSync(absolutePath, "utf-8");
                    if (renderHtmlFlag) {
                        rawHtml = html;
                        markdown = "";
                    } else {
                        markdown = htmlToMarkdown(html);
                        sourceConverted = true;
                    }
                    sourceInfo = basename(absolutePath);
                    ctx.ui.notify(
                        `Opening annotation UI for ${filePath}...`,
                        "info",
                    );
                } else {
                    markdown = readFileSync(absolutePath, "utf-8");
                    ctx.ui.notify(
                        `Opening annotation UI for ${filePath}...`,
                        "info",
                    );
                }
            }

            currentPiSession.update(ctx);
            const origin = getPiSessionIdentity(ctx);

            try {
                const session = await startMarkdownAnnotationSession(
                    ctx,
                    absolutePath,
                    markdown,
                    mode ?? "annotate",
                    folderPath,
                    sourceInfo,
                    sourceConverted,
                    gate,
                    rawHtml,
                    renderHtmlFlag,
                );
                ctx.ui.notify(
                    "Annotation opened. You can keep chatting while it runs.",
                    "info",
                );
                void session
                    .waitForDecision()
                    .then((result) => {
                        try {
                            if (result.exit) {
                                safeNotify(
                                    ctx,
                                    "Annotation session closed.",
                                    "info",
                                    origin,
                                );
                                return;
                            }
                            if (result.approved) {
                                safeNotify(
                                    ctx,
                                    "Annotation approved.",
                                    "info",
                                    origin,
                                );
                                return;
                            }
                            if (!result.feedback) {
                                safeNotify(
                                    ctx,
                                    "Annotation closed (no feedback).",
                                    "info",
                                    origin,
                                );
                                return;
                            }
                            sendUserMessageWithCurrentSessionFallback(
                                pi,
                                getAnnotateFileFeedbackPrompt(
                                    "pi",
                                    loadConfig(),
                                    {
                                        fileHeader: isFolder
                                            ? "Folder"
                                            : "File",
                                        filePath: absolutePath,
                                        feedback: result.feedback,
                                    },
                                ),
                                { deliverAs: "followUp" },
                                "Plan annotation feedback could not be sent",
                                origin,
                            );
                        } catch (err) {
                            reportBackgroundError(
                                ctx,
                                "Plan annotation feedback could not be sent",
                                err,
                                origin,
                            );
                        }
                    })
                    .catch((err) => {
                        reportBackgroundError(
                            ctx,
                            "Plan annotation session failed",
                            err,
                            origin,
                        );
                    });
            } catch (err) {
                ctx.ui.notify(
                    `Failed to start annotation UI: ${getStartupErrorMessage(err)}`,
                    "error",
                );
            }
        },
    });

    pi.registerCommand("plan-last", {
        description: "Annotate the last assistant message",
        handler: async (args, ctx) => {
            // #570: support --gate on /plan-last for Stop-hook review gate.
            const { gate } = parseAnnotateArgs(args ?? "");

            if (!hasPlanBrowserHtml()) {
                ctx.ui.notify(
                    "Annotation UI not available. Run 'bun run build' in the pi-extension directory.",
                    "error",
                );
                return;
            }

            currentPiSession.update(ctx);
            const origin = getPiSessionIdentity(ctx);

            const snapshot = getLastAssistantMessageSnapshot(ctx);
            if (!snapshot) {
                ctx.ui.notify(
                    "No assistant message found in session.",
                    "error",
                );
                return;
            }

            ctx.ui.notify("Opening annotation UI for last message...", "info");

            try {
                const session = await startLastMessageAnnotationSession(
                    ctx,
                    snapshot.text,
                    gate,
                );
                ctx.ui.notify(
                    "Last-message annotation opened. You can keep chatting while it runs.",
                    "info",
                );
                void session
                    .waitForDecision()
                    .then((result) => {
                        try {
                            if (result.exit) {
                                safeNotify(
                                    ctx,
                                    "Annotation session closed.",
                                    "info",
                                    origin,
                                );
                                return;
                            }
                            if (result.approved) {
                                safeNotify(
                                    ctx,
                                    "Message approved.",
                                    "info",
                                    origin,
                                );
                                return;
                            }
                            if (!result.feedback) {
                                safeNotify(
                                    ctx,
                                    "Annotation closed (no feedback).",
                                    "info",
                                    origin,
                                );
                                return;
                            }
                            const feedback = shouldAnchorLastMessageFeedback(
                                ctx,
                                snapshot.entryId,
                                origin,
                            )
                                ? anchorMessageFeedback(
                                      result.feedback,
                                      snapshot.text,
                                  )
                                : result.feedback;
                            sendUserMessageWithCurrentSessionFallback(
                                pi,
                                getAnnotateMessageFeedbackPrompt(
                                    "pi",
                                    loadConfig(),
                                    {
                                        feedback,
                                    },
                                ),
                                { deliverAs: "followUp" },
                                "Plan message annotation feedback could not be sent",
                                origin,
                            );
                        } catch (err) {
                            reportBackgroundError(
                                ctx,
                                "Plan message annotation feedback could not be sent",
                                err,
                                origin,
                            );
                        }
                    })
                    .catch((err) => {
                        reportBackgroundError(
                            ctx,
                            "Plan message annotation session failed",
                            err,
                            origin,
                        );
                    });
            } catch (err) {
                ctx.ui.notify(
                    `Failed to start annotation UI: ${getStartupErrorMessage(err)}`,
                    "error",
                );
            }
        },
    });

    pi.registerCommand("plan-archive", {
        description: "Browse saved plan decisions",
        handler: async (_args, ctx) => {
            if (!hasPlanBrowserHtml()) {
                ctx.ui.notify(
                    "Archive UI not available. Run 'bun run build' in the pi-extension directory.",
                    "error",
                );
                return;
            }

            ctx.ui.notify("Opening plan archive...", "info");

            try {
                await openArchiveBrowserAction(ctx);
                ctx.ui.notify("Archive browser closed.", "info");
            } catch (err) {
                ctx.ui.notify(
                    `Failed to start archive: ${getStartupErrorMessage(err)}`,
                    "error",
                );
            }
        },
    });

    // ── plan_ask_question Tool ───────────────────────────────────

    pi.registerTool({
        name: PLAN_ASK_QUESTION_TOOL,
        label: "Ask Plan Question",
        description:
            "Ask the user a planning clarification question with a finite list of answer choices. " +
            "Use this only while Plan planning mode is active when user-only clarification is required.",
        parameters: Type.Object({
            question: Type.String({
                description: "The clarification question to ask the user.",
            }),
            answers: Type.Array(Type.String(), {
                description:
                    "Finite answer choices to show in the interactive selection list. Include an 'Other / custom answer' choice when the proposed answers may not fit.",
            }),
        }) as any,

        async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
            if (phase !== "planning") {
                return {
                    content: [
                        {
                            type: "text",
                            text: "Error: plan_ask_question is only available while planning.",
                        },
                    ],
                    details: {
                        question: params.question,
                        answers: params.answers ?? [],
                        answer: null,
                        ok: false,
                    } satisfies PlanAskQuestionDetails,
                };
            }

            const question = String(params.question ?? "").trim();
            const answers = Array.isArray(params.answers)
                ? params.answers
                      .map((answer) => String(answer).trim())
                      .filter((answer) => answer.length > 0)
                : [];

            if (!question) {
                return {
                    content: [
                        {
                            type: "text",
                            text: "Error: question must be a non-empty string.",
                        },
                    ],
                    details: {
                        question,
                        answers,
                        answer: null,
                        ok: false,
                    } satisfies PlanAskQuestionDetails,
                };
            }

            if (answers.length === 0) {
                return {
                    content: [
                        {
                            type: "text",
                            text: "Error: answers must contain at least one non-empty answer choice.",
                        },
                    ],
                    details: {
                        question,
                        answers,
                        answer: null,
                        ok: false,
                    } satisfies PlanAskQuestionDetails,
                };
            }

            if (!ctx.hasUI) {
                return {
                    content: [
                        {
                            type: "text",
                            text: "Error: interactive question UI is not available in this session.",
                        },
                    ],
                    details: {
                        question,
                        answers,
                        answer: null,
                        ok: false,
                    } satisfies PlanAskQuestionDetails,
                };
            }

            const items: SelectItem[] = answers.map((answer, index) => ({
                value: String(index),
                label: answer,
            }));

            const selectedIndex = await ctx.ui.custom<string | null>(
                (tui, theme, _kb, done) => {
                    const container = new Container();
                    container.addChild(
                        new DynamicBorder((s: string) => theme.fg("accent", s)),
                    );
                    container.addChild(
                        new Text(
                            theme.fg("accent", theme.bold(question)),
                            1,
                            0,
                        ),
                    );

                    const selectList = new SelectList(
                        items,
                        Math.min(items.length, 10),
                        {
                            selectedPrefix: (t) => theme.fg("accent", t),
                            selectedText: (t) => theme.fg("accent", t),
                            description: (t) => theme.fg("muted", t),
                            scrollInfo: (t) => theme.fg("dim", t),
                            noMatch: (t) => theme.fg("warning", t),
                        },
                    );
                    selectList.onSelect = (item) => done(item.value);
                    selectList.onCancel = () => done(null);
                    container.addChild(selectList);

                    container.addChild(
                        new Text(
                            theme.fg(
                                "dim",
                                "↑↓ navigate • enter select • esc cancel",
                            ),
                            1,
                            0,
                        ),
                    );
                    container.addChild(
                        new DynamicBorder((s: string) => theme.fg("accent", s)),
                    );

                    return {
                        render: (width) => container.render(width),
                        invalidate: () => container.invalidate(),
                        handleInput: (data) => {
                            selectList.handleInput(data);
                            tui.requestRender();
                        },
                    };
                },
            );

            if (selectedIndex === null || selectedIndex === undefined) {
                return {
                    content: [
                        {
                            type: "text",
                            text: "User cancelled the question selection.",
                        },
                    ],
                    details: {
                        question,
                        answers,
                        answer: null,
                        cancelled: true,
                        ok: true,
                    } satisfies PlanAskQuestionDetails,
                };
            }

            const selectedAnswer = answers[Number(selectedIndex)] ?? null;
            return {
                content: [
                    {
                        type: "text",
                        text: selectedAnswer
                            ? `User selected: ${selectedAnswer}`
                            : "User selection could not be resolved.",
                    },
                ],
                details: {
                    question,
                    answers,
                    answer: selectedAnswer,
                    ok: selectedAnswer !== null,
                } satisfies PlanAskQuestionDetails,
            };
        },
    });

    // ── plan_submit_plan Tool ────────────────────────────────────

    pi.registerTool({
        name: PLAN_SUBMIT_TOOL,
        label: "Submit Plan",
        description:
            "Submit your Plan plan for user review. " +
            "Call this only while Plan planning mode is active, after writing your plan as a markdown file anywhere inside the working directory. " +
            "Pass the path to the plan file (e.g. remove-vscode-integration.md or plans/auth-flow.md). " +
            "The user will review the plan in a visual browser UI and can approve, deny with feedback, or annotate it. " +
            "If denied, edit the same file in place, then call this again with the same path.",
        parameters: Type.Object({
            filePath: Type.String({
                description:
                    "Path to the markdown plan file, relative to the working directory. Must end in .md or .mdx and resolve inside cwd.",
            }),
        }) as any,

        async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
            // Guard: must be in planning phase
            if (phase !== "planning") {
                return {
                    content: [
                        {
                            type: "text",
                            text: "Error: Not in plan mode. Use /plan to enter planning mode first.",
                        },
                    ],
                    details: { approved: false },
                };
            }

            const inputPath = (
                params as { filePath?: string }
            )?.filePath?.trim();
            if (!inputPath) {
                return {
                    content: [
                        {
                            type: "text",
                            text: `Error: ${PLAN_SUBMIT_TOOL} requires a filePath argument pointing to your markdown plan file (e.g. "remove-vscode-integration.md" or "plans/auth-flow.md").`,
                        },
                    ],
                    details: { approved: false },
                };
            }

            if (!isPlanWritePathAllowed(inputPath, ctx.cwd)) {
                return {
                    content: [
                        {
                            type: "text",
                            text: `Error: plan file must be a markdown file (.md or .mdx) inside the working directory. Rejected: ${inputPath}`,
                        },
                    ],
                    details: { approved: false },
                };
            }

            const fullPath = resolve(ctx.cwd, inputPath);

            try {
                if (!statSync(fullPath).isFile()) {
                    return {
                        content: [
                            {
                                type: "text",
                                text: `Error: ${inputPath} is not a regular file. Write your plan to a markdown file first, then call ${PLAN_SUBMIT_TOOL} with its path.`,
                            },
                        ],
                        details: { approved: false },
                    };
                }
            } catch {
                return {
                    content: [
                        {
                            type: "text",
                            text: `Error: ${inputPath} does not exist. Write your plan using the write tool first, then call ${PLAN_SUBMIT_TOOL} again.`,
                        },
                    ],
                    details: { approved: false },
                };
            }

            let planContent: string;
            try {
                planContent = readFileSync(fullPath, "utf-8");
            } catch (err) {
                return {
                    content: [
                        {
                            type: "text",
                            text: `Error: failed to read ${inputPath}: ${err instanceof Error ? err.message : String(err)}`,
                        },
                    ],
                    details: { approved: false },
                };
            }

            if (planContent.trim().length === 0) {
                return {
                    content: [
                        {
                            type: "text",
                            text: `Error: ${inputPath} is empty. Write your plan first, then call ${PLAN_SUBMIT_TOOL} again.`,
                        },
                    ],
                    details: { approved: false },
                };
            }

            lastSubmittedPath = inputPath;
            checklistItems = parseChecklist(planContent);

            // Non-interactive or no HTML: auto-approve
            if (!ctx.hasUI || !hasPlanBrowserHtml()) {
                phase = "executing";
                await applyPhaseConfig(ctx, { restoreSavedState: true });
                pi.appendEntry("plan-execute", { lastSubmittedPath });
                persistState();
                justApprovedPlan = true;
                return {
                    content: [
                        {
                            type: "text",
                            text: getPlanAutoApprovedPrompt("pi", loadConfig()),
                        },
                    ],
                    details: { approved: true },
                    terminate: true,
                };
            }

            let result: Awaited<ReturnType<typeof openPlanReviewBrowser>>;
            try {
                result = await openPlanReviewBrowser(ctx, planContent);
            } catch (err) {
                const message = `Failed to start plan review UI: ${getStartupErrorMessage(err)}`;
                ctx.ui.notify(message, "error");
                return {
                    content: [{ type: "text", text: message }],
                    details: { approved: false },
                };
            }

            if (result.approved) {
                phase = "executing";
                await applyPhaseConfig(ctx, { restoreSavedState: true });
                pi.appendEntry("plan-execute", { lastSubmittedPath });
                if (result.compactContext) {
                    enableCompactApprovedPlanContext(
                        ctx,
                        planContent,
                        inputPath,
                    );
                }
                persistState();
                justApprovedPlan = true;

                const completionMsg =
                    checklistItems.length > 0
                        ? `After completing each step, call ${PLAN_COMPLETE_STEP_TOOL} with the completed step number so the plan file and progress UI update immediately.`
                        : "";

                if (result.feedback) {
                    return {
                        content: [
                            {
                                type: "text",
                                text: getPlanApprovedWithNotesPrompt(
                                    "pi",
                                    loadConfig(),
                                    {
                                        planFilePath: inputPath,
                                        doneMsg: completionMsg,
                                        feedback: result.feedback,
                                    },
                                ),
                            },
                        ],
                        details: { approved: true, feedback: result.feedback },
                        terminate: true,
                    };
                }

                return {
                    content: [
                        {
                            type: "text",
                            text: getPlanApprovedPrompt("pi", loadConfig(), {
                                planFilePath: inputPath,
                                doneMsg: completionMsg,
                            }),
                        },
                    ],
                    details: { approved: true },
                    terminate: true,
                };
            }

            // Denied
            persistState();
            const feedbackText =
                result.feedback || "Plan rejected. Please revise.";
            return {
                content: [
                    {
                        type: "text",
                        text: getPlanDeniedPrompt("pi", loadConfig(), {
                            toolName: getPlanToolName("pi"),
                            planFileRule: buildPlanFileRule(
                                getPlanToolName("pi"),
                                inputPath,
                            ),
                            feedback: feedbackText,
                        }),
                    },
                ],
                details: { approved: false, feedback: feedbackText },
            };
        },
    });

    // ── plan_complete_step Tool ────────────────────────────────────

    pi.registerTool({
        name: PLAN_COMPLETE_STEP_TOOL,
        label: "Complete Plan Step",
        description:
            "Mark a completed /plan checklist step as done. " +
            "Call this immediately after finishing each implementation step from the approved plan. " +
            "It updates both the plan markdown checkbox and the /plan progress UI.",
        parameters: Type.Object({
            step: Type.Number({
                description:
                    "1-based checklist step number to mark complete, matching the Remaining steps list.",
            }),
        }) as any,

        async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
            if (phase !== "executing") {
                return {
                    content: [
                        {
                            type: "text",
                            text: "Error: plan_complete_step is only available while executing an approved plan.",
                        },
                    ],
                    details: { ok: false },
                };
            }

            if (!lastSubmittedPath) {
                return {
                    content: [
                        {
                            type: "text",
                            text: "Error: no approved plan file is recorded for this execution.",
                        },
                    ],
                    details: { ok: false },
                };
            }

            const step = Number((params as { step?: unknown })?.step);
            if (!Number.isInteger(step) || step < 1) {
                return {
                    content: [
                        {
                            type: "text",
                            text: "Error: step must be a positive integer.",
                        },
                    ],
                    details: { ok: false, step },
                };
            }

            const fullPath = resolve(ctx.cwd, lastSubmittedPath);
            let planContent: string;
            try {
                planContent = readFileSync(fullPath, "utf-8");
            } catch (err) {
                return {
                    content: [
                        {
                            type: "text",
                            text: `Error: failed to read ${lastSubmittedPath}: ${err instanceof Error ? err.message : String(err)}`,
                        },
                    ],
                    details: { ok: false, step },
                };
            }

            const result = markStepComplete(planContent, step);
            if (result.error) {
                return {
                    content: [{ type: "text", text: `Error: ${result.error}` }],
                    details: { ok: false, step },
                };
            }

            if (result.changed) {
                try {
                    writeFileSync(fullPath, result.content, "utf-8");
                } catch (err) {
                    return {
                        content: [
                            {
                                type: "text",
                                text: `Error: failed to update ${lastSubmittedPath}: ${err instanceof Error ? err.message : String(err)}`,
                            },
                        ],
                        details: { ok: false, step },
                    };
                }
            }

            checklistItems = parseChecklist(result.content);
            updateStatus(ctx);
            updateWidget(ctx);
            persistState();

            const itemText = result.item?.text ? `: ${result.item.text}` : "";
            const status = result.changed ? "completed" : "already complete";
            return {
                content: [
                    {
                        type: "text",
                        text: `Step ${step} ${status}${itemText}`,
                    },
                ],
                details: { ok: true, step, changed: result.changed },
            };
        },
    });

    // ── Event Handlers ───────────────────────────────────────────────────

    // Gate writes during planning — only markdown files inside cwd.
    pi.on("tool_call", async (event, ctx) => {
        if (phase !== "planning") return;
        if (event.toolName !== "write" && event.toolName !== "edit") return;

        const inputPath = event.input.path as string;
        if (!isPlanWritePathAllowed(inputPath, ctx.cwd)) {
            const verb = event.toolName === "write" ? "writes" : "edits";
            return {
                block: true,
                reason: `Plan: during planning, ${verb} are limited to markdown files (.md, .mdx) inside the working directory. Blocked: ${inputPath}`,
            };
        }
    });

    // Inject phase-specific context
    pi.on("before_agent_start", async (_event, ctx) => {
        const profile = getPhaseProfile();
        const planRef = lastSubmittedPath ?? "your plan file";

        if (phase === "executing" && lastSubmittedPath) {
            // Re-read from disk each turn to stay current
            const fullPath = resolve(ctx.cwd, lastSubmittedPath);
            try {
                const planContent = readFileSync(fullPath, "utf-8");
                checklistItems = parseChecklist(planContent);
            } catch {
                // File deleted during execution — degrade gracefully
            }
        }

        const todoStats =
            phase === "executing"
                ? formatTodoList(checklistItems)
                : formatTodoList([]);

        let improveContext: string | null = null;
        if (phase === "planning") {
            const hook = readImprovementHook("enterplanmode-improve");
            const pfmEnabled = loadConfig().pfmReminder === true;
            improveContext = composeImproveContext({
                pfmEnabled,
                improvementHookContent: hook?.content ?? null,
            });
        }

        if (profile?.systemPrompt) {
            const rendered = renderTemplate(
                profile.systemPrompt,
                buildPromptVariables({
                    planFilePath: planRef,
                    phase,
                    todoList: todoStats.todoList,
                    completedCount: todoStats.completedCount,
                    totalCount: todoStats.totalCount,
                    remainingCount: todoStats.remainingCount,
                }),
            );
            if (rendered.unknownVariables.length > 0) {
                ctx.ui.notify(
                    "Plan: unknown template variables in " +
                        phase +
                        " prompt: " +
                        rendered.unknownVariables.join(", "),
                    "warning",
                );
            }

            return {
                systemPrompt:
                    rendered.text +
                    (improveContext ? "\n\n" + improveContext : ""),
            };
        }

        if (phase === "planning") {
            return {
                message: {
                    customType: "plan-context",
                    content:
                        `[PLAN - PLANNING PHASE]
You are in plan mode. You MUST NOT make any changes to the codebase — no edits, no commits, no installs, no destructive commands. During planning you may only write or edit markdown files (.md, .mdx) inside the working directory.

Available tools: read, bash, grep, find, ls, write (markdown only), edit (markdown only), ${PLAN_ASK_QUESTION_TOOL}, ${PLAN_SUBMIT_TOOL}

Do not run destructive bash commands (rm, git push, npm install, etc.) — focus on reading and exploring the codebase. Web fetching (curl, wget) is fine.

## Iterative Planning Workflow

You are pair-planning with the user. Explore the code to build context, then write your findings into a markdown plan file as you go. The plan starts as a rough skeleton and gradually becomes the final plan.

### Picking a plan file

Choose a short descriptive kebab-case filename for your plan, based on the task (for example, \`remove-vscode-integration.md\` or \`auth-flow.md\`). Do not use generic names like \`PLAN.md\`. Put it at the repo root unless the project has an existing plans directory/convention; in that case use \`plans/<short-descriptive-name>.md\`. Reuse the same filename across revisions of the same plan so version history links up.

### The Loop

Repeat this cycle until the plan is complete:

1. **Explore** — Use read, grep, find, ls, and bash to understand the codebase. Actively search for existing functions, utilities, and patterns that can be reused — avoid proposing new code when suitable implementations already exist.
2. **Update the plan file** — After each discovery, immediately capture what you learned in the plan. Don't wait until the end. Use write for the initial draft, then edit for all subsequent updates.
3. **Ask the user** — When you hit an ambiguity or decision you can't resolve from code alone, call ${PLAN_ASK_QUESTION_TOOL} with the question and finite answer choices. Then go back to step 1.

### First Turn

Start by quickly scanning key files to form an initial understanding of the task scope. Then write a skeleton plan (headers and rough notes) and ask the user your first round of questions. Don't explore exhaustively before engaging the user.

### Asking Good Questions

- Never ask what you could find out by reading the code.
- Whenever user-only clarification is needed, use ${PLAN_ASK_QUESTION_TOOL}; do not ask the question as plain chat.
- Keep each ${PLAN_ASK_QUESTION_TOOL} question answerable via finite choices. Include an “Other / custom answer” choice when none of the proposed choices may fit.
- Batch related questions together only when they can be answered by one finite choice list; otherwise ask one focused ${PLAN_ASK_QUESTION_TOOL} question at a time.
- Focus on things only the user can answer: requirements, preferences, tradeoffs, edge-case priorities.
- Scale depth to the task — a vague feature request needs many rounds; a focused bug fix may need one or none.

### Plan File Structure

Your plan file should use markdown with clear sections:
- **Context** — Why this change is being made: the problem, what prompted it, the intended outcome.
- **Approach** — Your recommended approach only, not all alternatives considered.
- **Files to modify** — List the critical file paths that will be changed.
- **Reuse** — Reference existing functions and utilities you found, with their file paths.
- **Steps** — Implementation checklist:
  - [ ] Step 1 description
  - [ ] Step 2 description
- **Verification** — How to test the changes end-to-end (run the code, run tests, manual checks).

Keep the plan concise enough to scan quickly, but detailed enough to execute effectively.

### When to Submit

Your plan is ready when you've addressed all ambiguities and it covers: what to change, which files to modify, what existing code to reuse, and how to verify. Call ${PLAN_SUBMIT_TOOL} with the path to your plan file to submit for review.

### Revising After Feedback

When the user denies a plan with feedback:
1. Read the plan file to see the current plan.
2. Use the edit tool to make targeted changes addressing the feedback — do NOT rewrite the entire file.
3. Call ${PLAN_SUBMIT_TOOL} again with the same filePath to resubmit.

### Ending Your Turn

Your turn should only end by either:
- Calling ${PLAN_ASK_QUESTION_TOOL} to gather more information.
- Calling ${PLAN_SUBMIT_TOOL} when the plan is ready for review.

Do not end your turn without doing one of these two things.` +
                        (improveContext ? "\n\n---\n\n" + improveContext : ""),
                    display: false,
                },
            };
        }

        if (phase === "executing" && checklistItems.length > 0) {
            const remaining = checklistItems.filter((t) => !t.completed);
            if (remaining.length > 0) {
                const todoList = remaining
                    .map((t) => `- [ ] ${t.step}. ${t.text}`)
                    .join("\n");
                return {
                    message: {
                        customType: "plan-context",
                        content: `[PLAN - EXECUTING PLAN]
Full tool access is enabled. Execute the plan from ${planRef}.

Remaining steps:
${todoList}

Execute each step in order. Immediately after completing each step, call ${PLAN_COMPLETE_STEP_TOOL} with that step number so the plan file and progress UI update live.

When all checklist items are complete, /plan will ask whether to remove the plan file. Do not remove the plan file yourself; if the user declines, it will be kept in the filesystem.`,
                        display: false,
                    },
                };
            }
        }
    });

    // Filter stale context when idle and compact approved-plan context during execution.
    pi.on("context", async (event) => {
        if (compactApprovedPlanContext) {
            const postApprovalMessages = getPostApprovalContextMessages(
                event.messages,
            );
            return {
                messages: [
                    compactApprovedPlanMessage(compactApprovedPlanContext),
                    ...postApprovalMessages.filter((m) => {
                        const msg = m as { customType?: string };
                        return msg.customType !== "plan-compact-context";
                    }),
                ],
            };
        }

        if (phase !== "idle") return;

        return {
            messages: event.messages.filter((m) => {
                const msg = m as {
                    customType?: string;
                    role?: string;
                    content?: unknown;
                };
                if (msg.customType === "plan-context") return false;
                if (msg.role !== "user") return true;

                const content = msg.content;
                if (typeof content === "string") {
                    return !content.includes("[PLAN -");
                }
                if (Array.isArray(content)) {
                    return !content.some(
                        (c) =>
                            c.type === "text" &&
                            (c as { text?: string }).text?.includes("[PLAN -"),
                    );
                }
                return true;
            }),
        };
    });

    pi.on("before_provider_request", (event) => {
        if (!compactApprovedPlanContext) return;
        // Safety net for provider serializers that may reintroduce tool-result
        // protocol items after the normal context hook. Codex rejects orphaned
        // function_call_output entries when their function_call was compacted.
        return stripToolProtocol(event.payload);
    });

    // Keep execution progress synced from the plan file.
    pi.on("turn_end", async (_event, ctx) => {
        if (phase !== "executing" || !lastSubmittedPath) return;

        try {
            const planContent = readFileSync(
                resolve(ctx.cwd, lastSubmittedPath),
                "utf-8",
            );
            checklistItems = parseChecklist(planContent);
            updateStatus(ctx);
            updateWidget(ctx);
        } catch {
            // File deleted during execution — degrade gracefully.
        }
        persistState();
    });

    // Detect execution completion
    pi.on("agent_end", async (_event, ctx) => {
        if (phase === "executing" && justApprovedPlan) {
            justApprovedPlan = false;
            setTimeout(() => {
                pi.sendUserMessage("Continue with the approved plan.");
            }, 0);
            return;
        }

        if (phase !== "executing" || checklistItems.length === 0) return;

        if (checklistItems.every((t) => t.completed)) {
            const completedPlanPath = lastSubmittedPath;
            const completedList = checklistItems
                .map((t) => `- [x] ~~${t.text}~~`)
                .join("\n");
            pi.sendMessage(
                {
                    customType: "plan-complete",
                    content: `**Plan Complete!** ✓\n\n${completedList}`,
                    display: true,
                },
                { triggerTurn: false },
            );

            let cleanupMessage: string | null = null;
            if (completedPlanPath) {
                try {
                    const planFilePath = resolve(ctx.cwd, completedPlanPath);
                    if (!existsSync(planFilePath)) {
                        cleanupMessage = `Plan file was already removed: ${completedPlanPath}`;
                    } else {
                        let removePlanFile = false;
                        try {
                            removePlanFile = await ctx.ui.confirm(
                                "Done!",
                                `Implementation is complete. Remove ${completedPlanPath} from the filesystem?`,
                            );
                        } catch (err) {
                            cleanupMessage = `Plan file kept at ${completedPlanPath}; cleanup confirmation could not be shown: ${err instanceof Error ? err.message : String(err)}`;
                        }

                        if (removePlanFile) {
                            try {
                                unlinkSync(planFilePath);
                                cleanupMessage = `Plan file removed: ${completedPlanPath}`;
                            } catch (err) {
                                if (!existsSync(planFilePath)) {
                                    cleanupMessage = `Plan file was already removed: ${completedPlanPath}`;
                                } else {
                                    cleanupMessage = `Plan file kept at ${completedPlanPath}; failed to remove it: ${err instanceof Error ? err.message : String(err)}`;
                                }
                            }
                        } else if (!cleanupMessage) {
                            cleanupMessage = `Plan file kept: ${completedPlanPath}`;
                        }
                    }
                } catch (err) {
                    cleanupMessage = `Plan file kept at ${completedPlanPath}; cleanup could not complete: ${err instanceof Error ? err.message : String(err)}`;
                }
            }

            if (cleanupMessage) {
                pi.sendMessage(
                    {
                        customType: "plan-complete",
                        content: cleanupMessage,
                        display: true,
                    },
                    { triggerTurn: false },
                );
            }

            phase = "idle";
            checklistItems = [];
            lastSubmittedPath = null;
            compactApprovedPlanContext = null;

            await restoreSavedState(ctx);
            savedState = null;
            updateStatus(ctx);
            updateWidget(ctx);
            persistState();
        }
    });

    // Restore state on session start/resume
    pi.on("session_start", async (_event, ctx) => {
        const loadedConfig = loadPlanConfig(ctx.cwd);
        planConfig = loadedConfig.config;
        for (const warning of loadedConfig.warnings) {
            ctx.ui.notify(`Plan config: ${warning}`, "warning");
        }

        // Check --plan flag
        if (pi.getFlag("plan") === true) {
            phase = "planning";
        }

        // Restore persisted state
        const entries = ctx.sessionManager.getEntries();
        const stateEntry = entries
            .filter(
                (e: { type: string; customType?: string }) =>
                    e.type === "custom" && e.customType === "plan",
            )
            .pop() as { data?: PersistedPlanState } | undefined;

        if (stateEntry?.data) {
            phase = stateEntry.data.phase ?? phase;
            lastSubmittedPath =
                stateEntry.data.lastSubmittedPath ?? lastSubmittedPath;
            savedState = stateEntry.data.savedState ?? savedState;
            compactApprovedPlanContext =
                stateEntry.data.compactApprovedPlanContext ??
                compactApprovedPlanContext;
        }

        // Rebuild execution state from the plan file on disk.
        if (phase === "executing") {
            if (lastSubmittedPath) {
                const fullPath = resolve(ctx.cwd, lastSubmittedPath);
                if (existsSync(fullPath)) {
                    const content = readFileSync(fullPath, "utf-8");
                    checklistItems = parseChecklist(content);
                } else {
                    // Plan file gone — fall back to idle
                    phase = "idle";
                    lastSubmittedPath = null;
                    compactApprovedPlanContext = null;
                }
            } else {
                // No path recorded — can't rebuild, fall back to idle
                phase = "idle";
                compactApprovedPlanContext = null;
            }
        }

        if (phase === "planning") {
            checklistItems = [];
            const warning = getPlanReviewAvailabilityWarning({
                hasUI: ctx.hasUI,
                hasPlanHtml: hasPlanBrowserHtml(),
            });
            if (warning) {
                ctx.ui.notify(warning, "warning");
            }
        }

        if (phase === "idle") {
            if (savedState) {
                await restoreSavedState(ctx);
                savedState = null;
            } else {
                // Strip phase-only tools on fresh sessions where savedState is null.
                // Without this, plan tools can stay in the active tool set
                // even though plan mode hasn't been activated. See #387.
                pi.setActiveTools(stripPlanningOnlyTools(pi.getActiveTools()));
            }
        } else if (phase === "planning" || phase === "executing") {
            await applyPhaseConfig(ctx, { restoreSavedState: true });
        }

        updateStatus(ctx);
        updateWidget(ctx);
        persistState();
    });
}
