-- "The I in LLM stands for intelligence".
return {
    {
        'olimorris/codecompanion.nvim',
        cmd = {
            'CodeCompanion',
            'CodeCompanionChat',
            'CodeCompanionToggle',
            'CodeCompanionActions',
        },
        opts = {
            adapters = {
                openai = function()
                    return require('codecompanion.adapters').extend('openai', {
                        env = {
                            api_key = 'cmd:gpg --decrypt ~/.open_ai_key.gpg 2>/dev/null',
                        },
                        schema = {
                            model = {
                                -- Use the advanced but cheap guy.
                                default = 'gpt-4o-mini',
                            },
                        },
                    })
                end,
            },
        },
    },
}
