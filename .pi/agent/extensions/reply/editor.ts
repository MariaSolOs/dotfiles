import { mkdtemp, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import type { Run } from "./github.js";

function shellQuote(value: string): string {
    return `'${value.replace(/'/g, `'\\''`)}'`;
}

function vimString(value: string): string {
    return `'${value.replace(/'/g, "''")}'`;
}

export const SOURCE_PANE_SCRIPT = `tell application "Ghostty"
    set config to new surface configuration
    return id of focused terminal of selected tab of front window
end tell`;

export async function checkEditor(run: Run): Promise<{
    nvim: string;
    terminalId: string;
}> {
    if (process.platform !== "darwin") {
        throw new Error(
            "/reply currently requires macOS and Ghostty 1.3 or newer",
        );
    }
    // Capture the pane at command invocation, not after the model finishes:
    // focus may move to another pane or window while generation is running.
    const terminalId = (
        await run("/usr/bin/osascript", ["-e", SOURCE_PANE_SCRIPT])
    ).trim();
    if (!terminalId) throw new Error("No focused Ghostty pane found");
    const nvim = (
        await run("/bin/sh", [
            "-c",
            'command -v "$1"',
            "reply",
            process.env.NVIM_BIN || "nvim",
        ])
    ).trim();
    if (!path.isAbsolute(nvim))
        throw new Error(
            "nvim must resolve to an executable path (or set NVIM_BIN)",
        );
    return { nvim, terminalId };
}

export const CLOSE_PANE_SCRIPT = `on run argv
    tell application "Ghostty"
        set replyId to item 1 of argv
        if exists (first terminal whose id is replyId) then
            close (first terminal whose id is replyId)
        end if
    end tell
end run`;

export async function saveDraft(
    markdown: string,
    nvim: string,
    tempRoot = os.tmpdir(),
): Promise<{ draftPath: string; wrapperPath: string; directory: string }> {
    const directory = await mkdtemp(path.join(tempRoot, "pi-reply-"));
    const draftPath = path.join(directory, "reply.md");
    const vimPath = path.join(directory, "reply.vim");
    const wrapperPath = path.join(directory, "open-reply.sh");
    // Load personal nvim configuration as usual, then disable modelines before
    // opening model-generated text. Show Markdown punctuation, not concealment.
    const vimscript = `set nomodeline noexrc
execute 'edit ' . fnameescape(${vimString(draftPath)})
setlocal filetype=markdown noswapfile noundofile conceallevel=0 concealcursor= wrap linebreak
set nobackup nowritebackup
normal! gg
`;
    // Keep a parent shell alive to clean up after nvim. Ghostty can leave an
    // exited surface visible (e.g. on abnormal exits), so explicitly close only
    // the pane returned by split. Wait briefly for its ID if nvim exits before
    // openDraft finishes the launch handshake. Standalone script runs just clean up.
    const wrapper = `#!/bin/sh
managed=\${1:-}
pane_id_file=${shellQuote(path.join(directory, "pane-id"))}
cleanup() {
    trap - 0
    trap '' HUP INT TERM
    reply_id=''
    if [ "$managed" = '--close-pane' ]; then
        attempts=0
        while [ ! -s "$pane_id_file" ] && [ "$attempts" -lt 100 ]; do
            /bin/sleep 0.05
            attempts=$((attempts + 1))
        done
        if [ -s "$pane_id_file" ]; then
            IFS= read -r reply_id < "$pane_id_file"
        fi
    fi
    /bin/rm -rf -- ${shellQuote(directory)}
    if [ -n "$reply_id" ]; then
        /usr/bin/osascript -e ${shellQuote(CLOSE_PANE_SCRIPT)} "$reply_id" >/dev/null 2>&1
    fi
}
trap cleanup 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
${shellQuote(nvim)} -n -i NONE -S ${shellQuote(vimPath)}
exit "$?"
`;
    try {
        await writeFile(draftPath, markdown, { mode: 0o600 });
        await writeFile(vimPath, vimscript, { mode: 0o600 });
        await writeFile(wrapperPath, wrapper, { mode: 0o700 });
        return { draftPath, wrapperPath, directory };
    } catch (error) {
        await rm(directory, { recursive: true, force: true });
        throw error;
    }
}

export const OPEN_PANE_SCRIPT = `on run argv
    tell application "Ghostty"
        set sourceId to item 4 of argv
        set sourceTerminal to first terminal whose id is sourceId
        set config to new surface configuration
        set command of config to item 1 of argv
        set initial working directory of config to item 2 of argv
        set environment variables of config to {"PATH=" & item 3 of argv}
        set wait after command of config to false
        set replyTerminal to split sourceTerminal direction right with configuration config
        focus replyTerminal
        return id of replyTerminal
    end tell
end run`;

export async function openDraft(
    run: Run,
    wrapperPath: string,
    directory: string,
    terminalId: string,
): Promise<void> {
    // Pass dynamic strings as argv rather than interpolating them into
    // AppleScript. If the captured pane is gone, fail rather than split another.
    const replyId = (
        await run("/usr/bin/osascript", [
            "-e",
            OPEN_PANE_SCRIPT,
            `/bin/sh ${shellQuote(wrapperPath)} --close-pane`,
            directory,
            process.env.PATH ?? "/usr/bin:/bin",
            terminalId,
        ])
    ).trim();
    if (!replyId || replyId === terminalId) {
        throw new Error("Ghostty did not return a distinct reply pane ID");
    }
    // The wrapper owns deletion after reading this file, so it cannot disappear
    // while this handshake is in flight, even if nvim exits immediately.
    await writeFile(path.join(directory, "pane-id"), replyId + "\n", {
        mode: 0o600,
    });
}
