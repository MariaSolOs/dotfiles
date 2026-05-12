---
description: Create a concise GitHub-ready PR description and title of this conversation and open it in neovim
---

Summarize the current conversation into a concise, human-sounding PR description for GitHub, together with a suggested title.

## Requirements

- Use raw Markdown.
- No code fences around the whole summary.
- No padding/preamble like "Here’s a summary".
- Be concise but include the important facts, decisions, commands run, results, and follow-ups.
- Write it in first person plural or neutral engineering voice when appropriate.

After drafting the exact summary text, open it in a separate Ghostty tab running neovim, displaying the contents in a temporary scratch buffer:

1. Write the exact summary to a temporary Markdown file using a single-quoted heredoc so Markdown is preserved verbatim.
2. Use `osascript` to activate Ghostty, create a new tab with Cmd+T, paste a shell command, and press Enter.
3. The shell command should run neovim against the temp file and configure the buffer as scratch-like Markdown, for example:
   `nvim -n +'setlocal filetype=markdown buftype=nofile bufhidden=wipe noswapfile' +'setlocal nomodified' "$tmpfile"`
4. Prefer pasting the command via the clipboard inside AppleScript rather than typing it character by character, so paths/quotes are reliable.
5. Do not print the summary in chat unless opening Ghostty fails. If it succeeds, respond only with a terse confirmation and the temp file path.
