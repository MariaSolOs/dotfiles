import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import {
    mkdtemp,
    readFile,
    readdir,
    rm,
    stat,
    writeFile,
} from "node:fs/promises";
import path from "node:path";
import { test } from "node:test";
import { promisify } from "node:util";
import {
    initTheme,
    type ExtensionAPI,
    type ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent";
import {
    checkEditor,
    openDraft,
    saveDraft,
    OPEN_PANE_SCRIPT,
    CLOSE_PANE_SCRIPT,
    SOURCE_PANE_SCRIPT,
} from "./editor.js";
import {
    collectContext,
    commandRunner,
    parseLink,
    type Run,
} from "./github.js";
import replyExtension, { rawMarkdown } from "./index.js";

const exec = promisify(execFile);
const base = "repos/owner/repo";
const url = "https://github.com/owner/repo/pull/42";

function fixture(extra: Record<string, unknown> = {}, isPr = true) {
    const responses: Record<string, unknown> = {
        [`${base}/issues/42`]: {
            id: 42,
            title: "Fix a race",
            body: "Parent body",
            pull_request: isPr ? {} : undefined,
        },
        [`${base}/issues/42/comments?per_page=100&page=1`]: [],
        [`${base}/pulls/42`]: {
            id: 42,
            base: { ref: "main" },
            head: { ref: "fix" },
        },
        [`${base}/pulls/42/reviews?per_page=100&page=1`]: [],
        [`${base}/pulls/42/comments?per_page=100&page=1`]: [],
        [`${base}/pulls/42/files?per_page=100&page=1`]: [
            {
                filename: "race.ts",
                status: "modified",
                patch: "-before\n+after",
            },
        ],
        ...extra,
    };
    const calls: string[][] = [];
    const run: Run = async (file, args) => {
        assert.equal(file, "gh");
        assert.equal(args[args.indexOf("--method") + 1], "GET");
        calls.push(args);
        const endpoint = args.at(-1)!;
        assert.ok(endpoint in responses, `Unexpected endpoint: ${endpoint}`);
        return JSON.stringify(responses[endpoint]);
    };
    return { run, calls };
}

test("parses issue, PR, enterprise, and supported comment anchors", () => {
    assert.equal(parseLink(url).number, "42");
    assert.equal(
        parseLink("https://github.palantir.build/team/project/issues/1").host,
        "github.palantir.build",
    );
    assert.deepEqual(parseLink(`${url}#issuecomment-12`).target, {
        kind: "comment",
        id: "12",
    });
    assert.deepEqual(
        parseLink(`${url}/files?diff=split#discussion_r13`).target,
        { kind: "review-comment", id: "13" },
    );
    assert.deepEqual(parseLink(`${url}#pullrequestreview-14`).target, {
        kind: "review",
        id: "14",
    });
    assert.equal(parseLink(`${url}#issue-123`).target, undefined);
});

test("rejects invalid URLs rather than drafting for the wrong destination", () => {
    for (const value of [
        "",
        "owner/repo#1",
        "http://github.com/owner/repo/issues/1",
        "https://user:pass@github.com/owner/repo/issues/1",
        "https://github.com/owner/repo",
        `${url}#diff-abc`,
        `${url}#issuecomment-nope`,
        "https://github.com/owner/repo/issues/1#discussion_r2",
        "https://github.com/owner/repo/issues/0",
    ]) {
        assert.throws(() => parseLink(value), Error, value);
    }
});

test("collects an issue without PR endpoints", async () => {
    const { run, calls } = fixture({}, false);
    const context = await collectContext(
        parseLink(url.replace("pull", "issues")),
        run,
    );
    assert.match(context, /Parent body/);
    assert.equal(calls.length, 2);
});

test("fetches linked comments directly and paginates the conversation", async () => {
    const { run, calls } = fixture({
        [`${base}/issues/comments/12`]: {
            id: 12,
            body: "The exact target",
            issue_url: "https://api.github.com/repos/owner/repo/issues/42",
        },
        [`${base}/issues/42/comments?per_page=100&page=1`]: Array.from(
            { length: 100 },
            (_, id) => ({ id, body: `Comment ${id}` }),
        ),
        [`${base}/issues/42/comments?per_page=100&page=2`]: [
            { id: 101, body: "Next page" },
        ],
    });
    const context = await collectContext(
        parseLink(`${url}#issuecomment-12`),
        run,
    );
    assert.match(context, /The exact target/);
    assert.match(context, /Next page/);
    assert.match(context, /race.ts/);
    assert.ok(calls.some((args) => args.at(-1)?.endsWith("page=2")));
});

test("includes the linked inline review thread and diff hunk", async () => {
    const target = {
        id: 13,
        body: "Can we avoid this race?",
        in_reply_to_id: 10,
        pull_request_url: "https://api.github.com/repos/owner/repo/pulls/42",
        diff_hunk: "@@ -1 +1 @@\n+await lock()",
    };
    const { run } = fixture({
        [`${base}/pulls/comments/13`]: target,
        [`${base}/pulls/42/comments?per_page=100&page=1`]: [
            { id: 10, body: "Thread root" },
            target,
            { id: 14, in_reply_to_id: 10, body: "Thread reply" },
        ],
    });
    const context = await collectContext(
        parseLink(`${url}/files#discussion_r13`),
        run,
    );
    assert.match(context, /Reply specifically to this review-comment/);
    assert.match(context, /Linked review thread/);
    assert.match(context, /Thread root/);
    assert.match(context, /Thread reply/);
    assert.match(context, /await lock/);
});

test("includes comments belonging to a linked top-level review", async () => {
    const { run } = fixture({
        [`${base}/pulls/42/reviews/14`]: {
            id: 14,
            body: "Please revise",
            state: "CHANGES_REQUESTED",
        },
        [`${base}/pulls/42/reviews/14/comments?per_page=100&page=1`]: [
            { id: 15, body: "Specific review concern" },
        ],
    });
    const context = await collectContext(
        parseLink(`${url}#pullrequestreview-14`),
        run,
    );
    assert.match(context, /Please revise/);
    assert.match(context, /Specific review concern/);
});

test("rejects a comment from a different issue", async () => {
    const { run } = fixture({
        [`${base}/issues/comments/12`]: {
            id: 12,
            issue_url: "https://api.github.com/repos/owner/repo/issues/99",
        },
    });
    await assert.rejects(
        collectContext(parseLink(`${url}#issuecomment-12`), run),
        /does not belong/,
    );
});

test("propagates API failures instead of inventing missing context", async () => {
    await assert.rejects(
        collectContext(parseLink(url), async () => {
            throw new Error("authentication failed");
        }),
        /authentication failed/,
    );
});

test("bounds context and retains the explicit target", async () => {
    const { run } = fixture({
        [`${base}/issues/comments/12`]: {
            id: 12,
            body: "TARGET " + "x".repeat(100_000),
            issue_url: "https://api.github.com/repos/owner/repo/issues/42",
        },
        [`${base}/issues/42/comments?per_page=100&page=1`]: Array.from(
            { length: 90 },
            (_, id) => ({ id, body: "y".repeat(100_000) }),
        ),
    });
    const context = await collectContext(
        parseLink(`${url}#issuecomment-12`),
        run,
    );
    assert.ok(context.length < 100_000);
    assert.match(context, /TARGET/);
    assert.match(context, /truncated/);
    assert.match(context, /most recent retained/);
});

test("strips enclosing Markdown fences without removing internal code blocks", () => {
    assert.equal(
        rawMarkdown("```markdown\nHello **there**\n```"),
        "Hello **there**\n",
    );
    assert.equal(rawMarkdown("~~~md\nHello\n~~~"), "Hello\n");
    assert.equal(
        rawMarkdown("Try this:\n\n```ts\nfoo()\n```"),
        "Try this:\n\n```ts\nfoo()\n```\n",
    );
    assert.throws(() => rawMarkdown("  "), /empty reply/);
});

test("command runner handles errors, timeouts, and cancellation", async () => {
    const controller = new AbortController();
    const pi = {
        exec: async () => ({
            code: 1,
            stderr: "No access",
            stdout: "",
            killed: false,
        }),
    } as unknown as ExtensionAPI;
    await assert.rejects(
        commandRunner(pi, controller.signal)("gh", []),
        /No access/,
    );
    const timedOut = {
        exec: async () => ({ code: 0, stderr: "", stdout: "", killed: true }),
    } as unknown as ExtensionAPI;
    await assert.rejects(
        commandRunner(timedOut, controller.signal)("gh", []),
        /timed out/,
    );
    controller.abort();
    await assert.rejects(
        commandRunner(pi, controller.signal)("gh", []),
        /abort/i,
    );
});

test("saves private raw Markdown and quotes paths safely in the launch scripts", async () => {
    const root = await mkdtemp(
        path.join(process.cwd(), ".reply-test-'quoted-"),
    );
    try {
        const fakeNvim = path.join(root, "fake 'nvim'");
        await writeFile(fakeNvim, '#!/bin/sh\nprintf "%s\\n" "$@"\n', {
            mode: 0o700,
        });
        const draft = await saveDraft("Raw **Markdown**\n", fakeNvim, root);
        assert.equal(
            await readFile(draft.draftPath, "utf8"),
            "Raw **Markdown**\n",
        );
        assert.equal((await stat(draft.draftPath)).mode & 0o777, 0o600);
        const script = await readFile(
            path.join(draft.directory, "reply.vim"),
            "utf8",
        );
        assert.match(script, /set nomodeline noexrc/);
        assert.match(script, /conceallevel=0/);
        assert.ok(script.includes(draft.draftPath.replace(/'/g, "''")));
        assert.match(script, /noundofile/);
        assert.match(script, /nobackup nowritebackup/);
        const output = await exec("/bin/sh", [draft.wrapperPath]);
        assert.deepEqual(output.stdout.trim().split("\n"), [
            "-n",
            "-i",
            "NONE",
            "-S",
            path.join(draft.directory, "reply.vim"),
        ]);
        await assert.rejects(stat(draft.directory), { code: "ENOENT" });
    } finally {
        await rm(root, { recursive: true, force: true });
    }
});

test("cleans up on editor failure and pane hangup, preserving exit status", async () => {
    const root = await mkdtemp(
        path.join(process.cwd(), ".reply-cleanup-test-"),
    );
    try {
        const fakeNvim = path.join(root, "fake-nvim");
        for (const [command, code] of [
            ["exit 42", 42],
            ['kill -HUP "$PPID"; exit 0', 129],
        ] as const) {
            await writeFile(fakeNvim, `#!/bin/sh\n${command}\n`, {
                mode: 0o700,
            });
            const draft = await saveDraft("Draft\n", fakeNvim, root);
            await assert.rejects(exec("/bin/sh", [draft.wrapperPath]), {
                code,
            });
            await assert.rejects(stat(draft.directory), { code: "ENOENT" });
        }
    } finally {
        await rm(root, { recursive: true, force: true });
    }
});

test("captures the source pane before generation", async () => {
    const calls: string[] = [];
    const editor = await checkEditor(async (file, args) => {
        calls.push(file);
        if (file === "/usr/bin/osascript") {
            assert.equal(args[1], SOURCE_PANE_SCRIPT);
            return "source-pane-id\n";
        }
        return "/fake/nvim\n";
    });
    assert.deepEqual(editor, {
        nvim: "/fake/nvim",
        terminalId: "source-pane-id",
    });
    assert.equal(calls[0], "/usr/bin/osascript");
    await assert.rejects(
        checkEditor(async () => ""),
        /No focused Ghostty pane/,
    );
});

test("splits the source pane and hands only the reply pane ID to cleanup", async () => {
    const root = await mkdtemp(path.join(process.cwd(), ".reply-pane-test-"));
    let calls = 0;
    try {
        await openDraft(
            async (file, args) => {
                calls++;
                assert.equal(file, "/usr/bin/osascript");
                assert.equal(args[1], OPEN_PANE_SCRIPT);
                assert.match(
                    args[1],
                    /split sourceTerminal direction right with configuration/,
                );
                assert.match(args[1], /first terminal whose id is sourceId/);
                assert.match(args[1], /return id of replyTerminal/);
                assert.equal(args[5], "source-pane-id");
                assert.ok(!args[1].includes("front window"));
                assert.ok(!args[1].includes("new window"));
                assert.ok(!args[1].includes("new tab"));
                assert.ok(!args[1].includes("System Events"));
                assert.ok(!args[1].includes("untrusted"));
                assert.match(args[2], /untrusted/);
                assert.match(args[2], /--close-pane$/);
                return "reply-pane-id\n";
            },
            "/some 'untrusted'/open.sh",
            root,
            "source-pane-id",
        );
        assert.equal(calls, 1);
        assert.equal(
            await readFile(path.join(root, "pane-id"), "utf8"),
            "reply-pane-id\n",
        );
        assert.equal(
            (await stat(path.join(root, "pane-id"))).mode & 0o777,
            0o600,
        );
        assert.match(
            CLOSE_PANE_SCRIPT,
            /close \(first terminal whose id is replyId\)/,
        );
        assert.ok(!CLOSE_PANE_SCRIPT.includes("close window"));
        assert.ok(!CLOSE_PANE_SCRIPT.includes("front window"));
    } finally {
        await rm(root, { recursive: true, force: true });
    }
});

test("never hands the Pi pane ID or an empty ID to cleanup", async () => {
    for (const replyId of ["", "source-pane-id"]) {
        await assert.rejects(
            openDraft(
                async () => replyId,
                "/unused/open.sh",
                "/unused",
                "source-pane-id",
            ),
            /distinct reply pane ID/,
        );
    }
});

test("registers /reply and validates input before starting generation", async () => {
    let handler!: (args: string, ctx: ExtensionCommandContext) => Promise<void>;
    const notices: string[] = [];
    replyExtension({
        on() {},
        registerCommand(name: string, definition: { handler: typeof handler }) {
            assert.equal(name, "reply");
            handler = definition.handler;
        },
    } as unknown as ExtensionAPI);
    const ctx = {
        mode: "tui",
        model: {},
        ui: { notify: (text: string) => notices.push(text) },
    } as unknown as ExtensionCommandContext;
    await handler("", ctx);
    await handler("not-a-url", ctx);
    assert.match(notices[0], /Usage/);
    assert.match(notices[1], /full GitHub/);
});

test("command generates via the selected model and deletes the draft on launch failure", async () => {
    initTheme("dark", false);
    const root = await mkdtemp(
        path.join(process.cwd(), ".reply-command-test-"),
    );
    const previousTmp = process.env.TMPDIR;
    process.env.TMPDIR = root;
    try {
        for (const failLaunch of [false, true]) {
            let handler!: (
                args: string,
                ctx: ExtensionCommandContext,
            ) => Promise<void>;
            const notices: string[] = [];
            const { run } = fixture({}, false);
            const pi = {
                on() {},
                registerCommand(
                    _name: string,
                    definition: { handler: typeof handler },
                ) {
                    handler = definition.handler;
                },
                async exec(file: string, args: string[]) {
                    let stdout = "";
                    if (file === "gh") stdout = await run(file, args);
                    else if (file === "/bin/sh") stdout = "/fake/nvim\n";
                    else if (args[1] === SOURCE_PANE_SCRIPT)
                        stdout = "source-pane-id\n";
                    else if (args[1] === OPEN_PANE_SCRIPT) {
                        assert.equal(args[5], "source-pane-id");
                        if (failLaunch) throw new Error("Launch failed");
                        stdout = "reply-pane-id\n";
                    }
                    return { stdout, stderr: "", code: 0, killed: false };
                },
            } as unknown as ExtensionAPI;
            replyExtension(pi);
            const model = { id: "test-model" };
            let modelCalls = 0;
            const ctx = {
                mode: "tui",
                model,
                thinkingLevel: "off",
                sessionManager: { getBranch: () => [] },
                modelRegistry: {
                    complete: async (
                        selected: unknown,
                        context: {
                            messages: { content: { text: string }[] }[];
                            tools?: unknown;
                        },
                        options: {
                            reasoningEffort: string;
                            signal: AbortSignal;
                        },
                    ) => {
                        modelCalls++;
                        assert.equal(selected, model);
                        assert.equal(context.tools, undefined);
                        assert.equal(options.reasoningEffort, "low");
                        assert.ok(!options.signal.aborted);
                        assert.equal(
                            JSON.parse(context.messages[0].content[0].text)
                                .userGuidance,
                            "Ask for a reproduction",
                        );
                        return {
                            stopReason: "stop",
                            content: [
                                {
                                    type: "text",
                                    text: "```md\nCould you share a reproduction?\n```",
                                },
                            ],
                        };
                    },
                },
                ui: {
                    notify: (text: string) => notices.push(text),
                    custom: (
                        factory: (
                            tui: unknown,
                            theme: unknown,
                            kb: unknown,
                            done: (value: unknown) => void,
                        ) => { dispose: () => void },
                    ) =>
                        new Promise((resolve) => {
                            const loader = factory(
                                { requestRender() {} },
                                { fg: (_color: string, text: string) => text },
                                {},
                                (value) => {
                                    loader.dispose();
                                    resolve(value);
                                },
                            );
                        }),
                },
            } as unknown as ExtensionCommandContext;
            await handler(
                `${url.replace("pull", "issues")} Ask for a reproduction`,
                ctx,
            );
            assert.equal(modelCalls, 1);
            const notice = notices.at(-1)!;
            assert.match(
                notice,
                failLaunch ? /Reply failed: Launch failed/ : /Nothing posted/,
            );
            if (!failLaunch) {
                assert.match(
                    notice,
                    /deleted when nvim exits \(including :wq\)/,
                );
                const draftPath = notice.slice(notice.lastIndexOf(": ") + 2);
                assert.equal(
                    await readFile(draftPath, "utf8"),
                    "Could you share a reproduction?\n",
                );
                // The mocked launch never runs the shell cleanup.
                await rm(path.dirname(draftPath), { recursive: true });
            }
            assert.deepEqual(await readdir(root), []);
        }
    } finally {
        if (previousTmp === undefined) delete process.env.TMPDIR;
        else process.env.TMPDIR = previousTmp;
        await rm(root, { recursive: true, force: true });
    }
});
