import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export type Run = (file: string, args: string[]) => Promise<string>;

export function commandRunner(pi: ExtensionAPI, signal: AbortSignal): Run {
    return async (file, args) => {
        signal.throwIfAborted();
        const result = await pi.exec(file, args, { signal, timeout: 30_000 });
        signal.throwIfAborted();
        if (result.code !== 0 || result.killed) {
            throw new Error(
                result.stderr.trim() || `${file} failed or timed out`,
            );
        }
        return result.stdout;
    };
}

export type GitHubLink = {
    url: string;
    host: string;
    repo: string;
    number: string;
    target?: { kind: "comment" | "review-comment" | "review"; id: string };
};

export function parseLink(raw: string): GitHubLink {
    let url: URL;
    try {
        url = new URL(raw);
    } catch {
        throw new Error("Provide a full GitHub issue, PR, or comment URL");
    }
    const match = url.pathname.match(
        /^\/([\w.-]+)\/([\w.-]+)\/(issues|pull)\/([1-9]\d*)(?:\/(?:files|commits|changes))?\/?$/,
    );
    if (
        !match ||
        url.protocol !== "https:" ||
        url.username ||
        url.password ||
        url.port ||
        !/^[a-z0-9][a-z0-9.-]*$/i.test(url.hostname)
    ) {
        throw new Error("Expected an HTTPS GitHub issue, PR, or comment URL");
    }
    const anchor = url.hash.match(
        /^#(issuecomment-|discussion_r|pullrequestreview-)([1-9]\d*)$/,
    );
    if (url.hash && !anchor && !/^#issue-\d+$/.test(url.hash)) {
        throw new Error(`Unsupported GitHub anchor: ${url.hash}`);
    }
    const kind =
        anchor?.[1] === "issuecomment-"
            ? "comment"
            : anchor?.[1] === "discussion_r"
              ? "review-comment"
              : "review";
    if (anchor && kind !== "comment" && match[3] !== "pull") {
        throw new Error("Review links must point to a pull request");
    }
    url.search = "";
    return {
        url: url.href,
        host: url.hostname,
        repo: `${match[1]}/${match[2]}`,
        number: match[4],
        target: anchor ? { kind, id: anchor[2] } : undefined,
    };
}

type GitHubItem = {
    id: number;
    body?: string | null;
    title?: string;
    state?: string;
    user?: { login: string };
    html_url?: string;
    issue_url?: string;
    pull_request_url?: string;
    pull_request?: unknown;
    created_at?: string;
    submitted_at?: string;
    path?: string;
    line?: number;
    diff_hunk?: string;
    in_reply_to_id?: number;
    base?: { ref: string };
    head?: { ref: string };
};

export function truncate(text: string, max: number): string {
    if (text.length <= max) return text;
    const note = "\n...[truncated]";
    return text.slice(0, max - note.length) + note;
}

function describe(item: GitHubItem, bodyLimit = 6_000): string {
    return JSON.stringify({
        id: item.id,
        author: item.user?.login,
        url: item.html_url,
        title: item.title,
        state: item.state,
        date: item.created_at ?? item.submitted_at,
        body: truncate(item.body ?? "", bodyLimit),
        path: item.path,
        line: item.line,
        in_reply_to_id: item.in_reply_to_id,
        diff_hunk: item.diff_hunk
            ? truncate(item.diff_hunk, 12_000)
            : undefined,
        base: item.base?.ref,
        head: item.head?.ref,
    });
}

// REST endpoints work on both github.com and GitHub Enterprise, and distinguish
// conversation comments, inline review comments, and top-level PR reviews.
export async function collectContext(
    link: GitHubLink,
    run: Run,
): Promise<string> {
    const base = `repos/${link.repo}`;
    const api = async <T>(endpoint: string): Promise<T> =>
        JSON.parse(
            await run("gh", [
                "api",
                "--hostname",
                link.host,
                "--method",
                "GET",
                "-H",
                "Accept: application/vnd.github+json",
                endpoint,
            ]),
        ) as T;
    const list = async <T>(endpoint: string): Promise<T[]> => {
        const items: T[] = [];
        // Bound requests without silently treating a partial thread as complete.
        for (let page = 1; page <= 10; page++) {
            const batch = await api<T[]>(
                `${endpoint}?per_page=100&page=${page}`,
            );
            items.push(...batch);
            if (batch.length < 100) return items;
        }
        throw new Error(
            "GitHub thread reaches the 1,000-item fetch limit; no draft generated",
        );
    };

    const parent = await api<GitHubItem>(`${base}/issues/${link.number}`);
    const isPr = Boolean(parent.pull_request);
    let target: GitHubItem | undefined;
    if (link.target) {
        const { kind, id } = link.target;
        if (kind !== "comment" && !isPr) throw new Error("Not a pull request");
        const endpoint =
            kind === "comment"
                ? `${base}/issues/comments/${id}`
                : kind === "review-comment"
                  ? `${base}/pulls/comments/${id}`
                  : `${base}/pulls/${link.number}/reviews/${id}`;
        target = await api<GitHubItem>(endpoint);
        // Comment IDs are repository-scoped endpoints, so check that the URL's
        // issue/PR number actually owns the requested comment.
        const ownerUrl =
            kind === "comment" ? target.issue_url : target.pull_request_url;
        if (
            kind !== "review" &&
            (!ownerUrl || !ownerUrl.endsWith(`/${link.number}`))
        ) {
            throw new Error(
                "The linked comment does not belong to this issue/PR",
            );
        }
    }

    const comments = await list<GitHubItem>(
        `${base}/issues/${link.number}/comments`,
    );
    const sections = [
        `Reply destination: ${link.url}`,
        `Issue/PR:\n${describe(parent, 16_000)}`,
        target
            ? `Reply specifically to this ${link.target!.kind}:\n${describe(target, 24_000)}`
            : "Reply to the issue/PR as a whole, taking the conversation into account.",
    ];

    if (isPr) {
        const pr = await api<GitHubItem>(`${base}/pulls/${link.number}`);
        sections.push(`PR metadata:\n${describe({ ...pr, body: undefined })}`);
        const reviews = await list<GitHubItem>(
            `${base}/pulls/${link.number}/reviews`,
        );
        const inline = await list<GitHubItem>(
            `${base}/pulls/${link.number}/comments`,
        );
        if (link.target?.kind === "review-comment" && target) {
            const root = target.in_reply_to_id ?? target.id;
            const thread = inline.filter(
                (item) => item.id === root || item.in_reply_to_id === root,
            );
            sections.push(
                `Linked review thread:\n${truncate(thread.map((item) => describe(item)).join("\n"), 20_000)}`,
            );
        }
        if (link.target?.kind === "review") {
            const reviewComments = await list<GitHubItem>(
                `${base}/pulls/${link.number}/reviews/${link.target.id}/comments`,
            );
            sections.push(
                `Comments in the linked review:\n${truncate(reviewComments.map((item) => describe(item)).join("\n"), 20_000)}`,
            );
        }
        comments.push(...reviews, ...inline);
        const files = await list<{
            filename: string;
            status: string;
            patch?: string;
        }>(`${base}/pulls/${link.number}/files`);
        sections.push(
            `PR files and patches (GitHub may omit binary/large patches):\n${truncate(files.map((file) => JSON.stringify({ filename: file.filename, status: file.status, patch: file.patch ? truncate(file.patch, 6_000) : "[patch unavailable]" })).join("\n"), 20_000)}`,
        );
    }

    // Prefer recent discussion when context is large. The explicitly linked
    // comment and thread above take priority over unrelated conversation.
    comments.sort((a, b) =>
        (a.created_at ?? a.submitted_at ?? "").localeCompare(
            b.created_at ?? b.submitted_at ?? "",
        ),
    );
    const recent: string[] = [];
    let remaining = 24_000;
    for (const item of [...comments].reverse()) {
        const text = describe(item);
        if (text.length + 1 > remaining) break;
        recent.unshift(text);
        remaining -= text.length + 1;
    }
    sections.push(
        `Conversation (${recent.length}/${comments.length} entries, most recent retained):\n${recent.join("\n")}`,
    );
    return sections.join("\n\n");
}
