import { homedir } from "node:os";
import * as Pi from "@earendil-works/pi-coding-agent";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
    getLanguageFromPath,
    highlightCode,
} from "@earendil-works/pi-coding-agent";
import {
    Container,
    Text,
    truncateToWidth,
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

function createFallbackBuiltInDefinitions(cwd: string) {
    return {
        read: Pi.createReadToolDefinition(cwd),
        ls: Pi.createLsToolDefinition(cwd),
        grep: Pi.createGrepToolDefinition(cwd),
        find: Pi.createFindToolDefinition(cwd),
        write: Pi.createWriteToolDefinition(cwd),
        edit: Pi.createEditToolDefinition(cwd),
        bash: Pi.createBashToolDefinition(cwd),
    };
}

type BuiltInDefinitions = ReturnType<typeof createFallbackBuiltInDefinitions>;

function createBuiltInDefinitions(cwd: string): BuiltInDefinitions {
    // Built-in definitions are cwd-aware; cache one set per working directory and
    // delegate execution to them so this extension only owns preview rendering.
    const createAllToolDefinitions = (
        Pi as typeof Pi & {
            createAllToolDefinitions?: (cwd: string) => BuiltInDefinitions;
        }
    ).createAllToolDefinitions;
    return (
        createAllToolDefinitions?.(cwd) ?? createFallbackBuiltInDefinitions(cwd)
    );
}

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

function previewLineArray(
    lines: string[],
    theme: ThemeLike,
    options: { lang?: string; colorPlain?: boolean } = {},
): string[] {
    const trimmed = trimTrailingEmptyLines(lines);
    if (trimmed.length === 0) return [];

    const hasMore = trimmed.length > PREVIEW_LINES;
    const contentLineCount = hasMore
        ? Math.max(0, PREVIEW_LINES - 1)
        : PREVIEW_LINES;
    const displayLines = trimmed.slice(0, contentLineCount);
    const remaining = trimmed.length - displayLines.length;

    const output = displayLines.map((line) => {
        if (options.lang) return line;
        return options.colorPlain === false
            ? line
            : theme.fg("toolOutput", replaceTabs(line));
    });

    if (remaining > 0) {
        output.push(moreLinesMessage(remaining, theme));
    }

    return output;
}

function previewLines(
    lines: string[],
    theme: ThemeLike,
    options: { lang?: string; colorPlain?: boolean } = {},
): string {
    return previewLineArray(lines, theme, options).join("\n");
}

function minimalTextPreviewLines(result: any, theme: ThemeLike): string[] {
    return previewLineArray(textOutput(result).trim().split("\n"), theme);
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

class MinimalTextResultPreviewComponent implements Component {
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
        // The collapsed preview must stay within PREVIEW_LINES terminal rows.
        // Text wraps long grep matches, so render directly and truncate instead.
        return minimalTextPreviewLines(this.result, this.theme).map((line) =>
            truncateToWidth(line, Math.max(1, width)),
        );
    }
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

            const component =
                context.lastComponent instanceof
                MinimalTextResultPreviewComponent
                    ? context.lastComponent
                    : new MinimalTextResultPreviewComponent(result, theme);
            component.set(result, theme);
            return component;
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
            return renderBuiltInCall(
                "edit",
                args,
                theme,
                context,
                new Container(),
            );
        },
        renderResult(result: any, options: any, theme: any, context: any) {
            return (
                getBuiltInDefinitions(context.cwd).edit.renderResult?.(
                    result,
                    options,
                    theme,
                    context,
                ) ?? new Container()
            );
        },
    });
}
