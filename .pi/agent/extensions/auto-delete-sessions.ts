/**
 * Auto-delete sessions extension
 *
 * Automatically deletes pi sessions older than a configurable number of days.
 *
 * Configuration:
 *   --session-max-age <days>      Maximum session age in days (default: 7)
 *   --session-cleanup-dry-run     Preview deletions without actually deleting
 *
 * Commands:
 *   /cleanup-sessions             Manually trigger session cleanup
 *   /cleanup-sessions --dry-run   Preview what would be deleted
 *
 * The extension runs cleanup automatically on session start.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { SessionManager } from "@mariozechner/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";

// Parse days to milliseconds
function parseDays(days: number): number {
    if (days <= 0 || !Number.isFinite(days)) {
        throw new Error(`Invalid max age: "${days}". Must be a positive number of days.`);
    }
    return days * 24 * 60 * 60 * 1000;
}

// Format timestamp to relative time in days
function formatAge(timestamp: Date): string {
    const now = Date.now();
    const ageMs = now - timestamp.getTime();
    const days = ageMs / (24 * 60 * 60 * 1000);
    return `${days.toFixed(1)} days ago`;
}

interface SessionInfo {
    file: string;
    timestamp: Date;
    name?: string;
    cwd: string;
}

async function getOldSessions(maxAgeMs: number): Promise<SessionInfo[]> {
    const cutoff = Date.now() - maxAgeMs;
    const oldSessions: SessionInfo[] = [];

    // List all sessions across all projects
    const sessions = await SessionManager.listAll();

    for (const session of sessions) {
        const sessionTime = new Date(session.timestamp).getTime();
        if (sessionTime < cutoff) {
            oldSessions.push({
                file: session.file,
                timestamp: new Date(session.timestamp),
                name: session.name,
                cwd: session.cwd,
            });
        }
    }

    // Sort by age (oldest first)
    oldSessions.sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());

    return oldSessions;
}

async function deleteSession(sessionFile: string): Promise<boolean> {
    try {
        await fs.promises.unlink(sessionFile);
        return true;
    } catch {
        return false;
    }
}

export default function(pi: ExtensionAPI) {
    // Register flags
    pi.registerFlag("session-max-age", {
        description: "Maximum session age in days before auto-deletion",
        type: "number",
        default: 7,
    });

    pi.registerFlag("session-cleanup-dry-run", {
        description: "Preview session deletions without actually deleting",
        type: "boolean",
        default: false,
    });

    // Core cleanup function
    async function cleanupSessions(
        ctx: Parameters<Parameters<typeof pi.on>[1]>[1],
        dryRun: boolean,
        maxAgeDaysOverride?: number,
    ): Promise<{ deleted: number; failed: number; skipped: number }> {
        const maxAgeDays = maxAgeDaysOverride ?? (pi.getFlag("--session-max-age") as number) ?? 7;
        const currentSessionFile = ctx.sessionManager.getSessionFile();

        let maxAgeMs: number;
        try {
            maxAgeMs = parseDays(maxAgeDays);
        } catch (err) {
            ctx.ui.notify(`${err}`, "error");
            return { deleted: 0, failed: 0, skipped: 0 };
        }

        const oldSessions = await getOldSessions(maxAgeMs);

        if (oldSessions.length === 0) {
            return { deleted: 0, failed: 0, skipped: 0 };
        }

        let deleted = 0;
        let failed = 0;
        let skipped = 0;

        for (const session of oldSessions) {
            // Never delete the current session
            if (session.file === currentSessionFile) {
                skipped++;
                continue;
            }

            if (dryRun) {
                const name = session.name || path.basename(session.file);
                ctx.ui.notify(
                    `[DRY RUN] Would delete: ${name} (${formatAge(session.timestamp)})`,
                    "info",
                );
                deleted++;
            } else {
                const success = await deleteSession(session.file);
                if (success) {
                    deleted++;
                } else {
                    failed++;
                }
            }
        }

        return { deleted, failed, skipped };
    }

    // Register command for manual cleanup
    pi.registerCommand("cleanup-sessions", {
        description: "Delete sessions older than the configured max age",
        handler: async (args, ctx) => {
            const isDryRun = args?.includes("--dry-run")
                || (pi.getFlag("--session-cleanup-dry-run") as boolean);

            // Parse optional max-age from args
            let maxAgeDays: number | undefined;
            const ageMatch = args?.match(/--max-age[=\s]+(\d+)/);
            if (ageMatch) {
                maxAgeDays = parseInt(ageMatch[1], 10);
            }

            const displayDays = maxAgeDays ?? (pi.getFlag("--session-max-age") as number) ?? 7;

            ctx.ui.notify(
                `${isDryRun ? "[DRY RUN] " : ""}Cleaning up sessions older than ${displayDays} days...`,
                "info",
            );

            const result = await cleanupSessions(ctx, isDryRun, maxAgeDays);

            if (result.deleted === 0 && result.failed === 0) {
                ctx.ui.notify("No old sessions to clean up", "info");
            } else {
                const prefix = isDryRun ? "[DRY RUN] " : "";
                const action = isDryRun ? "Would delete" : "Deleted";
                let message = `${prefix}${action} ${result.deleted} session${result.deleted !== 1 ? "s" : ""}`;

                if (result.failed > 0) {
                    message += `, ${result.failed} failed`;
                }
                if (result.skipped > 0) {
                    message += ` (${result.skipped} skipped - current session)`;
                }

                ctx.ui.notify(message, result.failed > 0 ? "warn" : "success");
            }
        },
    });

    // Auto-cleanup on session start
    pi.on("session_start", async (_event, ctx) => {
        const dryRun = pi.getFlag("--session-cleanup-dry-run") as boolean;
        const maxAgeDays = (pi.getFlag("--session-max-age") as number) ?? 7;

        // Run cleanup silently
        const result = await cleanupSessions(ctx, dryRun, undefined);

        // Only notify if something was deleted (or would be in dry-run mode)
        if (result.deleted > 0) {
            const prefix = dryRun ? "[DRY RUN] " : "";
            const action = dryRun ? "Would delete" : "Cleaned up";
            ctx.ui.notify(
                `${prefix}${action} ${result.deleted} old session${
                    result.deleted !== 1 ? "s" : ""
                } (older than ${maxAgeDays} days)`,
                "info",
            );
        }
    });
}
