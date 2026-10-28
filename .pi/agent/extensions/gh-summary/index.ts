import { spawn } from "node:child_process";
import { mkdtemp, open, readFile, rm, stat, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import type { AssistantMessage, UserMessage } from "@earendil-works/pi-ai";
import type {
    ExtensionAPI,
    ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent";
import {
    checkEditor,
    handoffShell,
    openDraft,
    saveDraft,
    waitForDraftClose,
    type ClosedDraft,
} from "./editor.js";

// Keep the summarization request bounded while preserving enough concrete diff
// context for the model to write a useful PR title and description.
const MAX_CHANGESET_CHARS = 120_000;
const MAX_SECTION_CHARS = 50_000;
const MAX_CONVERSATION_CONTEXT_CHARS = 12_000;
const MAX_EXTRA_CONTEXT_CHARS = 8_000;
const MAX_UNTRACKED_FILES = 25;
const MAX_UNTRACKED_READ_BYTES = 256_000;
const MAX_UNTRACKED_FILE_CHARS = 12_000;

// The default body shows the change with short prose plus the smallest useful
// visual, then says how it was tested. A repo PR template takes precedence.
const SYSTEM_PROMPT = `You write terse GitHub pull request titles and bodies from git changes. Reviewers skim: every line must earn its place.

Grounding:
- Base the PR primarily on the provided git status, commits, diffs, and untracked file contents.
- Use extra context and conversation context only to understand intent, rationale, or wording for those changes. Never mention work not reflected in the git changes.
- Never invent testing. Only cite test runs, commands, or results that appear in the provided context.

Default body template (use it unless a PR template is provided; omit a section entirely if there is nothing grounded to put in it):

## Changes

<one or two short sentences of intent, then the smallest visual that makes the key point clear>

## Testing

<a short paragraph on how the change was verified: tests added or run, commands, manual checks>

Changes visuals (pick one, rarely two; use fenced code blocks):
- Pseudocode for logic or algorithms, a call tree for runtime flow, a shallow file tree for broad refactors, or a Mermaid diagram for interaction between components.
- Keep only the calls, files, states, and boundaries needed to understand the change. Skip the visual if the change is trivial.

Testing:
- Mention test runs or manual checks from the provided context.

Style:
- Use raw Markdown only; do not wrap the whole response in a code fence.
- No preamble, no restating the title, no filler like "This PR..." or "Here's a summary".
- Prefer short paragraphs over bullet lists. No paragraph longer than three sentences.
- Use only ASCII apostrophes (', U+0027) and double quotes (", U+0022) in the title and body. Do not use curly apostrophes or quotation marks.
- Describe changes in the body using present participles ("-ing" forms), such as "Removing the unused function" or "Adding validation", rather than imperatives like "Remove" or "Add". This does not apply to the title.
- Keep the title short and specific (under ~70 characters).`;

function truncate(value: string, max = MAX_SECTION_CHARS): string {
    if (value.length <= max) return value;
    return `${value.slice(0, max)}\n...[truncated ${value.length - max} chars]`;
}

type CommandResult = {
    code: number;
    stdout: string;
    stderr: string;
};

type ContentBlock = {
    type?: string;
    text?: string;
};

type SessionEntry = {
    type?: string;
    message?: {
        role?: string;
        content?: unknown;
    };
};

function runCapture(
    file: string,
    args: string[],
    cwd: string,
    allowedExitCodes = [0],
    input?: string,
): Promise<CommandResult> {
    return new Promise((resolve, reject) => {
        const child = spawn(file, args, {
            cwd,
            stdio: ["pipe", "pipe", "pipe"],
        });
        // Closing stdin immediately matches an ignored stdin for commands
        // that do not read input.
        child.stdin.on("error", () => {});
        child.stdin.end(input ?? "");
        let stdout = "";
        let stderr = "";

        child.stdout.on("data", (chunk) => {
            stdout += String(chunk);
        });
        child.stderr.on("data", (chunk) => {
            stderr += String(chunk);
        });
        child.on("error", reject);
        child.on("close", (code) => {
            const resolvedCode = code ?? 1;
            if (allowedExitCodes.includes(resolvedCode)) {
                resolve({ code: resolvedCode, stdout, stderr });
            } else {
                reject(
                    new Error(
                        stderr.trim() ||
                            `${file} ${args.join(" ")} exited with code ${resolvedCode}`,
                    ),
                );
            }
        });
    });
}

async function runGit(
    cwd: string,
    args: string[],
    allowedExitCodes = [0],
): Promise<string> {
    const result = await runCapture("git", args, cwd, allowedExitCodes);
    return result.stdout;
}

function extractTextParts(content: unknown): string[] {
    if (typeof content === "string") return [content];
    if (!Array.isArray(content)) return [];

    const parts: string[] = [];
    for (const item of content) {
        if (!item || typeof item !== "object") continue;
        const block = item as ContentBlock;
        if (block.type === "text" && typeof block.text === "string") {
            parts.push(block.text);
        }
    }
    return parts;
}

function buildConversationContext(entries: SessionEntry[]): string {
    const sections: string[] = [];
    let total = 0;

    for (const entry of [...entries].reverse()) {
        if (entry.type !== "message" || !entry.message?.role) continue;

        const role = entry.message.role;
        if (role !== "user" && role !== "assistant") continue;

        const text = extractTextParts(entry.message.content).join("\n").trim();
        if (!text) continue;

        const label = role === "user" ? "User" : "Assistant";
        const section = `${label}: ${truncate(text, 2_000)}`;
        const separatorLength = sections.length === 0 ? 0 : 2;
        if (
            total + separatorLength + section.length >
            MAX_CONVERSATION_CONTEXT_CHARS
        ) {
            break;
        }

        sections.unshift(section);
        total += separatorLength + section.length;
    }

    return sections.join("\n\n");
}

function appendBoundedSection(
    sections: string[],
    title: string,
    body: string,
    total: { value: number },
): void {
    if (total.value >= MAX_CHANGESET_CHARS) return;

    const trimmed = body.trimEnd();
    if (!trimmed) return;

    let section = `## ${title}\n${trimmed}`;
    const separatorLength = sections.length === 0 ? 0 : 2;
    if (total.value + separatorLength + section.length > MAX_CHANGESET_CHARS) {
        const remaining = MAX_CHANGESET_CHARS - total.value - separatorLength;
        if (remaining <= 500) {
            sections.push("...[git changes truncated]");
            total.value = MAX_CHANGESET_CHARS;
            return;
        }
        section = truncate(section, remaining);
    }

    sections.push(section);
    total.value += separatorLength + section.length;
}

function parseNulSeparated(value: string): string[] {
    return value.split("\0").filter(Boolean);
}

function resolveRepoPath(
    root: string,
    relativePath: string,
): string | undefined {
    const resolved = path.resolve(root, relativePath);
    const relative = path.relative(root, resolved);
    if (
        relative === "" ||
        relative.startsWith("..") ||
        path.isAbsolute(relative)
    ) {
        return undefined;
    }
    return resolved;
}

async function readUntrackedFile(
    root: string,
    relativePath: string,
): Promise<string> {
    const absolutePath = resolveRepoPath(root, relativePath);
    if (!absolutePath) return "[omitted: path resolves outside repository]";

    try {
        const fileStat = await stat(absolutePath);
        if (!fileStat.isFile()) return "[omitted: not a regular file]";

        const bytesToRead = Math.min(fileStat.size, MAX_UNTRACKED_READ_BYTES);
        const handle = await open(absolutePath, "r");
        try {
            const buffer = Buffer.alloc(bytesToRead);
            const { bytesRead } = await handle.read(buffer, 0, bytesToRead, 0);
            const content = buffer.subarray(0, bytesRead);
            if (content.includes(0)) return "[binary file omitted]";

            const truncationNote =
                fileStat.size > bytesRead
                    ? `\n...[truncated ${fileStat.size - bytesRead} bytes]`
                    : "";
            return truncate(
                content.toString("utf8") + truncationNote,
                MAX_UNTRACKED_FILE_CHARS,
            );
        } finally {
            await handle.close();
        }
    } catch (error) {
        return `[omitted: ${(error as Error).message}]`;
    }
}

async function buildUntrackedSection(
    root: string,
    rawFiles: string,
): Promise<string> {
    const files = parseNulSeparated(rawFiles);
    if (files.length === 0) return "";

    const chunks = [
        `Untracked files (${files.length}):`,
        files.map((file) => `- ${file}`).join("\n"),
    ];

    for (const file of files.slice(0, MAX_UNTRACKED_FILES)) {
        const content = await readUntrackedFile(root, file);
        chunks.push([`--- ${file}`, content].join("\n"));
    }

    if (files.length > MAX_UNTRACKED_FILES) {
        chunks.push(
            `...[omitted ${files.length - MAX_UNTRACKED_FILES} additional untracked files]`,
        );
    }

    return chunks.join("\n\n");
}

type GitChanges = {
    root: string;
    // Checked-out branch name; empty for a detached HEAD.
    branch: string;
    source: "worktree" | "branch";
    text: string;
};

async function refExists(root: string, ref: string): Promise<boolean> {
    const result = await runCapture(
        "git",
        ["rev-parse", "--verify", "--quiet", `${ref}^{commit}`],
        root,
        [0, 1],
    );
    return result.code === 0;
}

async function firstExistingBaseRef(
    root: string,
    branch: string,
): Promise<string | undefined> {
    const candidates: string[] = [];

    const originHead = await runCapture(
        "git",
        ["symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"],
        root,
        [0, 1],
    );
    if (originHead.code === 0 && originHead.stdout.trim()) {
        candidates.push(originHead.stdout.trim());
    }

    candidates.push("origin/main", "origin/master", "main", "master");

    const upstream = await runCapture(
        "git",
        ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"],
        root,
        [0, 128],
    );
    if (upstream.code === 0 && upstream.stdout.trim()) {
        candidates.push(upstream.stdout.trim());
    }

    for (const candidate of [...new Set(candidates)]) {
        if (candidate === branch) continue;
        if (await refExists(root, candidate)) return candidate;
    }

    return undefined;
}

async function collectBranchChanges(
    root: string,
    branch: string,
    head: string,
): Promise<GitChanges> {
    branch = branch.trim();
    const baseRef = await firstExistingBaseRef(root, branch);
    if (!baseRef) return { root, branch, source: "branch", text: "" };

    const mergeBase = (
        await runGit(root, ["merge-base", baseRef, "HEAD"], [0, 1])
    ).trim();
    if (!mergeBase) return { root, branch, source: "branch", text: "" };

    const commitCount = Number(
        (
            await runGit(root, ["rev-list", "--count", `${mergeBase}..HEAD`])
        ).trim(),
    );
    if (commitCount === 0) return { root, branch, source: "branch", text: "" };

    const [commits, diffStat, diff] = await Promise.all([
        runGit(root, ["log", "--oneline", "--decorate", `${mergeBase}..HEAD`]),
        runGit(root, ["diff", "--stat", `${mergeBase}..HEAD`, "--"]),
        runGit(root, [
            "diff",
            "--no-ext-diff",
            "--find-renames",
            "--find-copies",
            `${mergeBase}..HEAD`,
            "--",
        ]),
    ]);

    const sections: string[] = [];
    const total = { value: 0 };
    appendBoundedSection(
        sections,
        "Repository",
        [
            `Root: ${root}`,
            `Branch: ${branch.trim() || "(detached HEAD)"}`,
            `HEAD: ${head.trim()}`,
            `Base ref: ${baseRef}`,
            `Merge base: ${mergeBase.slice(0, 12)}`,
            `Commits ahead: ${commitCount}`,
        ].join("\n"),
        total,
    );
    appendBoundedSection(sections, "Branch commits", commits, total);
    appendBoundedSection(sections, "Branch diffstat", diffStat, total);
    appendBoundedSection(sections, "Branch diff", diff, total);

    return { root, branch, source: "branch", text: sections.join("\n\n") };
}

async function collectGitChanges(cwd: string): Promise<GitChanges> {
    let root: string;
    try {
        root = (await runGit(cwd, ["rev-parse", "--show-toplevel"])).trim();
    } catch (error) {
        throw new Error(
            `Not a git repository, or git is unavailable: ${(error as Error).message}`,
        );
    }

    const [branch, head, status] = await Promise.all([
        runGit(root, ["branch", "--show-current"]),
        runGit(root, ["rev-parse", "--short", "HEAD"]),
        runGit(root, ["status", "--short"]),
    ]);

    if (!status.trim()) return collectBranchChanges(root, branch, head);

    const [stagedStat, unstagedStat, stagedDiff, unstagedDiff, untrackedRaw] =
        await Promise.all([
            runGit(root, ["diff", "--cached", "--stat", "--"]),
            runGit(root, ["diff", "--stat", "--"]),
            runGit(root, [
                "diff",
                "--cached",
                "--no-ext-diff",
                "--find-renames",
                "--find-copies",
                "--",
            ]),
            runGit(root, [
                "diff",
                "--no-ext-diff",
                "--find-renames",
                "--find-copies",
                "--",
            ]),
            runGit(root, ["ls-files", "--others", "--exclude-standard", "-z"]),
        ]);

    const sections: string[] = [];
    const total = { value: 0 };
    appendBoundedSection(
        sections,
        "Repository",
        [
            `Root: ${root}`,
            `Branch: ${branch.trim() || "(detached HEAD)"}`,
            `HEAD: ${head.trim()}`,
        ].join("\n"),
        total,
    );
    appendBoundedSection(sections, "Worktree status", status, total);
    appendBoundedSection(sections, "Staged diffstat", stagedStat, total);
    appendBoundedSection(sections, "Staged diff", stagedDiff, total);
    appendBoundedSection(sections, "Unstaged diffstat", unstagedStat, total);
    appendBoundedSection(sections, "Unstaged diff", unstagedDiff, total);
    appendBoundedSection(
        sections,
        "Untracked files",
        await buildUntrackedSection(root, untrackedRaw),
        total,
    );

    return {
        root,
        branch: branch.trim(),
        source: "worktree",
        text: sections.join("\n\n"),
    };
}

// Match GitHub's common single-file PR template location; absence is normal.
async function readPrTemplate(cwd: string): Promise<string | undefined> {
    try {
        const templatePath = path.join(
            cwd,
            ".github",
            "PULL_REQUEST_TEMPLATE.md",
        );
        const template = await readFile(templatePath, "utf8");
        return template.trim() || undefined;
    } catch (error) {
        const code = (error as NodeJS.ErrnoException).code;
        if (code === "ENOENT" || code === "ENOTDIR") return undefined;
        throw error;
    }
}

function expandHome(value: string): string {
    if (value === "~") return os.homedir();
    if (value.startsWith("~/")) return path.join(os.homedir(), value.slice(2));
    return value;
}

type ParsedArgs = { repo?: string; extraContext: string };

// Split the raw argument string into an optional `--repo <path>` (or
// `--repo=<path>`) flag and free-form extra context. Everything that is not the
// repo flag is passed through to the model as supporting context, matching the
// original single-argument behaviour when the flag is absent.
function parseArgs(rawArgs: string): ParsedArgs {
    const tokens =
        (rawArgs ?? "").trim().match(/(?:[^\s"']+|"[^"]*"|'[^']*')+/g) ?? [];
    const unquote = (value: string) => value.replace(/^['"]|['"]$/g, "");
    const rest: string[] = [];
    let repo: string | undefined;

    for (let i = 0; i < tokens.length; i++) {
        const token = tokens[i];
        if (token === "--repo") {
            const next = tokens[i + 1];
            if (next !== undefined) {
                repo = expandHome(unquote(next));
                i++;
            }
            continue;
        }
        if (token.startsWith("--repo=")) {
            repo = expandHome(unquote(token.slice("--repo=".length)));
            continue;
        }
        rest.push(token);
    }

    return { repo, extraContext: rest.join(" ") };
}

function buildUserPrompt(
    changesText: string,
    source: GitChanges["source"],
    extraContext: string,
    conversationContext: string,
    prTemplate?: string,
): string {
    const templateSection = prTemplate
        ? [
              "Use this GitHub PR template instead of the default body template. Keep each section terse and prefer visuals over prose where they fit:",
              "<pull_request_template>",
              prTemplate,
              "</pull_request_template>",
              "",
          ].join("\n")
        : "";

    const extraContextSection = extraContext.trim()
        ? [
              "Extra context provided explicitly with this command. Use this only to clarify intent/rationale for the git changes:",
              "<extra_context>",
              truncate(extraContext.trim(), MAX_EXTRA_CONTEXT_CHARS),
              "</extra_context>",
              "",
          ].join("\n")
        : "";

    const conversationSection = conversationContext.trim()
        ? [
              "Supplemental conversation context. Use this only to clarify intent/rationale for the git changes; do not summarize unrelated parts of the conversation:",
              "<conversation_context>",
              conversationContext,
              "</conversation_context>",
              "",
          ].join("\n")
        : "";

    const sourceDescription =
        source === "worktree"
            ? "current git worktree changes"
            : "commits on the current branch";

    return [
        `Summarize the ${sourceDescription} into a terse GitHub-ready PR body, together with a suggested title.`,
        "Focus on the provided git changes. Use extra/context sections only as supporting context for those changes, not as the thing being summarized.",
        "",
        templateSection,
        extraContextSection,
        conversationSection,
        "Output format:",
        "Title: <suggested PR title>",
        "",
        "<PR body markdown>",
        "",
        "Git changes:",
        "<git_changes>",
        changesText,
        "</git_changes>",
    ].join("\n");
}

// The prompt forbids wrapping fences, but strip one anyway so the temp file is
// directly pasteable into GitHub if the model ignores that instruction.
function stripWrappingCodeFence(text: string): string {
    const trimmed = text.trim();
    const match = trimmed.match(/^```(?:markdown|md)?\s*\n([\s\S]*?)\n```$/i);
    return (match ? match[1] : trimmed).trimEnd() + "\n";
}

// Enforce the writing rule even if the isolated model call ignores its prompt,
// without stripping unrelated Unicode such as names or mathematical symbols.
function normalizeQuotes(text: string): string {
    return text.replace(/[\u2018\u2019]/g, "'").replace(/[\u201c\u201d]/g, '"');
}

function textFromResponse(response: AssistantMessage): string {
    return response.content
        .filter(
            (content): content is { type: "text"; text: string } =>
                content.type === "text",
        )
        .map((content) => content.text)
        .join("\n");
}

type PullRequest = { number: number; url: string };

// Look up the open PR for the checked-out branch. Resolves undefined when gh
// reports there is none; other failures (gh missing, unauthenticated, no
// GitHub remote) throw so callers do not try to create a PR blindly.
async function findPullRequest(root: string): Promise<PullRequest | undefined> {
    const result = await runCapture(
        "gh",
        ["pr", "view", "--json", "number,url,state"],
        root,
        [0, 1],
    );
    if (result.code !== 0) {
        if (/no (open )?pull requests? found/i.test(result.stderr)) {
            return undefined;
        }
        throw new Error(result.stderr.trim() || "gh pr view failed");
    }
    const pr = JSON.parse(result.stdout) as PullRequest & { state?: string };
    if (pr.state && pr.state !== "OPEN") return undefined;
    return pr.url ? { number: pr.number, url: pr.url } : undefined;
}

// What closing the draft does to GitHub, decided when the command starts so
// the user is told up front and the editor wrapper only waits for pi when
// there is something to do.
type PrTarget =
    | { kind: "edit"; pr: PullRequest }
    | { kind: "create"; branch: string }
    | { kind: "none"; reason: string };

// Never rejects: it runs concurrently with generation, and any failure only
// disables syncing to GitHub.
async function resolvePrTarget(changes: GitChanges): Promise<PrTarget> {
    try {
        return await resolvePrTargetOrThrow(changes);
    } catch (error) {
        return { kind: "none", reason: (error as Error).message };
    }
}

async function resolvePrTargetOrThrow(changes: GitChanges): Promise<PrTarget> {
    const pr = await findPullRequest(changes.root);
    if (pr) return { kind: "edit", pr };

    // Creating a PR commits and pushes, so refuse anywhere that would land
    // the work on the base branch itself.
    const branch = changes.branch;
    if (!branch) return { kind: "none", reason: "HEAD is detached" };
    const baseRef = await firstExistingBaseRef(changes.root, branch);
    const baseBranch = baseRef?.replace(/^[^/]+\//, "");
    if (branch === baseBranch || branch === "main" || branch === "master") {
        return { kind: "none", reason: `${branch} is the base branch` };
    }
    return { kind: "create", branch };
}

// Split the edited draft back into the "Title: ..." line the model was asked
// to emit and the Markdown body. Without a title line, the whole draft is the
// body and the PR's existing title is kept.
export function parseDraft(markdown: string): {
    title?: string;
    body: string;
} {
    const lines = normalizeQuotes(markdown).replace(/\r\n/g, "\n").split("\n");
    const first = lines.findIndex((line) => line.trim());
    if (first === -1) return { body: "" };
    const match = lines[first].match(/^\s*Title:\s*(.*?)\s*$/i);
    if (!match) return { body: lines.slice(first).join("\n").trim() };
    return {
        title: match[1] || undefined,
        body: lines
            .slice(first + 1)
            .join("\n")
            .trim(),
    };
}

async function updatePullRequest(
    root: string,
    pr: PullRequest,
    draft: { title?: string; body: string },
): Promise<void> {
    const args = ["pr", "edit", pr.url];
    if (draft.title) args.push("--title", draft.title);
    // Pipe the body through stdin: it can be large and contain anything.
    if (draft.body) args.push("--body-file", "-");
    await runCapture(
        "gh",
        args,
        root,
        [0],
        draft.body ? draft.body + "\n" : "",
    );
}

// Open a draft PR for the branch from the edited draft. Worktree summaries
// describe uncommitted work, so commit it first (titled like the PR) so that
// the PR contains what its description says.
async function createPullRequest(
    changes: GitChanges,
    branch: string,
    draft: { title: string; body: string },
): Promise<PullRequest> {
    const root = changes.root;
    const current = (await runGit(root, ["branch", "--show-current"])).trim();
    if (current !== branch) {
        throw new Error(
            `the checkout moved from ${branch} to ${current || "a detached HEAD"}`,
        );
    }

    if (
        changes.source === "worktree" &&
        (await runGit(root, ["status", "--porcelain"])).trim()
    ) {
        await runGit(root, ["add", "--all"]);
        await runGit(root, ["commit", "--message", draft.title]);
    }

    // Push to a same-named branch on origin; a bare `git push` could target
    // whatever the branch happens to track (e.g. origin/main).
    await runGit(root, ["push", "--set-upstream", "origin", branch]);

    const result = await runCapture(
        "gh",
        ["pr", "create", "--draft", "--title", draft.title, "--body-file", "-"],
        root,
        [0],
        draft.body + "\n",
    );
    const url = result.stdout.trim().split("\n").at(-1) ?? "";
    const number = Number(url.match(/\/pull\/(\d+)/)?.[1]);
    if (!url.startsWith("http") || !number) {
        throw new Error(`unexpected gh pr create output: ${result.stdout}`);
    }
    return { number, url };
}

function vimString(value: string): string {
    return `'${value.replace(/'/g, "''")}'`;
}

function nvimScript(summaryPath: string): string {
    return `set nomodeline noexrc
execute 'edit ' . fnameescape(${vimString(summaryPath)})
setlocal filetype=markdown noswapfile noundofile conceallevel=0
set nobackup nowritebackup
`;
}

function shellQuote(value: string): string {
    return `'${value.replace(/'/g, `'\\''`)}'`;
}

// Linux/Hyprland replaces the new pane's shell with this wrapper. macOS uses
// the native pane launcher instead, including its ID-scoped close/cleanup.
function wrapperScript(nvimScriptPath: string, tmpDir: string): string {
    const devNvim = path.join(
        os.homedir(),
        "Code",
        "neovim",
        "build",
        "bin",
        "nvim",
    );
    const devRuntime = path.join(os.homedir(), "Code", "neovim", "runtime");

    return `#!/bin/sh
set +e
vimscript=${shellQuote(nvimScriptPath)}
tmpdir=${shellQuote(tmpDir)}
# Clean up on every wrapper exit, including launch failures and editor errors.
# Signal handlers exit through the same trap; SIGKILL cannot be trapped.
trap 'rm -rf -- "$tmpdir"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
if [ -n "\${NVIM_BIN:-}" ]; then
  nvim_bin=$NVIM_BIN
elif command -v nvim >/dev/null 2>&1; then
  nvim_bin=$(command -v nvim)
elif [ -x ${shellQuote(devNvim)} ]; then
  nvim_bin=${shellQuote(devNvim)}
  if [ -d ${shellQuote(devRuntime)} ]; then
    VIMRUNTIME=${shellQuote(devRuntime)}
    export VIMRUNTIME
  fi
else
  echo "nvim not found in PATH and development build not found at ${devNvim}" >&2
  exit 127
fi
"$nvim_bin" -n -i NONE -S "$vimscript"
status=$?
${handoffShell(tmpDir)}
# Like revisar, do not leave Ghostty showing an abnormal command exit after
# the editor finishes. The EXIT trap still deletes the temporary files.
exit 0
`;
}

async function commandExists(command: string): Promise<boolean> {
    const result = await runCapture(
        "/bin/sh",
        ["-c", `command -v ${shellQuote(command)} >/dev/null 2>&1`],
        process.cwd(),
        [0, 1, 127],
    );
    return result.code === 0;
}

function sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

function runClipboardCommand(
    file: string,
    args: string[],
    input: string,
    waitForExit = false,
): Promise<void> {
    return new Promise((resolve, reject) => {
        const child = spawn(file, args, {
            stdio: ["pipe", "ignore", "pipe"],
        });
        let stderr = "";
        let settled = false;
        let settleTimer: NodeJS.Timeout | undefined;

        const settle = (error?: Error) => {
            if (settled) return;
            settled = true;
            if (settleTimer) clearTimeout(settleTimer);
            child.stderr.destroy();
            child.unref();
            if (error) reject(error);
            else resolve();
        };

        child.stderr.on("data", (chunk) => {
            stderr += String(chunk);
        });
        child.on("error", settle);
        child.on("close", (code) => {
            if (code === 0) settle();
            else
                settle(
                    new Error(
                        stderr.trim() || `${file} exited with code ${code}`,
                    ),
                );
        });

        child.stdin.end(input, () => {
            if (waitForExit) return;
            // Wayland/X11 clipboard tools often stay alive to serve future paste
            // requests. Once stdin is accepted, continue with Ghostty automation
            // instead of waiting forever for the clipboard owner to exit.
            settleTimer = setTimeout(() => settle(), 200);
        });
    });
}

async function copyToClipboard(text: string): Promise<void> {
    if (process.platform === "darwin") {
        // pbcopy exits once it has read stdin, so wait for its real result.
        await runClipboardCommand("pbcopy", [], text, true);
        return;
    }
    if (await commandExists("wl-copy")) {
        await runClipboardCommand("wl-copy", [], text);
        return;
    }

    throw new Error("wl-copy is required for clipboard support on Linux");
}

async function sendHyprlandShortcut(shortcut: string): Promise<void> {
    await runCapture(
        "hyprctl",
        ["dispatch", "sendshortcut", `${shortcut},activewindow`],
        process.cwd(),
    );
}

async function openInGhosttyLinux(wrapperPath: string): Promise<void> {
    if (!(await commandExists("hyprctl"))) {
        throw new Error(
            "opening a Ghostty pane on Linux currently requires Hyprland's hyprctl",
        );
    }

    // Match the configured alt+shift+v (split right) and alt+shift+p (paste)
    // bindings. Replacing the pane's shell closes it when the wrapper exits.
    const command = `exec /bin/sh ${shellQuote(wrapperPath)}`;
    await copyToClipboard(command);

    await sendHyprlandShortcut("ALT SHIFT,V");
    await sleep(400);
    await sendHyprlandShortcut("ALT SHIFT,P");
    await sleep(100);
    await sendHyprlandShortcut(",Return");
}

export default function ghSummaryExtension(pi: ExtensionAPI) {
    // Drafts still open in an editor pane, each waiting to update its PR.
    const watchers = new Set<AbortController>();
    pi.on("session_shutdown", () => {
        for (const watcher of watchers) watcher.abort();
        watchers.clear();
    });

    // Notifications are transient, so record the PR link in the session
    // transcript as a displayed custom message. It does not start a turn.
    const printPrLink = (action: string, pr: PullRequest) => {
        pi.sendMessage({
            customType: "gh-summary",
            content: `${action}: ${pr.url}`,
            display: true,
            details: pr,
        });
    };

    // Runs in the background after the command returns: once nvim exits,
    // push the final draft to GitHub by editing the existing PR or opening a
    // draft one. When GitHub cannot be updated (e.g. on the base branch), copy
    // the draft to the clipboard for manual use instead. Quitting with a
    // nonzero status (`:cq`) or emptying the draft skips it.
    const syncOnClose = async (
        ctx: ExtensionCommandContext,
        changes: GitChanges,
        target: PrTarget,
        directory: string,
        draftPath: string,
    ) => {
        const controller = new AbortController();
        watchers.add(controller);
        const skipped =
            target.kind === "edit"
                ? `PR #${target.pr.number} was not updated`
                : target.kind === "create"
                  ? "no PR was created"
                  : "nothing was copied";
        let closed: ClosedDraft | undefined;
        try {
            closed = await waitForDraftClose(
                directory,
                draftPath,
                controller.signal,
            );
            if (controller.signal.aborted) return;
            if (!closed) {
                ctx.ui.notify(
                    `PR draft closed without a clean nvim exit; ${skipped}`,
                    "warning",
                );
                return;
            }
            if (closed.status !== 0) {
                ctx.ui.notify(
                    `nvim exited with status ${closed.status}; ${skipped}`,
                    "info",
                );
                return;
            }
            const draft = parseDraft(closed.markdown);
            if (!draft.title && !draft.body) {
                ctx.ui.notify(`PR draft was empty; ${skipped}`, "info");
                return;
            }
            if (target.kind === "none") {
                // Copy the buffer verbatim, including its "Title:" line.
                await copyToClipboard(normalizeQuotes(closed.markdown));
                ctx.ui.notify("Copied the PR draft to the clipboard", "info");
                return;
            }
            if (target.kind === "edit") {
                await updatePullRequest(changes.root, target.pr, draft);
                printPrLink(`Updated PR #${target.pr.number}`, target.pr);
                return;
            }
            if (!draft.title) {
                ctx.ui.notify(
                    `PR draft has no "Title:" line; ${skipped}`,
                    "warning",
                );
                if (ctx.hasUI) ctx.ui.setEditorText(closed.markdown);
                return;
            }
            const pr = await createPullRequest(changes, target.branch, {
                title: draft.title,
                body: draft.body,
            });
            printPrLink(`Opened draft PR #${pr.number}`, pr);
        } catch (error) {
            ctx.ui.notify(
                `Failed to ${target.kind === "edit" ? `update ${target.pr.url}` : target.kind === "create" ? "open a PR" : "copy the PR draft"}: ${(error as Error).message}`,
                "error",
            );
            // The wrapper deletes the draft after handoff; keep the edited
            // Markdown recoverable in pi's input.
            if (closed && ctx.hasUI) ctx.ui.setEditorText(closed.markdown);
        } finally {
            watchers.delete(controller);
        }
    };

    pi.registerCommand("gh-summary", {
        description:
            "Create a GitHub-ready PR title/description from git changes and open it in a right-hand Ghostty/neovim pane. Usage: /gh-summary [--repo <path>] [extra context]",
        handler: async (args, ctx) => {
            if (!ctx.model) {
                ctx.ui.notify("No model selected", "error");
                return;
            }

            const runEditor = async (file: string, argv: string[]) => {
                const result = await pi.exec(file, argv, { timeout: 30_000 });
                if (result.code !== 0 || result.killed) {
                    throw new Error(
                        result.stderr.trim() || `${file} failed or timed out`,
                    );
                }
                return result.stdout;
            };
            let editor: Awaited<ReturnType<typeof checkEditor>> | undefined;
            try {
                // Snapshot the source pane before inspecting git or generating
                // text, so later focus changes cannot redirect the macOS split.
                if (process.platform === "darwin")
                    editor = await checkEditor(runEditor);
                else if (process.platform !== "linux") {
                    throw new Error(
                        `Unsupported platform: ${process.platform}`,
                    );
                }
            } catch (error) {
                ctx.ui.notify(
                    `Cannot prepare Ghostty/neovim: ${(error as Error).message}`,
                    "error",
                );
                return;
            }

            const { repo, extraContext } = parseArgs(args ?? "");
            // Resolve the target repo relative to pi's cwd so `--repo` can point
            // at a sibling checkout (e.g. running /gh-summary from a config repo
            // to summarize changes made in another repository).
            const targetCwd = repo ? path.resolve(ctx.cwd, repo) : ctx.cwd;

            if (repo) {
                try {
                    const dirStat = await stat(targetCwd);
                    if (!dirStat.isDirectory()) {
                        throw new Error("path is not a directory");
                    }
                } catch (error) {
                    ctx.ui.notify(
                        `Invalid --repo ${targetCwd}: ${(error as Error).message}`,
                        "error",
                    );
                    return;
                }
            }

            let changes: GitChanges;
            let targetLookup: Promise<PrTarget>;
            const model = ctx.model;
            try {
                changes = await collectGitChanges(targetCwd);
                // Look up the PR while the model generates the summary.
                targetLookup = resolvePrTarget(changes);
            } catch (error) {
                ctx.ui.notify(
                    `Failed to inspect git changes: ${(error as Error).message}`,
                    "error",
                );
                return;
            }

            if (!changes.text.trim()) {
                ctx.ui.notify(
                    "No git worktree changes or current-branch commits found",
                    "warning",
                );
                return;
            }

            ctx.ui.notify(
                `Generating PR summary from ${changes.source === "worktree" ? "git worktree" : "current branch commits"}...`,
                "info",
            );

            let summary = "";
            let prTemplate: string | undefined;
            let conversationContext = "";
            try {
                prTemplate = await readPrTemplate(changes.root);
                conversationContext = buildConversationContext(
                    ctx.sessionManager.getBranch() as SessionEntry[],
                );
                const userMessage: UserMessage = {
                    role: "user",
                    content: [
                        {
                            type: "text",
                            text: buildUserPrompt(
                                changes.text,
                                changes.source,
                                extraContext,
                                conversationContext,
                                prTemplate,
                            ),
                        },
                    ],
                    timestamp: Date.now(),
                };

                // Go through ModelRegistry rather than pi-ai's compatibility
                // helper so custom providers, resolved auth/base URLs, and
                // provider-specific request behavior are all preserved.
                // Newer reasoning-only models reject an omitted/off effort;
                // preserve the session level while clamping its lowest values.
                const reasoningEffort =
                    ctx.thinkingLevel === "off" ||
                    ctx.thinkingLevel === "minimal"
                        ? "low"
                        : ctx.thinkingLevel;
                const response = await ctx.modelRegistry.complete(
                    model,
                    { systemPrompt: SYSTEM_PROMPT, messages: [userMessage] },
                    {
                        cacheRetention: "none",
                        reasoningEffort,
                    },
                );

                if (response.stopReason === "aborted") {
                    ctx.ui.notify("PR summary generation cancelled", "info");
                    return;
                }
                if (response.stopReason === "error") {
                    throw new Error(
                        response.errorMessage || "Model request failed",
                    );
                }

                summary = normalizeQuotes(
                    stripWrappingCodeFence(textFromResponse(response)),
                );

                if (!summary.trim()) {
                    throw new Error(
                        `Model returned no text (stop reason: ${response.stopReason})`,
                    );
                }
            } catch (error) {
                ctx.ui.notify(
                    `Failed to generate PR summary: ${(error as Error).message}`,
                    "error",
                );
                return;
            }

            const target = await targetLookup;
            let tmpDir: string | undefined;
            try {
                let summaryPath: string;
                if (editor) {
                    // Use the native split, stable-ID closure, private
                    // Markdown buffer, and deletion on every nvim exit.
                    const draft = await saveDraft(
                        summary,
                        editor.nvim,
                        os.tmpdir(),
                        "pr-description",
                        // Every PR target acts on the final draft.
                        true,
                    );
                    tmpDir = draft.directory;
                    summaryPath = draft.draftPath;
                    await openDraft(
                        runEditor,
                        draft.wrapperPath,
                        draft.directory,
                        editor.terminalId,
                    );
                } else {
                    tmpDir = await mkdtemp(
                        path.join(os.tmpdir(), "gh-summary-"),
                    );
                    summaryPath = path.join(tmpDir, "pr-description.md");
                    const nvimScriptPath = path.join(
                        tmpDir,
                        "gh-summary.nvim.vim",
                    );
                    const wrapperPath = path.join(tmpDir, "open-gh-summary.sh");
                    await writeFile(summaryPath, summary, { mode: 0o600 });
                    await writeFile(nvimScriptPath, nvimScript(summaryPath), {
                        mode: 0o600,
                    });
                    await writeFile(
                        wrapperPath,
                        wrapperScript(nvimScriptPath, tmpDir),
                        { mode: 0o700 },
                    );
                    await openInGhosttyLinux(wrapperPath);
                }
                ctx.ui.notify(
                    `Opened PR summary in a right-hand Ghostty/neovim pane: ${summaryPath}`,
                    "info",
                );
                const action =
                    target.kind === "edit"
                        ? `updates PR #${target.pr.number} (${target.pr.url})`
                        : target.kind === "create"
                          ? `${changes.source === "worktree" ? "commits the worktree changes, " : ""}pushes ${target.branch} to origin and opens a draft PR`
                          : `copies the draft to the clipboard (GitHub will not be updated: ${target.reason})`;
                ctx.ui.notify(
                    `Closing nvim ${action}; use :cq to skip`,
                    "info",
                );
                void syncOnClose(ctx, changes, target, tmpDir, summaryPath);
            } catch (error) {
                ctx.ui.notify(
                    `Failed to open Ghostty/neovim: ${(error as Error).message}`,
                    "error",
                );
                if (ctx.hasUI) ctx.ui.setEditorText(summary);
                // No editor took ownership: remove the draft here, retaining
                // the generated Markdown only in pi's input for recovery.
                if (tmpDir) {
                    try {
                        await rm(tmpDir, { recursive: true, force: true });
                    } catch (cleanupError) {
                        ctx.ui.notify(
                            `Failed to delete ${tmpDir}: ${String(cleanupError)}`,
                            "error",
                        );
                    }
                }
            }
        },
    });
}
