// @ts-nocheck
// @generated — DO NOT EDIT. Source: packages/server/path-utils.ts
/**
 * Strip a cwd prefix from an absolute path to get a repo-relative path.
 * Used by review agent transforms to convert absolute file paths from
 * agent output into diff-compatible relative paths.
 *
 * Uses path.relative for cross-platform support (Windows backslashes)
 * and normalizes to forward slashes for git diff path matching.
 */
import { relative } from "node:path";

export function toRelativePath(absolutePath: string, cwd?: string): string {
    if (!cwd) return absolutePath;
    const rel = relative(cwd, absolutePath);
    // Don't relativize if the result goes outside cwd (different drive, symlink escape)
    if (rel.startsWith("..")) return absolutePath;
    // Normalize to forward slashes for diff path matching
    return rel.replace(/\\/g, "/");
}
