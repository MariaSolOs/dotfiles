// @ts-nocheck
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import type {
    ExtensionAPI,
    ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import type { DiffType, VcsSelection } from "./server.js";
import {
    getLastAssistantMessageText,
    getStartupErrorMessage,
    openArchiveBrowserAction,
    openCodeReview,
    openLastMessageAnnotation,
    openMarkdownAnnotation,
    startCodeReviewBrowserSession,
    startLastMessageAnnotationSession,
    startMarkdownAnnotationSession,
    startPlanReviewBrowserSession,
} from "./plan-browser.js";

export const PLAN_REQUEST_CHANNEL = "plan:request" as const;
export const PLAN_REVIEW_RESULT_CHANNEL = "plan:review-result" as const;
export const PLAN_TIMEOUT_MS = 5_000;

export type PlanAction =
    | "plan-review"
    | "review-status"
    | "code-review"
    | "annotate"
    | "annotate-last"
    | "archive";

export interface PlanHandledResponse<T> {
    status: "handled";
    result: T;
}

export interface PlanUnavailableResponse {
    status: "unavailable";
    error?: string;
}

export interface PlanErrorResponse {
    status: "error";
    error: string;
}

export type PlanResponse<T> =
    | PlanHandledResponse<T>
    | PlanUnavailableResponse
    | PlanErrorResponse;

export interface PlanRequestBase<A extends PlanAction, P, R> {
    requestId: string;
    action: A;
    payload: P;
    respond: (response: PlanResponse<R>) => void;
}

export interface PlanPlanReviewPayload {
    planFilePath?: string;
    planContent: string;
    origin?: string;
}

export interface PlanPlanReviewStartResult {
    status: "pending";
    reviewId: string;
}

export interface PlanReviewResultEvent {
    reviewId: string;
    approved: boolean;
    feedback?: string;
    savedPath?: string;
    agentSwitch?: string;
    permissionMode?: string;
}

export interface PlanReviewStatusPayload {
    reviewId: string;
}

export type PlanReviewStatusResult =
    | { status: "pending" }
    | ({ status: "completed" } & PlanReviewResultEvent)
    | { status: "missing" };

export interface PlanCodeReviewPayload {
    diffType?: DiffType;
    defaultBranch?: string;
    vcsType?: VcsSelection;
    useLocal?: boolean;
    cwd?: string;
    prUrl?: string;
}

export interface PlanCodeReviewResult {
    approved: boolean;
    feedback?: string;
    annotations?: unknown[];
    agentSwitch?: string;
}

export interface PlanAnnotatePayload {
    filePath: string;
    markdown?: string;
    mode?: "annotate" | "annotate-folder" | "annotate-last";
    folderPath?: string;
    /** Enable review-gate UX (Approve / Annotate / Close), #570 */
    gate?: boolean;
}

export interface PlanAnnotationResult {
    feedback: string;
    /** True when the reviewer closed the session without providing feedback. */
    exit?: boolean;
    /** True when the reviewer clicked Approve in review-gate mode, #570 */
    approved?: boolean;
}

export interface PlanArchivePayload {
    customPlanPath?: string;
}

export interface PlanArchiveResult {
    opened: boolean;
}

export type PlanRequestMap = {
    "plan-review": PlanRequestBase<
        "plan-review",
        PlanPlanReviewPayload,
        PlanPlanReviewStartResult
    >;
    "review-status": PlanRequestBase<
        "review-status",
        PlanReviewStatusPayload,
        PlanReviewStatusResult
    >;
    "code-review": PlanRequestBase<
        "code-review",
        PlanCodeReviewPayload,
        PlanCodeReviewResult
    >;
    annotate: PlanRequestBase<
        "annotate",
        PlanAnnotatePayload,
        PlanAnnotationResult
    >;
    "annotate-last": PlanRequestBase<
        "annotate-last",
        PlanAnnotatePayload,
        PlanAnnotationResult
    >;
    archive: PlanRequestBase<"archive", PlanArchivePayload, PlanArchiveResult>;
};
export type PlanRequest = PlanRequestMap[PlanAction];
export type PlanResponseMap = {
    "plan-review": PlanResponse<PlanPlanReviewStartResult>;
    "review-status": PlanResponse<PlanReviewStatusResult>;
    "code-review": PlanResponse<PlanCodeReviewResult>;
    annotate: PlanResponse<PlanAnnotationResult>;
    "annotate-last": PlanResponse<PlanAnnotationResult>;
    archive: PlanResponse<PlanArchiveResult>;
};
function isPlanAction(value: unknown): value is PlanAction {
    return (
        value === "plan-review" ||
        value === "review-status" ||
        value === "code-review" ||
        value === "annotate" ||
        value === "annotate-last" ||
        value === "archive"
    );
}

const REVIEW_STATUS_PATH = join(homedir(), ".pi", "plan-review-status.json");

type StoredReviewStatus = Record<string, PlanReviewStatusResult>;

function readStoredReviewStatuses(): StoredReviewStatus {
    try {
        if (!existsSync(REVIEW_STATUS_PATH)) return {};
        const raw = readFileSync(REVIEW_STATUS_PATH, "utf-8");
        const parsed = JSON.parse(raw) as StoredReviewStatus;
        return parsed && typeof parsed === "object" ? parsed : {};
    } catch {
        return {};
    }
}

function writeStoredReviewStatuses(statuses: StoredReviewStatus): void {
    mkdirSync(dirname(REVIEW_STATUS_PATH), { recursive: true });
    writeFileSync(REVIEW_STATUS_PATH, JSON.stringify(statuses, null, 2));
}

function setStoredReviewStatus(
    reviewId: string,
    status: PlanReviewStatusResult,
): void {
    const statuses = readStoredReviewStatuses();
    statuses[reviewId] = status;
    writeStoredReviewStatuses(statuses);
}

function getStoredReviewStatus(reviewId: string): PlanReviewStatusResult {
    return readStoredReviewStatuses()[reviewId] ?? { status: "missing" };
}

function createActiveSessionContext() {
    let currentCtx: ExtensionContext | undefined;

    return {
        set(ctx: ExtensionContext): void {
            currentCtx = ctx;
        },
        clear(): void {
            currentCtx = undefined;
        },
        get(): ExtensionContext | undefined {
            return currentCtx;
        },
    };
}

export function registerPlanEventListeners(pi: ExtensionAPI): void {
    const activeSessionContext = createActiveSessionContext();

    // Plan event requests are handled against the latest active session.
    // The active context is intentionally session-scoped and replaced on each session_start.
    pi.on("session_start", async (_event, ctx) => {
        activeSessionContext.set(ctx);
    });
    pi.events.on(PLAN_REQUEST_CHANNEL, async (data) => {
        const request = data as Partial<PlanRequest> | null;
        const ctx = activeSessionContext.get();

        if (
            !request ||
            typeof request.respond !== "function" ||
            !isPlanAction(request.action)
        ) {
            return;
        }

        try {
            if (request.action === "review-status") {
                const reviewId = request.payload?.reviewId;
                if (typeof reviewId !== "string" || !reviewId.trim()) {
                    request.respond({
                        status: "error",
                        error: "Missing reviewId for review-status request.",
                    });
                    return;
                }
                request.respond({
                    status: "handled",
                    result: getStoredReviewStatus(reviewId),
                });
                return;
            }

            if (!ctx) {
                request.respond({
                    status: "unavailable",
                    error: "Plan context is not ready yet.",
                });
                return;
            }

            switch (request.action) {
                case "plan-review": {
                    const planContent = request.payload?.planContent;
                    if (
                        typeof planContent !== "string" ||
                        !planContent.trim()
                    ) {
                        request.respond({
                            status: "error",
                            error: "Missing planContent for plan-review request.",
                        });
                        return;
                    }
                    const session = await startPlanReviewBrowserSession(
                        ctx,
                        planContent,
                    );
                    setStoredReviewStatus(session.reviewId, {
                        status: "pending",
                    });
                    session.onDecision((result) => {
                        const reviewResult = {
                            reviewId: session.reviewId,
                            approved: result.approved,
                            feedback: result.feedback,
                            savedPath: result.savedPath,
                            agentSwitch: result.agentSwitch,
                            permissionMode: result.permissionMode,
                        } satisfies PlanReviewResultEvent;
                        setStoredReviewStatus(session.reviewId, {
                            status: "completed",
                            ...reviewResult,
                        });
                        pi.events.emit(
                            PLAN_REVIEW_RESULT_CHANNEL,
                            reviewResult,
                        );
                    });
                    request.respond({
                        status: "handled",
                        result: {
                            status: "pending",
                            reviewId: session.reviewId,
                        },
                    });
                    return;
                }
                case "code-review": {
                    const result = await openCodeReview(ctx, {
                        cwd: request.payload?.cwd,
                        defaultBranch: request.payload?.defaultBranch,
                        diffType: request.payload?.diffType,
                        vcsType: request.payload?.vcsType,
                        useLocal: request.payload?.useLocal,
                        prUrl: request.payload?.prUrl,
                    });
                    request.respond({ status: "handled", result });
                    return;
                }
                case "annotate": {
                    const payload = request.payload;
                    if (!payload?.filePath) {
                        request.respond({
                            status: "error",
                            error: "Missing filePath for annotate request.",
                        });
                        return;
                    }
                    const sourceConverted =
                        /\.html?$/i.test(payload.filePath) ||
                        /^https?:\/\//i.test(payload.filePath);
                    const result = await openMarkdownAnnotation(
                        ctx,
                        payload.filePath,
                        payload.markdown ?? "",
                        payload.mode ?? "annotate",
                        payload.folderPath,
                        undefined,
                        sourceConverted,
                        payload.gate,
                    );
                    request.respond({ status: "handled", result });
                    return;
                }
                case "annotate-last": {
                    const payload = request.payload;
                    const lastText = payload?.markdown?.trim()
                        ? payload.markdown
                        : getLastAssistantMessageText(ctx);
                    if (!lastText) {
                        request.respond({
                            status: "unavailable",
                            error: "No assistant message found in session.",
                        });
                        return;
                    }
                    const result = await openLastMessageAnnotation(
                        ctx,
                        lastText,
                        payload?.gate,
                    );
                    request.respond({ status: "handled", result });
                    return;
                }
                case "archive": {
                    const result = await openArchiveBrowserAction(
                        ctx,
                        request.payload?.customPlanPath,
                    );
                    request.respond({ status: "handled", result });
                    return;
                }
            }
        } catch (err) {
            const message = getStartupErrorMessage(err);
            if (/unavailable|not available/i.test(message)) {
                request.respond({ status: "unavailable", error: message });
                return;
            }
            request.respond({ status: "error", error: message });
        }
    });
}

export {
    getLastAssistantMessageText,
    hasPlanBrowserHtml,
    hasReviewBrowserHtml,
    startCodeReviewBrowserSession,
    startLastMessageAnnotationSession,
    startMarkdownAnnotationSession,
    getStartupErrorMessage,
    openArchiveBrowserAction,
    openCodeReview,
    openLastMessageAnnotation,
    openMarkdownAnnotation,
    openPlanReviewBrowser,
    startPlanReviewBrowserSession,
} from "./plan-browser.js";
