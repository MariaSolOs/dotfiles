import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import {
    mkdtemp,
    mkdir,
    readFile,
    readdir,
    rm,
    writeFile,
} from "node:fs/promises";
import path from "node:path";
import { test } from "node:test";
import { promisify } from "node:util";
import type {
    ExtensionAPI,
    ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent";
import { OPEN_PANE_SCRIPT, SOURCE_PANE_SCRIPT } from "./editor.js";
import ghSummaryExtension from "./index.js";

const exec = promisify(execFile);
const markdown = "Title: Fix the race\n\nRemoving the race condition.\n";
const curlyMarkdown =
    "Title: Fix the worker\u2019s \u201crace\u201d\n\n" +
    "Removing \u2018stale\u2019 state while keeping 'ASCII' and \"quotes\", caf\u00e9, and \u2192.\n";
const normalizedMarkdown =
    'Title: Fix the worker\'s "race"\n\n' +
    "Removing 'stale' state while keeping 'ASCII' and \"quotes\", caf\u00e9, and \u2192.\n";

async function fixture() {
    const root = await mkdtemp(path.join(process.cwd(), ".gh-summary-test-"));
    const bin = path.join(root, "bin");
    const drafts = path.join(root, "drafts");
    await mkdir(bin);
    await mkdir(drafts);
    const previousPath = process.env.PATH;
    const previousTmp = process.env.TMPDIR;
    // This is a stub executable, not a repository: tests never invoke real git
    // or inspect/mutate the user's special bare/sparse configuration checkout.
    await writeFile(
        path.join(bin, "git"),
        `#!/bin/sh
case "$1" in
  rev-parse)
    case "$2" in
      --show-toplevel) printf '%s\\n' "$PWD" ;;
      --short) printf 'abc123\\n' ;;
      --verify) exit 1 ;;
      *) exit 128 ;;
    esac ;;
  branch)
    if [ -f '${root}/branch' ]; then /bin/cat '${root}/branch'
    else printf 'feature\\n'; fi ;;
  status) printf ' M changed.ts\\n' ;;
  add|commit|push) printf '%s\\n' "$*" >> '${root}/git-writes' ;;
  diff) printf '%s\\n' 'diff --git a/changed.ts b/changed.ts' '+fixRace()' ;;
  ls-files) exit 0 ;;
  *) exit 1 ;;
esac
`,
        { mode: 0o700 },
    );
    // Stub gh: `pr view` reports the PR in pr.json when present; `pr edit` and
    // `pr create` record their argv and stdin body for assertions.
    await writeFile(
        path.join(bin, "gh"),
        `#!/bin/sh
case "$1 $2" in
  "pr view")
    if [ -f '${root}/pr.json' ]; then /bin/cat '${root}/pr.json'
    else echo 'no pull requests found for branch "feature"' >&2; exit 1; fi ;;
  "pr create")
    printf '%s\\n' "$@" > '${root}/gh-create-args'
    /bin/cat > '${root}/gh-create-body'
    printf 'https://github.com/o/r/pull/8\\n' ;;
  "pr edit")
    printf '%s\\n' "$@" > '${root}/gh-edit-args'
    /bin/cat > '${root}/gh-edit-body' ;;
  *) exit 1 ;;
esac
`,
        { mode: 0o700 },
    );
    process.env.PATH = `${bin}:${previousPath}`;
    process.env.TMPDIR = drafts;
    return {
        root,
        bin,
        drafts,
        async dispose() {
            if (previousPath === undefined) delete process.env.PATH;
            else process.env.PATH = previousPath;
            if (previousTmp === undefined) delete process.env.TMPDIR;
            else process.env.TMPDIR = previousTmp;
            await rm(root, { recursive: true, force: true });
        },
    };
}

function harness(
    cwd: string,
    failure?: "prepare" | "model" | "launch",
    responseMarkdown = markdown,
    nvimPath = "/fake/nvim",
) {
    const notices: string[] = [];
    const editorTexts: string[] = [];
    let handler!: (args: string, ctx: ExtensionCommandContext) => Promise<void>;
    let modelCalls = 0;
    let captured = false;
    let launched = false;
    const pi = {
        on() {},
        registerCommand(name: string, definition: { handler: typeof handler }) {
            assert.equal(name, "gh-summary");
            handler = definition.handler;
        },
        async exec(file: string, args: string[]) {
            let stdout = "";
            if (args[1] === SOURCE_PANE_SCRIPT) {
                assert.equal(modelCalls, 0);
                if (failure === "prepare") throw new Error("No Ghostty pane");
                captured = true;
                stdout = "pi-pane-id\n";
            } else if (file === "/bin/sh") {
                stdout = `${nvimPath}\n`;
            } else {
                assert.equal(args[1], OPEN_PANE_SCRIPT);
                assert.equal(modelCalls, 1);
                // Generation may change focus; the captured source ID is used.
                assert.equal(args[5], "pi-pane-id");
                assert.match(args[2], /--close-pane$/);
                if (failure === "launch") throw new Error("Split failed");
                launched = true;
                stdout = "summary-pane-id\n";
            }
            return { stdout, stderr: "", code: 0, killed: false };
        },
    } as unknown as ExtensionAPI;
    const model = { id: "test-model" };
    const ctx = {
        cwd,
        model,
        hasUI: true,
        thinkingLevel: "off",
        sessionManager: { getBranch: () => [] },
        modelRegistry: {
            complete: async (
                selected: unknown,
                context: {
                    systemPrompt: string;
                    messages: { content: { text: string }[] }[];
                },
            ) => {
                modelCalls++;
                if (process.platform === "darwin") assert.ok(captured);
                assert.equal(selected, model);
                assert.match(
                    context.systemPrompt,
                    /ASCII apostrophes.*U\+0027/,
                );
                assert.match(context.systemPrompt, /double quotes.*U\+0022/);
                assert.match(context.messages[0].content[0].text, /fixRace/);
                if (failure === "model") throw new Error("Model failed");
                return {
                    stopReason: "stop",
                    content: [
                        {
                            type: "text",
                            text: `\`\`\`markdown\n${responseMarkdown}\`\`\``,
                        },
                    ],
                };
            },
        },
        ui: {
            notify: (text: string) => notices.push(text),
            setEditorText: (text: string) => editorTexts.push(text),
        },
    } as unknown as ExtensionCommandContext;
    ghSummaryExtension(pi);
    return {
        run: () => handler("Keep it concise", ctx),
        notices,
        editorTexts,
        get modelCalls() {
            return modelCalls;
        },
        get launched() {
            return launched;
        },
    };
}

test("gh-summary uses the right-pane lifecycle with its own Markdown filename", async () => {
    const f = await fixture();
    try {
        const h = harness(f.root);
        await h.run();
        assert.ok(h.launched);
        assert.equal(h.modelCalls, 1);
        const entries = await readdir(f.drafts);
        assert.equal(entries.length, 1);
        const directory = path.join(f.drafts, entries[0]);
        assert.equal(
            await readFile(path.join(directory, "pr-description.md"), "utf8"),
            markdown,
        );
        assert.equal(
            await readFile(path.join(directory, "pane-id"), "utf8"),
            "summary-pane-id\n",
        );
        const wrapper = await readFile(
            path.join(directory, "open-pr-description.sh"),
            "utf8",
        );
        assert.match(wrapper, /trap cleanup 0/);
        assert.match(wrapper, /close \(first terminal whose id is replyId\)/);
        assert.ok(!wrapper.includes("System Events"));
        assert.match(wrapper, /exit-status/);
        assert.ok(
            h.notices.some((n) => /right-hand Ghostty\/neovim pane/.test(n)),
        );
        assert.match(h.notices.at(-1)!, /opens a draft PR/);
        assert.deepEqual(h.editorTexts, []);
    } finally {
        await f.dispose();
    }
});

test("normalizes curly quotes in saved drafts and editor recovery without changing other Unicode", async () => {
    for (const failure of [undefined, "launch"] as const) {
        const f = await fixture();
        try {
            const h = harness(f.root, failure, curlyMarkdown);
            await h.run();
            if (failure === "launch") {
                assert.deepEqual(h.editorTexts, [normalizedMarkdown]);
                assert.deepEqual(await readdir(f.drafts), []);
            } else {
                assert.ok(h.launched);
                const entries = await readdir(f.drafts);
                assert.equal(entries.length, 1);
                assert.equal(
                    await readFile(
                        path.join(f.drafts, entries[0], "pr-description.md"),
                        "utf8",
                    ),
                    normalizedMarkdown,
                );
            }
        } finally {
            await f.dispose();
        }
    }
});

test("preflight and model failures leave no summary files", async () => {
    const f = await fixture();
    try {
        for (const failure of ["prepare", "model"] as const) {
            const h = harness(f.root, failure);
            await h.run();
            assert.equal(h.modelCalls, failure === "prepare" ? 0 : 1);
            assert.ok(!h.launched);
            assert.match(
                h.notices.at(-1)!,
                failure === "prepare" ? /No Ghostty pane/ : /Model failed/,
            );
            assert.deepEqual(await readdir(f.drafts), []);
        }
    } finally {
        await f.dispose();
    }
});

test("split failure removes temporary files and recovers Markdown in pi's editor", async () => {
    const f = await fixture();
    try {
        const h = harness(f.root, "launch");
        await h.run();
        assert.match(h.notices.at(-1)!, /Split failed/);
        assert.deepEqual(h.editorTexts, [markdown]);
        assert.deepEqual(await readdir(f.drafts), []);
    } finally {
        await f.dispose();
    }
});

test("Linux uses configured right-split/paste bindings and an exiting shell", async () => {
    const f = await fixture();
    const platform = Object.getOwnPropertyDescriptor(process, "platform")!;
    const previousNvim = process.env.NVIM_BIN;
    const clipboard = path.join(f.root, "clipboard");
    const shortcuts = path.join(f.root, "shortcuts");
    try {
        await writeFile(
            path.join(f.bin, "wl-copy"),
            `#!/bin/sh\n/bin/cat > '${clipboard}'\n`,
            { mode: 0o700 },
        );
        await writeFile(
            path.join(f.bin, "hyprctl"),
            `#!/bin/sh\nprintf '%s\\n' "$@" >> '${shortcuts}'\n`,
            { mode: 0o700 },
        );
        const fakeNvim = path.join(f.bin, "nvim");
        await writeFile(fakeNvim, "#!/bin/sh\nexit 42\n", { mode: 0o700 });
        process.env.NVIM_BIN = fakeNvim;
        Object.defineProperty(process, "platform", { value: "linux" });
        const h = harness(f.root, undefined, curlyMarkdown);
        await h.run();
        assert.ok(
            h.notices.some((n) => /right-hand Ghostty\/neovim pane/.test(n)),
        );
        const keys = await readFile(shortcuts, "utf8");
        assert.match(keys, /ALT SHIFT,V,activewindow/);
        assert.match(keys, /ALT SHIFT,P,activewindow/);
        assert.ok(!keys.includes("CTRL_SHIFT,T"));
        const command = await readFile(clipboard, "utf8");
        assert.match(command, /^exec \/bin\/sh /);
        const entries = await readdir(f.drafts);
        assert.equal(
            await readFile(
                path.join(f.drafts, entries[0], "pr-description.md"),
                "utf8",
            ),
            normalizedMarkdown,
        );
        const wrapper = await readFile(
            path.join(f.drafts, entries[0], "open-gh-summary.sh"),
            "utf8",
        );
        assert.ok(!wrapper.includes("osascript"));
        // The editor's nonzero exit must not keep the pane open as an error.
        await exec("/bin/sh", ["-c", command]);
        assert.deepEqual(await readdir(f.drafts), []);
    } finally {
        Object.defineProperty(process, "platform", platform);
        if (previousNvim === undefined) delete process.env.NVIM_BIN;
        else process.env.NVIM_BIN = previousNvim;
        await f.dispose();
    }
});

async function waitFor(predicate: () => Promise<boolean> | boolean) {
    for (let i = 0; i < 200; i++) {
        if (await predicate()) return;
        await new Promise((resolve) => setTimeout(resolve, 50));
    }
    assert.fail("timed out waiting for condition");
}

// Runs the real generated wrapper (standalone, without --close-pane) with a
// fake nvim that rewrites the draft and exits with the given status.
async function closeDraft(
    status: number,
    existingPr = true,
    branch = "feature",
) {
    const f = await fixture();
    try {
        await writeFile(path.join(f.root, "branch"), `${branch}\n`);
        // Stub the macOS clipboard (Linux uses wl-copy, stubbed separately).
        await writeFile(
            path.join(f.bin, "pbcopy"),
            `#!/bin/sh\n/bin/cat > '${f.root}/clipboard'\n`,
            { mode: 0o700 },
        );
        if (existingPr) {
            await writeFile(
                path.join(f.root, "pr.json"),
                JSON.stringify({
                    number: 7,
                    url: "https://github.com/o/r/pull/7",
                    state: "OPEN",
                }),
            );
        }
        const fakeNvim = path.join(f.bin, "fake-nvim");
        await writeFile(
            fakeNvim,
            `#!/bin/sh
draft="\${5%.vim}.md"
printf '%s\\n' 'Title: Edited \u2019title\u2019' '' 'Edited body.' > "$draft"
exit ${status}
`,
            { mode: 0o700 },
        );
        const h = harness(f.root, undefined, markdown, fakeNvim);
        await h.run();
        assert.match(
            h.notices.at(-1)!,
            existingPr
                ? /Closing nvim updates PR #7/
                : branch === "main"
                  ? /copies the draft to the clipboard \(GitHub will not be updated: main is the base branch\)/
                  : /commits the worktree changes, pushes feature to origin and opens a draft PR/,
        );
        const [entry] = await readdir(f.drafts);
        const wrapper = path.join(f.drafts, entry, "open-pr-description.sh");
        assert.match(await readFile(wrapper, "utf8"), /exit-status/);
        // The wrapper propagates nvim's exit status.
        await exec("/bin/sh", [wrapper]).catch((error) =>
            assert.equal(error.code, status),
        );
        assert.deepEqual(await readdir(f.drafts), []);
        return { f, h };
    } catch (error) {
        await f.dispose();
        throw error;
    }
}

test("closing nvim updates the PR title and body from the edited draft", async () => {
    const { f, h } = await closeDraft(0);
    try {
        await waitFor(() => /Updated PR #7/.test(h.notices.at(-1)!));
        assert.equal(
            await readFile(path.join(f.root, "gh-edit-args"), "utf8"),
            [
                "pr",
                "edit",
                "https://github.com/o/r/pull/7",
                "--title",
                "Edited 'title'",
                "--body-file",
                "-",
                "",
            ].join("\n"),
        );
        assert.equal(
            await readFile(path.join(f.root, "gh-edit-body"), "utf8"),
            "Edited body.\n",
        );
    } finally {
        await f.dispose();
    }
});

test("a nonzero nvim exit skips the PR update", async () => {
    const { f, h } = await closeDraft(1);
    try {
        await waitFor(() => /not updated/.test(h.notices.at(-1)!));
        assert.match(h.notices.at(-1)!, /status 1/);
        assert.deepEqual(
            (await readdir(f.root)).filter((n) => n.startsWith("gh-edit")),
            [],
        );
    } finally {
        await f.dispose();
    }
});

test("without a PR, closing nvim commits, pushes, and opens a draft PR", async () => {
    const { f, h } = await closeDraft(0, false);
    try {
        await waitFor(() => /Opened draft PR #8/.test(h.notices.at(-1)!));
        assert.equal(
            await readFile(path.join(f.root, "git-writes"), "utf8"),
            [
                "add --all",
                "commit --message Edited 'title'",
                "push --set-upstream origin feature",
                "",
            ].join("\n"),
        );
        assert.equal(
            await readFile(path.join(f.root, "gh-create-args"), "utf8"),
            [
                "pr",
                "create",
                "--draft",
                "--title",
                "Edited 'title'",
                "--body-file",
                "-",
                "",
            ].join("\n"),
        );
        assert.equal(
            await readFile(path.join(f.root, "gh-create-body"), "utf8"),
            "Edited body.\n",
        );
    } finally {
        await f.dispose();
    }
});

test("on the base branch, closing nvim only copies the draft to the clipboard", async () => {
    const { f, h } = await closeDraft(0, false, "main");
    try {
        await waitFor(() => /Copied the PR draft/.test(h.notices.at(-1)!));
        assert.equal(
            await readFile(path.join(f.root, "clipboard"), "utf8"),
            "Title: Edited 'title'\n\nEdited body.\n",
        );
        const writes = (await readdir(f.root)).filter((name) =>
            /^(git-writes|gh-create|gh-edit)/.test(name),
        );
        assert.deepEqual(writes, []);
    } finally {
        await f.dispose();
    }
});
