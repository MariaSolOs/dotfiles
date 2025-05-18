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
        opts = function()
            local config = require('codecompanion.config').config

            local diff_opts = config.display.diff.opts
            table.insert(diff_opts, 'context:99') -- Setting the context to a very large number disables folding.

            return {
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
                display = {
                    diff = { opts = diff_opts },
                },
            }
        end,
    },
}
