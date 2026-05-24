---
name: plan-file
description: Open Plan's file UI for a Plan-generated plan markdown file, ordinary markdown/HTML file, URL, or folder.
---

# Plan File

Use this skill when the user wants to open a document in Plan's file UI.

Run:

```bash
plan file <path-or-url>
```

Behavior:

1. If the target is a Plan-generated plan markdown file, it opens the plan review flow so the user can approve or request revisions.
2. Otherwise, it opens the annotation UI for markdown, converted HTML, URLs, or folders.
3. Wait for the browser review to finish.
4. If feedback is returned, address it directly.
5. If the session closes without feedback, say so briefly and continue.

Do not ask the user to paste a shell command into the chat. Run the command yourself.
