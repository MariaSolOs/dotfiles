---
name: plan-annotate
description: Open Plan's annotation UI for a markdown file, converted HTML file, URL, or folder and then respond to the returned annotations.
---

# Plan Annotate

Use this skill when the user wants to annotate a document in Plan instead of reviewing it inline in chat.

Run:

```bash
plan annotate <path-or-url>
```

Behavior:

1. Launch the command with Bash.
2. Wait for the browser review to finish.
3. If annotations are returned, address them directly.
4. If the session closes without feedback, say so briefly and continue.

Do not ask the user to paste a shell command into the chat. Run the command yourself.
