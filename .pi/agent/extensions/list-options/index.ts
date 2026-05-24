import { Type } from "@earendil-works/pi-ai";
import {
    DynamicBorder,
    type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import {
    Container,
    Input,
    type SelectItem,
    SelectList,
    Text,
} from "@earendil-works/pi-tui";

const ASK_QUESTION_TOOL = "ask_question";
const CUSTOM_ANSWER_LABEL = "Custom answer";
const LEGACY_CUSTOM_ANSWER_LABEL = "Other / custom answer";

type AskQuestionDetails = {
    question: string;
    answers: string[];
    answer: string | null;
    customAnswer: string | null;
    cancelled: boolean;
    ok: boolean;
};

function normalizeAnswerChoice(answer: string): string {
    return answer === LEGACY_CUSTOM_ANSWER_LABEL ? CUSTOM_ANSWER_LABEL : answer;
}

function isCustomAnswerChoice(answer: string | null): boolean {
    return (
        answer === CUSTOM_ANSWER_LABEL || answer === LEGACY_CUSTOM_ANSWER_LABEL
    );
}

function details(
    options: Partial<AskQuestionDetails> &
        Pick<AskQuestionDetails, "question" | "answers">,
): AskQuestionDetails {
    return {
        question: options.question,
        answers: options.answers,
        answer: options.answer ?? null,
        customAnswer: options.customAnswer ?? null,
        cancelled: options.cancelled ?? false,
        ok: options.ok ?? false,
    };
}

export default function (pi: ExtensionAPI) {
    pi.registerTool({
        name: ASK_QUESTION_TOOL,
        label: "List Options",
        description:
            "Ask the user a question or present a finite list of options for the user to choose from. " +
            "Use this whenever user clarification is required or whenever you would provide/propose a list of options. Include a 'Custom answer' choice when the proposed answers may not fit; the custom response is collected in the same UI.",
        parameters: Type.Object({
            question: Type.String({
                description:
                    "The question, prompt, or option-list heading to show the user.",
            }),
            answers: Type.Array(Type.String(), {
                description:
                    "Finite answer choices or proposed options to show in the interactive selection list. Include a 'Custom answer' choice when the proposed answers may not fit.",
            }),
        }) as any,

        async execute(_toolCallId, params: any, _signal, _onUpdate, ctx) {
            const question = String(params.question ?? "").trim();
            const answers = Array.isArray(params.answers)
                ? (params.answers as unknown[])
                      .map((answer) =>
                          normalizeAnswerChoice(String(answer).trim()),
                      )
                      .filter((answer) => answer.length > 0)
                : [];

            if (!question) {
                return {
                    content: [
                        {
                            type: "text",
                            text: "Error: question must be a non-empty string.",
                        },
                    ],
                    details: details({ question, answers }),
                };
            }

            if (answers.length === 0) {
                return {
                    content: [
                        {
                            type: "text",
                            text: "Error: answers must contain at least one non-empty answer choice.",
                        },
                    ],
                    details: details({ question, answers }),
                };
            }

            if (!ctx.hasUI) {
                return {
                    content: [
                        {
                            type: "text",
                            text: "Error: interactive question UI is not available in this session.",
                        },
                    ],
                    details: details({ question, answers }),
                };
            }

            const items: SelectItem[] = answers.map((answer, index) => ({
                value: String(index),
                label: answer,
            }));

            const selectedIndex = await ctx.ui.custom<string | null>(
                (tui, theme, _kb, done) => {
                    const container = new Container();
                    container.addChild(
                        new DynamicBorder((s: string) => theme.fg("accent", s)),
                    );
                    container.addChild(
                        new Text(
                            theme.fg("accent", theme.bold(question)),
                            1,
                            0,
                        ),
                    );

                    const selectList = new SelectList(
                        items,
                        Math.min(items.length, 10),
                        {
                            selectedPrefix: (t) => theme.fg("accent", t),
                            selectedText: (t) => theme.fg("accent", t),
                            description: (t) => theme.fg("muted", t),
                            scrollInfo: (t) => theme.fg("dim", t),
                            noMatch: (t) => theme.fg("warning", t),
                        },
                    );
                    selectList.onSelect = (item) => done(item.value);
                    selectList.onCancel = () => done(null);
                    container.addChild(selectList);

                    container.addChild(
                        new Text(
                            theme.fg(
                                "dim",
                                "↑↓ navigate • enter select • esc cancel",
                            ),
                            1,
                            0,
                        ),
                    );
                    container.addChild(
                        new DynamicBorder((s: string) => theme.fg("accent", s)),
                    );

                    return {
                        render: (width) => container.render(width),
                        invalidate: () => container.invalidate(),
                        handleInput: (data) => {
                            selectList.handleInput(data);
                            tui.requestRender();
                        },
                    };
                },
            );

            if (selectedIndex === null || selectedIndex === undefined) {
                return {
                    content: [
                        {
                            type: "text",
                            text: "User cancelled the question selection.",
                        },
                    ],
                    details: details({
                        question,
                        answers,
                        cancelled: true,
                        ok: true,
                    }),
                };
            }

            const selectedAnswer = answers[Number(selectedIndex)] ?? null;

            if (isCustomAnswerChoice(selectedAnswer)) {
                const customAnswer = await ctx.ui.custom<string | null>(
                    (tui, theme, _kb, done) => {
                        const container = new Container();
                        container.addChild(
                            new DynamicBorder((s: string) =>
                                theme.fg("accent", s),
                            ),
                        );
                        container.addChild(
                            new Text(
                                theme.fg("accent", theme.bold(question)),
                                1,
                                0,
                            ),
                        );
                        container.addChild(
                            new Text(theme.fg("muted", "Custom answer:"), 1, 0),
                        );

                        const input = new Input();
                        input.focused = true;
                        input.onSubmit = (value) => done(value.trim());
                        input.onEscape = () => done(null);
                        container.addChild(input);

                        container.addChild(
                            new Text(
                                theme.fg(
                                    "dim",
                                    "type answer • enter submit • esc cancel",
                                ),
                                1,
                                0,
                            ),
                        );
                        container.addChild(
                            new DynamicBorder((s: string) =>
                                theme.fg("accent", s),
                            ),
                        );

                        return {
                            render: (width) => container.render(width),
                            invalidate: () => container.invalidate(),
                            handleInput: (data) => {
                                input.handleInput(data);
                                tui.requestRender();
                            },
                        };
                    },
                );

                if (customAnswer === null || customAnswer === undefined) {
                    return {
                        content: [
                            {
                                type: "text",
                                text: "User cancelled the custom answer entry.",
                            },
                        ],
                        details: details({
                            question,
                            answers,
                            answer: CUSTOM_ANSWER_LABEL,
                            cancelled: true,
                            ok: true,
                        }),
                    };
                }

                return {
                    content: [
                        {
                            type: "text",
                            text: customAnswer
                                ? `User entered custom answer: ${customAnswer}`
                                : "User submitted an empty custom answer.",
                        },
                    ],
                    details: details({
                        question,
                        answers,
                        answer: CUSTOM_ANSWER_LABEL,
                        customAnswer,
                        ok: true,
                    }),
                };
            }

            return {
                content: [
                    {
                        type: "text",
                        text: selectedAnswer
                            ? `User selected: ${selectedAnswer}`
                            : "User selection could not be resolved.",
                    },
                ],
                details: details({
                    question,
                    answers,
                    answer: selectedAnswer,
                    ok: selectedAnswer !== null,
                }),
            };
        },
    });
}
