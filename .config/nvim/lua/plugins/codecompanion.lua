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
            strategies = {
                inline = {
                    keymaps = {
                        accept_change = {
                            modes = { n = '<leader>ca' },
                            description = 'Accept the suggested change',
                        },
                        reject_change = {
                            modes = { n = '<leader>cr' },
                            description = 'Reject the suggested change',
                        },
                    },
                },
            },
        },
    },
}
