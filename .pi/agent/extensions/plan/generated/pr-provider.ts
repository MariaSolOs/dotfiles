// @ts-nocheck
// @generated — DO NOT EDIT. Source: packages/shared/pr-provider.ts
/**
 * Server-only GitHub PR provider facade.
 *
 * This local Plan extension only supports GitHub PR review.
 */

import {
    checkGhAuth,
    getGhUser,
    fetchGhPR,
    fetchGhPRContext,
    fetchGhPRFileContent,
    submitGhPRReview,
    fetchGhPRViewedFiles,
    markGhFilesViewed,
    fetchGhPRStack,
    fetchGhPRList,
} from "./pr-github";
import type {
    PRRuntime,
    PRRef,
    PRMetadata,
    PRContext,
    PRReviewFileComment,
    PRStackTree,
    PRListItem,
} from "./pr-types";

export * from "./pr-types";

export async function checkAuth(runtime: PRRuntime, ref: PRRef): Promise<void> {
    return checkGhAuth(runtime, ref.host);
}

export async function getUser(
    runtime: PRRuntime,
    ref: PRRef,
): Promise<string | null> {
    return getGhUser(runtime, ref.host);
}

export async function fetchPR(
    runtime: PRRuntime,
    ref: PRRef,
): Promise<{ metadata: PRMetadata; rawPatch: string }> {
    return fetchGhPR(runtime, ref);
}

export async function fetchPRContext(
    runtime: PRRuntime,
    ref: PRRef,
): Promise<PRContext> {
    return fetchGhPRContext(runtime, ref);
}

export async function fetchPRFileContent(
    runtime: PRRuntime,
    ref: PRRef,
    sha: string,
    filePath: string,
): Promise<string | null> {
    return fetchGhPRFileContent(runtime, ref, sha, filePath);
}

export async function submitPRReview(
    runtime: PRRuntime,
    ref: PRRef,
    headSha: string,
    action: "approve" | "comment",
    body: string,
    fileComments: PRReviewFileComment[],
): Promise<void> {
    return submitGhPRReview(runtime, ref, headSha, action, body, fileComments);
}

export async function fetchPRViewedFiles(
    runtime: PRRuntime,
    ref: PRRef,
): Promise<Record<string, boolean>> {
    return fetchGhPRViewedFiles(runtime, ref);
}

export async function markPRFilesViewed(
    runtime: PRRuntime,
    ref: PRRef,
    prNodeId: string,
    filePaths: string[],
    viewed: boolean,
): Promise<void> {
    return markGhFilesViewed(runtime, ref, prNodeId, filePaths, viewed);
}

export async function fetchPRStack(
    runtime: PRRuntime,
    ref: PRRef,
    metadata: PRMetadata,
): Promise<PRStackTree | null> {
    return fetchGhPRStack(runtime, ref, metadata);
}

export async function fetchPRList(
    runtime: PRRuntime,
    ref: PRRef,
): Promise<PRListItem[]> {
    return fetchGhPRList(runtime, ref);
}
