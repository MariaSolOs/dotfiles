// Run with: node --experimental-test-module-mocks --test index.test.mjs
// Ghostty/clipboard are mocked; the generated shell wrapper executes for real.
import assert from "node:assert/strict";
import { execFile as realExecFile, spawn } from "node:child_process";
import { access, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import { PassThrough } from "node:stream";
import { mock, test } from "node:test";
import { promisify } from "node:util";

const realExec = promisify(realExecFile);
let scenario;
const quote = (s) => `'${s.replace(/'/g, `'\\''`)}'`;
function execFile() {}
execFile[promisify.custom] = (file) => {
    const stdin = new PassThrough();
    const chunks = [];
    stdin.on("data", (chunk) => chunks.push(chunk));
    const finished = new Promise((resolve) => stdin.on("finish", resolve));
    const pending = (async () => {
        if (file === "git") return { stdout: `${scenario.root}\n`, stderr: "" };
        await finished;
        if (file.endsWith("pbcopy") || file === "wl-copy") {
            scenario.command = Buffer.concat(chunks).toString();
        } else if (file.endsWith("osascript") || file === "hyprctl") {
            if (scenario.launchError) throw new Error("Automation denied");
            if (file === "hyprctl") return { stdout: "", stderr: "" };
            const script = scenario.command.match(/^exec \/bin\/sh '(.*)'$/)[1];
            scenario.dir = path.dirname(script);
            const source = await readFile(script, "utf8");
            assert(!source.includes("tuicr"));
            assert(!source.includes("XDG_"));
            assert(!source.includes("keystroke"));
            if (scenario.onLaunch) {
                await scenario.onLaunch();
            } else {
                const fake = path.join(scenario.dir, "fake.sh");
                await writeFile(fake, scenario.program);
                const executableWrapper = source.replace(
                    "'/Volumes/git/revisar/target/release/revisar'",
                    `/bin/sh ${quote(fake)}`,
                );
                await writeFile(script, executableWrapper);
                await realExec("/bin/sh", [script]).catch(() => {});
            }
        } else throw new Error(`Unexpected command: ${file}`);
        return { stdout: "", stderr: "" };
    })();
    pending.child = { stdin };
    return pending;
};
mock.module("node:child_process", { namedExports: { execFile, spawn } });
const { default: extension } = await import("./index.ts");

async function setup(t, options = {}) {
    // An awkward repo path also exercises the wrapper's shell quoting.
    const root = await mkdtemp(path.join(os.tmpdir(), "revisar-test-'repo-"));
    scenario = {
        root,
        program: "printf 'review feedback\\n'\nexit 0\n",
        ...options,
    };
    const current = scenario;
    t.after(async () => {
        await rm(root, { recursive: true, force: true });
        if (current.dir)
            await rm(current.dir, { recursive: true, force: true });
    });
    let handler;
    let shutdown;
    const sent = [];
    const notifications = [];
    const editor = [];
    const statuses = [];
    const ctx = {
        mode: "tui",
        cwd: root,
        isIdle: () => true,
        hasPendingMessages: () => false,
        sessionManager: { getSessionId: () => "original-session" },
        ui: {
            notify: (message) => notifications.push(message),
            setStatus: (_, value) => statuses.push(value),
            setEditorText: (text) => editor.push(text),
        },
    };
    extension({
        registerCommand: (name, command) => {
            assert.equal(name, "revisar");
            handler = command.handler;
        },
        on: (name, fn) => {
            assert.equal(name, "session_shutdown");
            shutdown = fn;
        },
        sendUserMessage: (text, options) => {
            if (scenario.sendError) throw new Error("Handoff failed");
            sent.push({ text, options });
        },
    });
    return {
        ctx,
        sent,
        notifications,
        editor,
        statuses,
        run: (args = "") => handler(args, ctx),
        shutdown: () => shutdown({}, ctx),
    };
}

test("explicit send delivers once, then removes transport", async (t) => {
    const h = await setup(t);
    await h.run();
    assert.deepEqual(h.sent, [
        { text: "review feedback", options: { deliverAs: "followUp" } },
    ]);
    assert.equal(h.statuses.at(-1), undefined);
    await assert.rejects(access(scenario.dir), { code: "ENOENT" });
});

test("cancel and error never deliver even if stdout contains text", async (t) => {
    for (const code of [1, 2]) {
        const h = await setup(t, {
            program: `printf 'partial feedback'\nprintf 'failure' >&2\nexit ${code}\n`,
        });
        await h.run();
        assert.equal(h.sent.length, 0);
        assert(
            h.notifications.some((n) =>
                n.includes(code === 2 ? "cancelled" : "failure"),
            ),
        );
        await assert.rejects(access(scenario.dir), { code: "ENOENT" });
    }
});

test("empty feedback does not start a turn", async (t) => {
    const h = await setup(t, { program: "exit 0\n" });
    await h.run();
    assert.equal(h.sent.length, 0);
    assert(h.notifications.some((n) => n.includes("no comments")));
});

test("failed handoff leaves feedback in the editor, not a saved review", async (t) => {
    const h = await setup(t, { sendError: true });
    await h.run();
    assert.deepEqual(h.editor, ["review feedback"]);
    assert.equal(h.sent.length, 0);
    await assert.rejects(access(scenario.dir), { code: "ENOENT" });
});

test("shutdown abandons review and concurrent launches are rejected", async (t) => {
    const h = await setup(t);
    scenario.onLaunch = async () => {
        await h.run();
        assert(h.notifications.some((n) => n.includes("already open")));
        await h.shutdown();
    };
    await h.run();
    assert.equal(h.sent.length, 0);
    assert.equal(h.editor.length, 0);
    await assert.rejects(access(scenario.dir), { code: "ENOENT" });
});

test("busy agent and unexpected arguments do not launch", async (t) => {
    const h = await setup(t);
    h.ctx.isIdle = () => false;
    await h.run();
    assert(h.notifications.some((n) => n.includes("Wait for the agent")));
    h.ctx.isIdle = () => true;
    await h.run("--staged");
    assert(h.notifications.some((n) => n.includes("no arguments")));
    assert.equal(scenario.command, undefined);
    assert.equal(h.sent.length, 0);
});
