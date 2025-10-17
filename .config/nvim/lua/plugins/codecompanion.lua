-- "The I in LLM stands for intelligence".
return {
    {
        'olimorris/codecompanion.nvim',
        cmd = 'CodeCompanion',
        dependencies = { 'nvim-lua/plenary.nvim' },
        keys = {
            { '<leader>at', '<cmd>CodeCompanionChat Toggle<cr>', desc = 'Toggle CodeCompanion chat' },
            { '<leader>aa', '<cmd>CodeCompanionChat Add<cr>', desc = 'Add to CodeCompanion chat', mode = 'x' },
        },
        opts = {
            strategies = {
                inline = {
                    keymaps = {
                        accept_change = {
                            modes = { n = '<leader>ay' },
                            description = 'Accept the suggested change',
                        },
                        always_accept = {
                            modes = { n = '<leader>aY' },
                            description = 'Accept and enable auto mode',
                        },
                        reject_change = {
                            modes = { n = '<leader>an' },
                            description = 'Reject the suggested change',
                        },
                    },
                },
                chat = {
                    keymaps = {
                        clear = {
                            modes = { n = 'gX' },
                            description = 'Clear chat',
                        },
                    },
                },
            },
        },
    },
}
