// @ts-nocheck
// @generated — DO NOT EDIT. Source: packages/shared/pr-types.ts
/**
 * Browser-safe GitHub PR types and pure helpers.
 *
 * This local Plan extension only supports GitHub PR review.
 */

// --- Runtime Types ---

export interface CommandResult {
    stdout: string;
    stderr: string;
    exitCode: number;
}

export interface PRRuntime {
    runCommand: (cmd: string, args: string[]) => Promise<CommandResult>;
    runCommandWithInput?: (
        cmd: string,
        args: string[],
        input: string,
    ) => Promise<CommandResult>;
}

// --- Platform Types ---

export type Platform = "github";

export interface GithubPRRef {
    platform: "github";
    host: string;
    owner: string;
    repo: string;
    number: number;
}

export type PRRef = GithubPRRef;

export interface GithubPRMetadata {
    platform: "github";
    host: string;
    owner: string;
    repo: string;
    number: number;
    /** GraphQL node ID for the PR — used for markFileAsViewed mutations */
    prNodeId?: string;
    title: string;
    author: string;
    baseBranch: string;
    headBranch: string;
    /** Repository default branch, used to infer whether this PR targets another PR branch. */
    defaultBranch?: string;
    baseSha: string;
    headSha: string;
    /** Merge-base SHA — the common ancestor commit used to compute the PR diff. Differs from baseSha when the base branch has moved. */
    mergeBaseSha?: string;
    url: string;
}

export type PRMetadata = GithubPRMetadata;

// --- PR Context Types ---

export interface PRComment {
    id: string;
    author: string;
    body: string;
    createdAt: string;
    url: string;
}

export interface PRReview {
    id: string;
    author: string;
    state: string;
    body: string;
    submittedAt: string;
    url?: string;
}

export interface PRCheck {
    name: string;
    status: string;
    conclusion: string | null;
    workflowName: string;
    detailsUrl: string;
}

export interface PRLinkedIssue {
    number: number;
    url: string;
    repo: string;
}

export interface PRThreadComment {
    id: string;
    author: string;
    body: string;
    createdAt: string;
    url: string;
    diffHunk?: string;
}

export interface PRReviewThread {
    id: string;
    isResolved: boolean;
    isOutdated: boolean;
    path: string;
    line: number | null;
    startLine: number | null;
    diffSide: "LEFT" | "RIGHT" | null;
    comments: PRThreadComment[];
}

export interface PRContext {
    body: string;
    state: string;
    isDraft: boolean;
    labels: Array<{ name: string; color: string }>;
    reviewDecision: string;
    mergeable: string;
    mergeStateStatus: string;
    comments: PRComment[];
    reviews: PRReview[];
    reviewThreads: PRReviewThread[];
    checks: PRCheck[];
    linkedIssues: PRLinkedIssue[];
}

export interface PRReviewFileComment {
    path: string;
    line: number;
    side: "LEFT" | "RIGHT";
    body: string;
    start_line?: number;
    start_side?: "LEFT" | "RIGHT";
}

export type PRDiffScope = "layer" | "full-stack";

export interface PRDiffScopeOption {
    id: PRDiffScope;
    label: string;
    description: string;
    enabled: boolean;
}

export interface PRStackInfo {
    isStacked: boolean;
    baseBranch: string;
    defaultBranch?: string;
    label: string;
    source: "branch-inferred" | "tree-discovered" | "github-native" | "ghstack";
}

export interface PRStackNode {
    branch: string;
    number?: number;
    title?: string;
    url?: string;
    isCurrent: boolean;
    isDefaultBranch: boolean;
    state?: "open" | "merged" | "closed";
}

export interface PRStackTree {
    nodes: PRStackNode[];
}

export interface PRListItem {
    id: string;
    number: number;
    title: string;
    author: string;
    url: string;
    baseBranch: string;
    state: "open" | "closed" | "merged";
}

// --- Label Helpers ---

type HasPlatform = PRRef | PRMetadata;

export function getPlatformLabel(_m: HasPlatform): string {
    return "GitHub";
}

export function getMRLabel(_m: HasPlatform): string {
    return "PR";
}

export function getMRNumberLabel(m: HasPlatform): string {
    return `#${m.number}`;
}

export function getDisplayRepo(m: HasPlatform): string {
    return `${m.owner}/${m.repo}`;
}

export function prRefFromMetadata(m: PRMetadata): PRRef {
    return {
        platform: "github",
        host: m.host,
        owner: m.owner,
        repo: m.repo,
        number: m.number,
    };
}

export function isSameProject(a: PRRef, b: PRRef): boolean {
    return a.host === b.host && a.owner === b.owner && a.repo === b.repo;
}

export function getCliName(_ref: PRRef): string {
    return "gh";
}

export function getCliInstallUrl(_ref: PRRef): string {
    return "https://cli.github.com";
}

export function encodeApiFilePath(filePath: string): string {
    return encodeURIComponent(filePath);
}

// --- URL Parsing ---

/**
 * Parse a GitHub PR URL into its components.
 *
 * Handles:
 * - GitHub: https://github.com/owner/repo/pull/123[/files|/commits]
 * - GitHub Enterprise: https://ghe.company.com/owner/repo/pull/123
 */
export function parsePRUrl(url: string): PRRef | null {
    if (!url) return null;

    const ghMatch = url.match(
        /^https?:\/\/([^/]+)\/([^/]+)\/([^/]+)\/pull\/(\d+)/,
    );
    if (ghMatch) {
        return {
            platform: "github",
            host: ghMatch[1],
            owner: ghMatch[2],
            repo: ghMatch[3],
            number: parseInt(ghMatch[4], 10),
        };
    }

    return null;
}
