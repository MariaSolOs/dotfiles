// @ts-nocheck
import { randomUUID } from "node:crypto";
import { createServer } from "node:http";

import { contentHash, deleteDraft } from "../generated/draft.js";
import {
    generateSlug,
    getPlanVersion,
    getVersionCount,
    listVersions,
    saveToHistory,
} from "../generated/storage.js";
import { createEditorAnnotationHandler } from "./annotations.js";
import { createExternalAnnotationHandler } from "./external-annotations.js";
import {
    handleDraftRequest,
    handleFavicon,
    handleImageRequest,
    handleUploadRequest,
} from "./handlers.js";
import { html, json, parseBody, requestUrl } from "./helpers.js";
import { listenOnPort } from "./network.js";

import {
    loadConfig,
    saveConfig,
    detectGitUser,
    getServerConfig,
} from "../generated/config.js";
import { composeImproveContext } from "../generated/pfm-reminder.js";
import { detectProjectName, getRepoInfo } from "./project.js";
import {
    handleDocRequest,
    handleDocExistsRequest,
    handleFileBrowserRequest,
} from "./reference.js";
import { warmFileListCache } from "../generated/resolve-file.js";

export interface PlanReviewDecision {
    approved: boolean;
    feedback?: string;
    agentSwitch?: string;
    permissionMode?: string;
    compactContext?: boolean;
}

export interface PlanServerResult {
    reviewId: string;
    port: number;
    portSource: "env" | "remote-default" | "random";
    url: string;
    waitForDecision: () => Promise<PlanReviewDecision>;
    onDecision: (
        listener: (result: PlanReviewDecision) => void | Promise<void>,
    ) => () => void;
    stop: () => void;
}

export async function startPlanReviewServer(options: {
    plan: string;
    htmlContent: string;
    origin?: string;
    permissionMode?: string;
    sharingEnabled?: boolean;
    shareBaseUrl?: string;
    pasteApiUrl?: string;
}): Promise<PlanServerResult> {
    // Side-channel pre-warm so /api/doc/exists POSTs land on warm cache.
    void warmFileListCache(process.cwd(), "code");
    const gitUser = detectGitUser();
    const sharingEnabled =
        options.sharingEnabled ?? process.env.PLAN_SHARE !== "disabled";
    const shareBaseUrl =
        (options.shareBaseUrl ?? process.env.PLAN_SHARE_URL) || undefined;
    const pasteApiUrl =
        (options.pasteApiUrl ?? process.env.PLAN_PASTE_URL) || undefined;

    const repoInfo = getRepoInfo();
    const slug = generateSlug(options.plan);
    const project = detectProjectName();
    const historyResult = saveToHistory(project, slug, options.plan);
    const previousPlan =
        historyResult.version > 1
            ? getPlanVersion(project, slug, historyResult.version - 1)
            : null;
    const versionInfo = {
        version: historyResult.version,
        totalVersions: getVersionCount(project, slug),
        project,
    };

    const reviewId = randomUUID();
    let resolveDecision!: (result: PlanReviewDecision) => void;
    const decisionListeners = new Set<
        (result: PlanReviewDecision) => void | Promise<void>
    >();
    let decisionSettled = false;
    const decisionPromise = new Promise<PlanReviewDecision>((r) => {
        resolveDecision = r;
    });
    const publishDecision = (result: PlanReviewDecision): boolean => {
        if (decisionSettled) return false;
        decisionSettled = true;
        resolveDecision(result);
        for (const listener of decisionListeners) {
            Promise.resolve(listener(result)).catch((error) => {
                console.error("[Plan Review] Decision listener failed:", error);
            });
        }
        return true;
    };

    // Drafts are keyed by plan content so browser notes survive reloads/crashes.
    const draftKey = contentHash(options.plan);
    const editorAnnotations = createEditorAnnotationHandler();
    const externalAnnotations = createExternalAnnotationHandler("plan");

    const server = createServer(async (req, res) => {
        const url = requestUrl(req);

        if (url.pathname === "/api/plan/version") {
            const vParam = url.searchParams.get("v");
            if (!vParam) {
                json(res, { error: "Missing v parameter" }, 400);
                return;
            }
            const v = parseInt(vParam, 10);
            if (Number.isNaN(v) || v < 1) {
                json(res, { error: "Invalid version number" }, 400);
                return;
            }
            const content = getPlanVersion(project, slug, v);
            if (content === null) {
                json(res, { error: "Version not found" }, 404);
                return;
            }
            json(res, { plan: content, version: v });
        } else if (url.pathname === "/api/plan/versions") {
            json(res, { project, slug, versions: listVersions(project, slug) });
        } else if (url.pathname === "/api/plan") {
            json(res, {
                plan: options.plan,
                origin: options.origin ?? "pi",
                permissionMode: options.permissionMode,
                previousPlan,
                versionInfo,
                sharingEnabled,
                shareBaseUrl,
                pasteApiUrl,
                repoInfo,
                projectRoot: process.cwd(),
                serverConfig: getServerConfig(gitUser),
            });
        } else if (
            url.pathname === "/api/hooks/status" &&
            req.method === "GET"
        ) {
            const config = loadConfig();
            const pfmEnabled = config.pfmReminder === true;
            const composed = composeImproveContext({ pfmEnabled });
            json(res, {
                pfmReminder: { enabled: pfmEnabled },
                composedLength: composed?.length ?? null,
            });
        } else if (url.pathname === "/api/config" && req.method === "POST") {
            try {
                const body = (await parseBody(req)) as {
                    displayName?: string;
                    diffOptions?: Record<string, unknown>;
                    pfmReminder?: boolean;
                };
                const toSave: Record<string, unknown> = {};
                if (body.displayName !== undefined)
                    toSave.displayName = body.displayName;
                if (body.diffOptions !== undefined)
                    toSave.diffOptions = body.diffOptions;
                if (body.pfmReminder !== undefined)
                    toSave.pfmReminder = body.pfmReminder;
                if (Object.keys(toSave).length > 0)
                    saveConfig(toSave as Parameters<typeof saveConfig>[0]);
                json(res, { ok: true });
            } catch {
                json(res, { error: "Invalid request" }, 400);
            }
        } else if (url.pathname === "/api/image") {
            handleImageRequest(res, url);
        } else if (url.pathname === "/api/upload" && req.method === "POST") {
            await handleUploadRequest(req, res);
        } else if (url.pathname === "/api/draft") {
            await handleDraftRequest(req, res, draftKey);
        } else if (await editorAnnotations.handle(req, res, url)) {
            return;
        } else if (await externalAnnotations.handle(req, res, url)) {
            return;
        } else if (url.pathname === "/api/doc" && req.method === "GET") {
            await handleDocRequest(res, url);
        } else if (
            url.pathname === "/api/doc/exists" &&
            req.method === "POST"
        ) {
            await handleDocExistsRequest(res, req);
        } else if (
            url.pathname === "/api/reference/files" &&
            req.method === "GET"
        ) {
            handleFileBrowserRequest(res, url);
        } else if (url.pathname === "/api/agents" && req.method === "GET") {
            json(res, { agents: [] });
        } else if (url.pathname === "/favicon.svg") {
            handleFavicon(res);
        } else if (
            url.pathname === "/api/save-notes" &&
            req.method === "POST"
        ) {
            json(res, { ok: true, results: {} });
        } else if (url.pathname === "/api/approve" && req.method === "POST") {
            if (decisionSettled) {
                json(res, { ok: true, duplicate: true });
                return;
            }
            let feedback: string | undefined;
            let agentSwitch: string | undefined;
            let requestedPermissionMode: string | undefined;
            let compactContext = false;
            try {
                const body = await parseBody(req);
                if (body.feedback) feedback = body.feedback as string;
                if (body.agentSwitch) agentSwitch = body.agentSwitch as string;
                if (body.permissionMode)
                    requestedPermissionMode = body.permissionMode as string;
                compactContext = body.compactContext === true;
            } catch (err) {
                console.error(`[Integration] Error:`, err);
            }
            deleteDraft(draftKey);
            const effectivePermissionMode =
                requestedPermissionMode || options.permissionMode;
            publishDecision({
                approved: true,
                feedback,
                agentSwitch,
                permissionMode: effectivePermissionMode,
                compactContext,
            });
            json(res, { ok: true });
        } else if (url.pathname === "/api/deny" && req.method === "POST") {
            if (decisionSettled) {
                json(res, { ok: true, duplicate: true });
                return;
            }
            let feedback = "Plan rejected by user";
            try {
                const body = await parseBody(req);
                feedback = (body.feedback as string) || feedback;
            } catch {
                /* use default feedback */
            }
            deleteDraft(draftKey);
            publishDecision({ approved: false, feedback });
            json(res, { ok: true });
        } else {
            html(res, options.htmlContent);
        }
    });

    const { port, portSource } = await listenOnPort(server);

    return {
        reviewId,
        port,
        portSource,
        url: `http://localhost:${port}`,
        waitForDecision: () => decisionPromise,
        onDecision: (listener) => {
            decisionListeners.add(listener);
            return () => {
                decisionListeners.delete(listener);
            };
        },
        stop: () => server.close(),
    };
}
