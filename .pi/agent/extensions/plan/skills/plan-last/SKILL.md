---
name: plan-last
description: Open Plan on the latest rendered assistant message and use the returned annotations to revise that message or continue.
---

# Plan Last

Use this skill when the user wants to annotate the latest assistant response in Plan.

Run:

```bash
plan last
```

Behavior:

1. Launch the command with Bash.
2. Wait for the annotation session to finish.
3. If feedback is returned, incorporate it into the follow-up response.
4. If the session closes without feedback, mention that briefly and continue.

Run the command yourself rather than telling the user to invoke shell syntax manually.
