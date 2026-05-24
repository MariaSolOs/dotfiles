import { extname, isAbsolute, relative, resolve } from "node:path";

export type Phase = "idle" | "planning" | "executing";

export const PLAN_SUBMIT_TOOL = "plan_submit_plan";
export const PLAN_COMPLETE_STEP_TOOL = "plan_complete_step";
export const ASK_QUESTION_TOOL = "ask_question";
export const PLANNING_DISCOVERY_TOOLS = ["grep", "find", "ls"] as const;

const PHASE_ONLY_TOOLS = new Set<string>([
    PLAN_SUBMIT_TOOL,
    PLAN_COMPLETE_STEP_TOOL,
]);
const ALLOWED_PLAN_EXTENSIONS = new Set<string>([".md", ".mdx"]);

export function stripPlanningOnlyTools(tools: readonly string[]): string[] {
    return tools.filter((tool) => !PHASE_ONLY_TOOLS.has(tool));
}

export function getToolsForPhase(
    baseTools: readonly string[],
    phase: Phase,
): string[] {
    const tools = stripPlanningOnlyTools(baseTools);
    if (phase === "planning") {
        return [
            ...new Set([
                ...tools,
                ...PLANNING_DISCOVERY_TOOLS,
                PLAN_SUBMIT_TOOL,
                ASK_QUESTION_TOOL,
            ]),
        ];
    }

    if (phase === "executing") {
        return [...new Set([...tools, PLAN_COMPLETE_STEP_TOOL])];
    }

    return [...new Set(tools)];
}

// Used by both the planning-phase write gate and plan_submit_plan.
// Path must resolve inside cwd (no traversal, no absolute escape) and end
// in a permitted markdown extension.
export function isPlanWritePathAllowed(
    inputPath: string,
    cwd: string,
): boolean {
    if (!inputPath) return false;
    const targetAbs = resolve(cwd, inputPath);
    const rel = relative(resolve(cwd), targetAbs);
    if (rel === "" || rel.startsWith("..") || isAbsolute(rel)) return false;
    const ext = extname(targetAbs).toLowerCase();
    return ALLOWED_PLAN_EXTENSIONS.has(ext);
}
