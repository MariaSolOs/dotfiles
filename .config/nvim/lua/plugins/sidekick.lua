-- Built-in terminal for Claude.
return {
    {
        'folke/sidekick.nvim',
        opts = {
            -- Disable next-edit suggestions.
            -- TODO: Give this another chance?
            nes = { enabled = false },
            cli = { picker = 'fzf-lua' },
            mux = { create = 'split' },
        },
        keys = {
            {
                '<leader>at',
                function()
                    require('sidekick.cli').toggle { name = 'claude', focus = true }
                end,
                desc = 'Toggle Claude',
            },
            {
                '<leader>av',
                function()
                    require('sidekick.cli').send { msg = '{selection}' }
                end,
                mode = { 'x' },
                desc = 'Send visual selection to Sidekick',
            },
        },
    },
}
