import { homedir } from "node:os";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
    createBashToolDefinition,
    createEditToolDefinition,
    createFindToolDefinition,
    createGrepToolDefinition,
    createLsToolDefinition,
    createReadToolDefinition,
    createWriteToolDefinition,
    getLanguageFromPath,
    highlightCode,
} from "@earendil-works/pi-coding-agent";
import {
    Box,
    Container,
    Spacer,
    Text,
    wrapTextWithAnsi,
    type Component,
} from "@earendil-works/pi-tui";

// Keep collapsed tool output compact while still leaving expanded views to
// Pi's built-in renderers. Bash uses visual terminal lines so wrapped JSON and
// other long single-line outputs do not fill the screen.
const PREVIEW_LINES = 2;

type ThemeLike = {
    fg(color: string, text: string): string;
    bg(color: string, text: string): string;
    bold(text: string): string;
};

function createBuiltInDefinitions(cwd: string) {
    // Built-in definitions are cwd-aware; cache one set per working directory and
    // delegate execution to them so this extension only owns preview rendering.
    return {
        read: createReadToolDefinition(cwd),
        ls: createLsToolDefinition(cwd),
        grep: createGrepToolDefinition(cwd),
        find: createFindToolDefinition(cwd),
        write: createWriteToolDefinition(cwd),
        edit: createEditToolDefinition(cwd),
        bash: createBashToolDefinition(cwd),
    };
}

type BuiltInDefinitions = ReturnType<typeof createBuiltInDefinitions>;
type BuiltInToolName = keyof BuiltInDefinitions;

const toolCache = new Map<string, BuiltInDefinitions>();

function getBuiltInDefinitions(cwd: string) {
    let tools = toolCache.get(cwd);
    if (!tools) {
        tools = createBuiltInDefinitions(cwd);
        toolCache.set(cwd, tools);
    }
    return tools;
}

function delegateExecute(toolName: BuiltInToolName): any {
    return async (
        toolCallId: string,
        params: any,
        signal: AbortSignal | undefined,
        onUpdate: any,
        ctx: any,
    ) =>
        getBuiltInDefinitions(ctx.cwd)[toolName].execute(
            toolCallId,
            params,
            signal,
            onUpdate,
            ctx,
        );
}

function renderBuiltInCall(
    toolName: BuiltInToolName,
    args: any,
    theme: any,
    context: any,
    fallback: Component,
): Component {
    return (
        getBuiltInDefinitions(context.cwd)[toolName].renderCall?.(
            args,
            theme,
            context,
        ) ?? fallback
    );
}

function renderBuiltInExpandedResult(
    toolName: BuiltInToolName,
    result: any,
    options: any,
    theme: any,
    context: any,
    fallback: Component,
): Component | undefined {
    if (!options.expanded) return undefined;
    return (
        getBuiltInDefinitions(context.cwd)[toolName].renderResult?.(
            result,
            options,
            theme,
            context,
        ) ?? fallback
    );
}

function str(value: unknown): string | null {
    if (typeof value === "string") return value;
    if (value == null) return "";
    return null;
}

function shortenPath(path: string): string {
    const home = homedir();
    if (path.startsWith(home)) return `~${path.slice(home.length)}`;
    return path;
}

function replaceTabs(text: string): string {
    return text.replace(/\t/g, "   ");
}

function normalizeDisplayText(text: string): string {
    return text.replace(/\r/g, "");
}

function trimTrailingEmptyLines(lines: string[]): string[] {
    let end = lines.length;
    while (end > 0 && lines[end - 1] === "") end--;
    return lines.slice(0, end);
}

function textOutput(result: {
    content?: Array<{ type: string; text?: string }>;
}): string {
    return (result.content ?? [])
        .filter((content) => content.type === "text")
        .map((content) => normalizeDisplayText(content.text ?? ""))
        .join("\n");
}

function moreLinesMessage(remaining: number, theme: ThemeLike): string {
    return theme.fg("muted", `${remaining} more lines...`);
}

function formatBashCall(args: any, theme: ThemeLike): string {
    const command = str(args?.command);
    const timeout =
        typeof args?.timeout === "number" ? args.timeout : undefined;
    const timeoutSuffix = timeout
        ? theme.fg("muted", ` (timeout ${timeout}s)`)
        : "";
    if (command === null) {
        return `${theme.fg("toolTitle", theme.bold("$"))} ${theme.fg("error", "[invalid arg]")}${timeoutSuffix}`;
    }

    const commandDisplay = command
        ? replaceTabs(normalizeDisplayText(command))
        : theme.fg("toolOutput", "...");
    return `${theme.fg("toolTitle", theme.bold(`$ ${commandDisplay}`))}${timeoutSuffix}`;
}

function previewLines(
    lines: string[],
    theme: ThemeLike,
    options: { lang?: string; colorPlain?: boolean } = {},
): string {
    const trimmed = trimTrailingEmptyLines(lines);
    const displayLines = trimmed.slice(0, PREVIEW_LINES);
    const remaining = trimmed.length - displayLines.length;

    let output = displayLines
        .map((line) => {
            if (options.lang) return line;
            return options.colorPlain === false
                ? line
                : theme.fg("toolOutput", replaceTabs(line));
        })
        .join("\n");

    if (remaining > 0) {
        output += `${output ? "\n" : ""}${moreLinesMessage(remaining, theme)}`;
    }

    return output;
}

function formatMinimalTextResult(result: any, theme: ThemeLike): string {
    const output = previewLines(textOutput(result).trim().split("\n"), theme);
    return output ? `\n${output}` : "";
}

function highlightedContentLines(
    content: string,
    rawPath: string | null,
): { lines: string[]; lang?: string } {
    const lang = rawPath ? getLanguageFromPath(rawPath) : undefined;
    const normalized = replaceTabs(normalizeDisplayText(content));
    return {
        lang,
        lines: lang ? highlightCode(normalized, lang) : normalized.split("\n"),
    };
}

function formatReadResult(args: any, result: any, theme: ThemeLike): string {
    const rawPath = str(args?.file_path ?? args?.path);
    const { lines, lang } = highlightedContentLines(
        textOutput(result),
        rawPath,
    );
    const output = previewLines(lines, theme, { lang });
    return output ? `\n${output}` : "";
}

function formatWriteCall(args: any, theme: ThemeLike): string {
    const rawPath = str(args?.file_path ?? args?.path);
    const fileContent = str(args?.content);
    const path = rawPath !== null ? shortenPath(rawPath) : null;
    const pathDisplay =
        path === null
            ? theme.fg("error", "[invalid arg]")
            : path
              ? theme.fg("accent", path)
              : theme.fg("toolOutput", "...");

    let output = `${theme.fg("toolTitle", theme.bold("write"))} ${pathDisplay}`;
    if (fileContent === null) {
        output += `\n\n${theme.fg("error", "[invalid content arg - expected string]")}`;
    } else if (fileContent) {
        const { lines, lang } = highlightedContentLines(fileContent, rawPath);
        const preview = previewLines(lines, theme, { lang });
        if (preview) output += `\n\n${preview}`;
    }
    return output;
}

type EditBlock = { oldText: string; newText: string };

function getEditBlocks(args: any): EditBlock[] {
    if (Array.isArray(args?.edits)) {
        return args.edits.filter(
            (edit: any): edit is EditBlock =>
                typeof edit?.oldText === "string" &&
                typeof edit?.newText === "string",
        );
    }
    if (
        typeof args?.oldText === "string" &&
        typeof args?.newText === "string"
    ) {
        return [{ oldText: args.oldText, newText: args.newText }];
    }
    return [];
}

function editPreviewLines(args: any, theme: ThemeLike): string[] {
    const blocks = getEditBlocks(args);
    const lines: string[] = [];

    for (const block of blocks) {
        const oldLines = trimTrailingEmptyLines(
            normalizeDisplayText(block.oldText).split("\n"),
        );
        const newLines = trimTrailingEmptyLines(
            normalizeDisplayText(block.newText).split("\n"),
        );

        for (const line of oldLines) {
            lines.push(theme.fg("toolDiffRemoved", `- ${replaceTabs(line)}`));
        }
        for (const line of newLines) {
            lines.push(theme.fg("toolDiffAdded", `+ ${replaceTabs(line)}`));
        }
    }

    return lines;
}

function formatEditCall(args: any, theme: ThemeLike): string {
    const rawPath = str(args?.file_path ?? args?.path);
    const path = rawPath !== null ? shortenPath(rawPath) : null;
    const pathDisplay =
        path === null
            ? theme.fg("error", "[invalid arg]")
            : path
              ? theme.fg("accent", path)
              : theme.fg("toolOutput", "...");
    return `${theme.fg("toolTitle", theme.bold("edit"))} ${pathDisplay}`;
}

function buildCollapsedEditCall(component: Box, args: any, theme: ThemeLike) {
    component.setBgFn((text) => theme.bg("toolPendingBg", text));
    component.clear();
    component.addChild(new Text(formatEditCall(args, theme), 0, 0));

    const lines = editPreviewLines(args, theme);
    const output = previewLines(lines, theme, { colorPlain: false });
    if (output) {
        component.addChild(new Spacer(1));
        component.addChild(new Text(output, 0, 0));
    }
    return component;
}

class BashCallPreviewComponent implements Component {
    constructor(
        private args: any,
        private theme: ThemeLike,
    ) {}

    set(args: any, theme: ThemeLike) {
        this.args = args;
        this.theme = theme;
    }

    invalidate() {}

    render(width: number): string[] {
        const visualLines = wrapTextWithAnsi(
            formatBashCall(this.args, this.theme),
            Math.max(1, width),
        );
        const displayLines = visualLines.slice(0, PREVIEW_LINES);
        const remaining = visualLines.length - displayLines.length;

        if (remaining > 0) {
            return [...displayLines, moreLinesMessage(remaining, this.theme)];
        }
        return displayLines;
    }
}

class BashPreviewComponent implements Component {
    constructor(
        private result: any,
        private theme: ThemeLike,
    ) {}

    set(result: any, theme: ThemeLike) {
        this.result = result;
        this.theme = theme;
    }

    invalidate() {}

    render(width: number): string[] {
        const output = textOutput(this.result).trim();
        if (!output) return [];

        const styledOutput = output
            .split("\n")
            .map((line) => this.theme.fg("toolOutput", replaceTabs(line)))
            .join("\n");
        const visualLines = wrapTextWithAnsi(styledOutput, Math.max(1, width));
        const displayLines = visualLines.slice(-PREVIEW_LINES);
        const skipped = visualLines.length - displayLines.length;

        if (skipped > 0) {
            return ["", ...displayLines, moreLinesMessage(skipped, this.theme)];
        }
        return ["", ...displayLines];
    }
}

function registerMinimalTextResultTool(
    pi: ExtensionAPI,
    startupTools: BuiltInDefinitions,
    toolName: "ls" | "grep" | "find",
) {
    pi.registerTool({
        ...startupTools[toolName],
        execute: delegateExecute(toolName),
        renderCall(args: any, theme: any, context: any) {
            return renderBuiltInCall(
                toolName,
                args,
                theme,
                context,
                new Text("", 0, 0),
            );
        },
        renderResult(result: any, options: any, theme: any, context: any) {
            const expanded = renderBuiltInExpandedResult(
                toolName,
                result,
                options,
                theme,
                context,
                new Text("", 0, 0),
            );
            if (expanded) return expanded;

            const text =
                context.lastComponent instanceof Text
                    ? context.lastComponent
                    : new Text("", 0, 0);
            text.setText(formatMinimalTextResult(result, theme));
            return text;
        },
    });
}

export default function (pi: ExtensionAPI) {
    const startupTools = getBuiltInDefinitions(process.cwd());

    pi.registerTool({
        ...startupTools.bash,
        execute: delegateExecute("bash"),
        renderCall(args: any, theme: any, context: any) {
            const state = context.state;
            if (context.executionStarted && state?.startedAt === undefined) {
                state.startedAt = Date.now();
                state.endedAt = undefined;
            }

            if (context.expanded) {
                const text =
                    context.lastComponent instanceof Text
                        ? context.lastComponent
                        : new Text("", 0, 0);
                text.setText(formatBashCall(args, theme));
                return text;
            }

            const component =
                context.lastComponent instanceof BashCallPreviewComponent
                    ? context.lastComponent
                    : new BashCallPreviewComponent(args, theme);
            component.set(args, theme);
            return component;
        },
        renderResult(result: any, options: any, theme: any, context: any) {
            if (options.expanded) {
                return (
                    getBuiltInDefinitions(context.cwd).bash.renderResult?.(
                        result,
                        options,
                        theme,
                        context,
                    ) ?? new Container()
                );
            }

            const component =
                context.lastComponent instanceof BashPreviewComponent
                    ? context.lastComponent
                    : new BashPreviewComponent(result, theme);
            component.set(result, theme);
            return component;
        },
    });

    registerMinimalTextResultTool(pi, startupTools, "ls");
    registerMinimalTextResultTool(pi, startupTools, "grep");
    registerMinimalTextResultTool(pi, startupTools, "find");

    pi.registerTool({
        ...startupTools.read,
        execute: delegateExecute("read"),
        renderCall(args: any, theme: any, context: any) {
            return renderBuiltInCall(
                "read",
                args,
                theme,
                context,
                new Text("", 0, 0),
            );
        },
        renderResult(result: any, options: any, theme: any, context: any) {
            const expanded = renderBuiltInExpandedResult(
                "read",
                result,
                options,
                theme,
                context,
                new Text("", 0, 0),
            );
            if (expanded) return expanded;

            const text =
                context.lastComponent instanceof Text
                    ? context.lastComponent
                    : new Text("", 0, 0);
            text.setText(formatReadResult(context.args, result, theme));
            return text;
        },
    });

    pi.registerTool({
        ...startupTools.write,
        execute: delegateExecute("write"),
        renderCall(args: any, theme: any, context: any) {
            if (context.expanded) {
                return renderBuiltInCall(
                    "write",
                    args,
                    theme,
                    context,
                    new Text("", 0, 0),
                );
            }

            const text =
                context.lastComponent instanceof Text
                    ? context.lastComponent
                    : new Text("", 0, 0);
            text.setText(formatWriteCall(args, theme));
            return text;
        },
        renderResult(result: any, options: any, theme: any, context: any) {
            return (
                getBuiltInDefinitions(context.cwd).write.renderResult?.(
                    result,
                    options,
                    theme,
                    context,
                ) ?? new Container()
            );
        },
    });

    pi.registerTool({
        ...startupTools.edit,
        execute: delegateExecute("edit"),
        renderCall(args: any, theme: any, context: any) {
            if (context.expanded) {
                return renderBuiltInCall(
                    "edit",
                    args,
                    theme,
                    context,
                    new Container(),
                );
            }

            const component =
                context.lastComponent instanceof Box
                    ? context.lastComponent
                    : new Box(1, 1, (text) => theme.bg("toolPendingBg", text));
            return buildCollapsedEditCall(component, args, theme);
        },
        renderResult(result: any, options: any, theme: any, context: any) {
            const expanded = renderBuiltInExpandedResult(
                "edit",
                result,
                options,
                theme,
                context,
                new Container(),
            );
            if (expanded) return expanded;

            const component =
                context.lastComponent instanceof Container
                    ? context.lastComponent
                    : new Container();
            component.clear();
            return component;
        },
    });
}
