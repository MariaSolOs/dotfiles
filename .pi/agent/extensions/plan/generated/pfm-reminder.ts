// @ts-nocheck
// @generated — DO NOT EDIT. Source: packages/shared/pfm-reminder.ts
/**
 * Plan Flavored Markdown reminder.
 *
 * Static prose injected into the EnterPlanMode PreToolUse hook when the user
 * has opted in via `pfmReminder: true` in ~/.plan/config.json. It tells
 * the planning agent which markdown extensions Plan's viewer renders so
 * plans can be enriched with code-file links, callouts, tables, diagrams, etc.
 *
 * Keep this short. The agent reads it on every EnterPlanMode call.
 */

/**
 * Compose the additionalContext string for the improve-context PreToolUse handler.
 * Returns null when the reminder is disabled (handler should exit silently).
 */
export function composeImproveContext(input: {
    pfmEnabled: boolean;
}): string | null {
    return input.pfmEnabled ? PFM_REMINDER : null;
}

export const PFM_REMINDER = `[Plan Flavored Markdown]
This plan will be reviewed in Plan, which renders GitHub Flavored Markdown plus the extensions below. Use these features when they make the plan clearer for the reviewer — don't force them in for their own sake.

Code-file links (highest leverage)
Reference real source files inline. Plan validates the path and renders a clickable badge that opens the file in the reviewer's editor — prefer this over pasting code when you just need to point at something.
  \`packages/server/index.ts\`            backticked path
  \`packages/server/index.ts:42\`         path with line number
  \`packages/server/index.ts:10-20\`      line range — hover shows a code snippet preview
  [the handler](packages/server/index.ts:42)  markdown link form
Ambiguous paths (e.g. \`index.ts\`) still render and open a picker.

Callouts and alerts
GitHub-style alerts highlight critical context:
  > [!NOTE]      general callout
  > [!TIP]       suggestion
  > [!WARNING]   watch out
  > [!CAUTION]   risk
  > [!IMPORTANT] must-read
Or use directive containers for richer blocks:
  :::tip
  Body with **inline markdown**.
  :::

Tables
Pipe tables are interactive — the reviewer can copy as Markdown/CSV from a hover toolbar, or expand to a sortable, filterable popout. Reach for them for comparisons, files-to-change lists, or risk summaries.

Task lists
Use \`- [ ]\` and \`- [x]\` for actionable steps the reviewer (or a follow-up agent) can tick off.

Diagrams
Code fences with \`mermaid\` or \`graphviz\` render as live diagrams. Useful for flow, state, sequence, or architecture sketches.

Other extras
  - Wiki-links: [[architecture]] auto-resolves to .md docs in the workspace
  - Hex color swatches: #1a2bcc renders as a small color chip
  - @username and #123 link to GitHub when a repo is detected
  - A small set of emoji shortcodes is supported (:rocket:, :warning:, :white_check_mark:, ...)

Plain prose is always fine. The point is: prefer code-file links over copy-pasted snippets, and reach for callouts or tables when structure makes the plan easier to scan.`;
