// @ts-nocheck
// @generated — DO NOT EDIT. Source: packages/shared/storage.ts
/**
 * Plan Storage Utility
 *
 * Stores submitted plan versions in ~/.plan/history/.
 * Cross-platform: works on Windows, macOS, and Linux.
 *
 * Runtime-agnostic: uses only node:fs, node:path, node:os.
 */

import { homedir } from "os";
import { join } from "path";
import {
    mkdirSync,
    writeFileSync,
    readFileSync,
    readdirSync,
    statSync,
    existsSync,
} from "fs";
import { sanitizeTag } from "./project";

/**
 * Extract the first heading from markdown content.
 */
function extractFirstHeading(markdown: string): string | null {
    const match = markdown.match(/^#\s+(.+)$/m);
    if (!match) return null;
    return match[1].trim();
}

/**
 * Generate a slug from plan content.
 * Format: {sanitized-heading}-YYYY-MM-DD
 */
export function generateSlug(plan: string): string {
    const date = new Date().toISOString().split("T")[0]; // YYYY-MM-DD

    const heading = extractFirstHeading(plan);
    const slug = heading ? sanitizeTag(heading) : null;

    return slug ? `${slug}-${date}` : `plan-${date}`;
}

// --- Version History ---

/**
 * Get the history directory for a project/slug combination, creating it if needed.
 * History is always stored in ~/.plan/history/{project}/{slug}/.
 */
export function getHistoryDir(project: string, slug: string): string {
    const historyDir = join(homedir(), ".plan", "history", project, slug);
    mkdirSync(historyDir, { recursive: true });
    return historyDir;
}

/**
 * Determine the next version number by scanning existing files.
 * Returns 1 if no versions exist, otherwise max + 1.
 */
function getNextVersionNumber(historyDir: string): number {
    try {
        const entries = readdirSync(historyDir);
        let max = 0;
        for (const entry of entries) {
            const match = entry.match(/^(\d+)\.md$/);
            if (match) {
                const num = parseInt(match[1], 10);
                if (num > max) max = num;
            }
        }
        return max + 1;
    } catch {
        return 1;
    }
}

/**
 * Save a plan version to the history directory.
 * Deduplication: if the latest version has identical content, skip saving.
 * Returns the version number, file path, and whether a new file was created.
 */
export function saveToHistory(
    project: string,
    slug: string,
    plan: string,
): { version: number; path: string; isNew: boolean } {
    const historyDir = getHistoryDir(project, slug);
    const nextVersion = getNextVersionNumber(historyDir);

    // Deduplicate: check if latest version has identical content
    if (nextVersion > 1) {
        const latestPath = join(
            historyDir,
            `${String(nextVersion - 1).padStart(3, "0")}.md`,
        );
        try {
            const existing = readFileSync(latestPath, "utf-8");
            if (existing === plan) {
                return {
                    version: nextVersion - 1,
                    path: latestPath,
                    isNew: false,
                };
            }
        } catch {
            // File read failed, proceed with saving
        }
    }

    const fileName = `${String(nextVersion).padStart(3, "0")}.md`;
    const filePath = join(historyDir, fileName);
    writeFileSync(filePath, plan, "utf-8");
    return { version: nextVersion, path: filePath, isNew: true };
}

/**
 * Read a specific version's content from history.
 * Returns null if the version doesn't exist or on read error.
 */
export function getPlanVersion(
    project: string,
    slug: string,
    version: number,
): string | null {
    const historyDir = join(homedir(), ".plan", "history", project, slug);
    const fileName = `${String(version).padStart(3, "0")}.md`;
    const filePath = join(historyDir, fileName);

    try {
        return readFileSync(filePath, "utf-8");
    } catch {
        return null;
    }
}

/**
 * Get the file path for a specific version in history.
 * Returns null if the version file doesn't exist.
 */
export function getPlanVersionPath(
    project: string,
    slug: string,
    version: number,
): string | null {
    const historyDir = join(homedir(), ".plan", "history", project, slug);
    const fileName = `${String(version).padStart(3, "0")}.md`;
    const filePath = join(historyDir, fileName);
    return existsSync(filePath) ? filePath : null;
}

/**
 * Get the number of versions stored for a project/slug.
 * Returns 0 if the directory doesn't exist.
 */
export function getVersionCount(project: string, slug: string): number {
    const historyDir = join(homedir(), ".plan", "history", project, slug);
    try {
        const entries = readdirSync(historyDir);
        return entries.filter((e) => /^\d+\.md$/.test(e)).length;
    } catch {
        return 0;
    }
}

/**
 * List all versions for a project/slug with metadata.
 * Returns versions sorted ascending by version number.
 */
export function listVersions(
    project: string,
    slug: string,
): Array<{ version: number; timestamp: string }> {
    const historyDir = join(homedir(), ".plan", "history", project, slug);
    try {
        const entries = readdirSync(historyDir);
        const versions: Array<{ version: number; timestamp: string }> = [];
        for (const entry of entries) {
            const match = entry.match(/^(\d+)\.md$/);
            if (match) {
                const version = parseInt(match[1], 10);
                const filePath = join(historyDir, entry);
                try {
                    const stat = statSync(filePath);
                    versions.push({
                        version,
                        timestamp: stat.mtime.toISOString(),
                    });
                } catch {
                    versions.push({ version, timestamp: "" });
                }
            }
        }
        return versions.sort((a, b) => a.version - b.version);
    } catch {
        return [];
    }
}

/**
 * List all plan slugs stored for a project.
 * Returns slugs sorted by most recently modified first.
 */
export function listProjectPlans(
    project: string,
): Array<{ slug: string; versions: number; lastModified: string }> {
    const projectDir = join(homedir(), ".plan", "history", project);
    try {
        const entries = readdirSync(projectDir, { withFileTypes: true });
        const plans: Array<{
            slug: string;
            versions: number;
            lastModified: string;
        }> = [];
        for (const entry of entries) {
            if (!entry.isDirectory()) continue;
            const slugDir = join(projectDir, entry.name);
            const files = readdirSync(slugDir).filter((f) =>
                /^\d+\.md$/.test(f),
            );
            if (files.length === 0) continue;

            // Find most recent file modification time
            let latest = 0;
            for (const file of files) {
                try {
                    const mtime = statSync(join(slugDir, file)).mtime.getTime();
                    if (mtime > latest) latest = mtime;
                } catch {
                    /* skip */
                }
            }

            plans.push({
                slug: entry.name,
                versions: files.length,
                lastModified: latest ? new Date(latest).toISOString() : "",
            });
        }
        return plans.sort((a, b) =>
            b.lastModified.localeCompare(a.lastModified),
        );
    } catch {
        return [];
    }
}
