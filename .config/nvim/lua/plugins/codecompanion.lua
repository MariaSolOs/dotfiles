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
                            api_key = 'cmd:bws secret get f3a6ad3d-2382-45f2-9dc6-b1e7001e769c | jq -r .value',
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
