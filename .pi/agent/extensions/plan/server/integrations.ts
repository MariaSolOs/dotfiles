// @ts-nocheck
/**
 * Note-taking app integrations (Obsidian).
 * Node.js equivalents of packages/server/integrations.ts.
 * Config types, save functions, tag extraction, filename generation
 */

import { execSync } from "node:child_process";
import { existsSync, mkdirSync, statSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";

import {
    type ObsidianConfig,
    type IntegrationResult,
    generateFrontmatter,
    generateFilename,
    detectObsidianVaults,
} from "../generated/integrations-common.js";
import { sanitizeTag } from "../generated/project.js";
import { resolveUserPath } from "../generated/resolve-file.js";

export type { ObsidianConfig, IntegrationResult };
export { generateFrontmatter, generateFilename, detectObsidianVaults };

/** Detect project name from git or cwd (sync). Used by extractTags for note integrations. */
function detectProjectNameSync(): string | null {
    try {
        const toplevel = execSync("git rev-parse --show-toplevel", {
            encoding: "utf-8",
            stdio: ["pipe", "pipe", "pipe"],
        }).trim();
        if (toplevel) {
            const name = sanitizeTag(basename(toplevel));
            if (name) return name;
        }
    } catch {
        /* not in a git repo */
    }
    try {
        return sanitizeTag(basename(process.cwd())) ?? null;
    } catch {
        return null;
    }
}

export async function extractTags(markdown: string): Promise<string[]> {
    const tags = new Set<string>(["plan"]);
    const projectName = detectProjectNameSync();
    if (projectName) tags.add(projectName);
    const stopWords = new Set([
        "the",
        "and",
        "for",
        "with",
        "this",
        "that",
        "from",
        "into",
        "plan",
        "implementation",
        "overview",
        "phase",
        "step",
        "steps",
    ]);
    const h1Match = markdown.match(
        /^#\s+(?:Implementation\s+Plan:|Plan:)?\s*(.+)$/im,
    );
    if (h1Match) {
        h1Match[1]
            .toLowerCase()
            .replace(/[^\w\s-]/g, " ")
            .split(/\s+/)
            .filter((w) => w.length > 2 && !stopWords.has(w))
            .slice(0, 3)
            .forEach((w) => tags.add(w));
    }
    const seenLangs = new Set<string>();
    let langMatch: RegExpExecArray | null;
    const langRegex = /```(\w+)/g;
    while ((langMatch = langRegex.exec(markdown)) !== null) {
        const lang = langMatch[1];
        const n = lang.toLowerCase();
        if (
            !seenLangs.has(n) &&
            !["json", "yaml", "yml", "text", "txt", "markdown", "md"].includes(
                n,
            )
        ) {
            seenLangs.add(n);
            tags.add(n);
        }
    }
    return Array.from(tags).slice(0, 7);
}

export async function saveToObsidian(
    config: ObsidianConfig,
): Promise<IntegrationResult> {
    try {
        const { vaultPath, folder, plan } = config;
        if (!vaultPath?.trim()) {
            return { success: false, error: "Vault path is required" };
        }
        const normalizedVault = resolveUserPath(vaultPath);
        if (!existsSync(normalizedVault))
            return {
                success: false,
                error: `Vault path does not exist: ${normalizedVault}`,
            };
        if (!statSync(normalizedVault).isDirectory())
            return {
                success: false,
                error: `Vault path is not a directory: ${normalizedVault}`,
            };
        const folderName = folder.trim() || "plan";
        const targetFolder = join(normalizedVault, folderName);
        if (!existsSync(targetFolder))
            mkdirSync(targetFolder, { recursive: true });
        const filename = generateFilename(
            plan,
            config.filenameFormat,
            config.filenameSeparator,
        );
        const filePath = join(targetFolder, filename);
        const tags = await extractTags(plan);
        const frontmatter = generateFrontmatter(tags);
        const content = `${frontmatter}\n\n[[Plan Plans]]\n\n${plan}`;
        writeFileSync(filePath, content);
        return { success: true, path: filePath };
    } catch (err) {
        return {
            success: false,
            error: err instanceof Error ? err.message : "Unknown error",
        };
    }
}
