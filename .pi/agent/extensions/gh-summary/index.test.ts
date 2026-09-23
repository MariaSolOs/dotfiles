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
import { OPEN_PANE_SCRIPT, SOURCE_PANE_SCRIPT } from "../reply/editor.js";
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
      *) exit 1 ;;
    esac ;;
  branch) printf 'feature\\n' ;;
  status) printf ' M changed.ts\\n' ;;
  diff) printf '%s\\n' 'diff --git a/changed.ts b/changed.ts' '+fixRace()' ;;
  ls-files) exit 0 ;;
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
) {
    const notices: string[] = [];
    const editorTexts: string[] = [];
    let handler!: (args: string, ctx: ExtensionCommandContext) => Promise<void>;
    let modelCalls = 0;
    let captured = false;
    let launched = false;
    const pi = {
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
                stdout = "/fake/nvim\n";
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

test("gh-summary uses the shared right-pane lifecycle with its own Markdown filename", async () => {
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
        assert.match(h.notices.at(-1)!, /right-hand Ghostty\/neovim pane/);
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
        assert.match(h.notices.at(-1)!, /right-hand Ghostty\/neovim pane/);
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
