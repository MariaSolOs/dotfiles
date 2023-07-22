-- Managing crate dependencies.
return {
    {
        'Saecki/crates.nvim',
        event = 'BufRead Cargo.toml',
        opts = {
            popup = { border = 'rounded' },
        },
        config = function(_, opts)
            local crates = require 'crates'

            crates.setup(opts)

            local keymap = function(key, rhs, desc)
                vim.keymap.set('n', '<leader>c' .. key, function()
                    rhs()
                    crates.focus_popup()
                end, { desc = desc, silent = true })
            end
            keymap('c', crates.show_crate_popup, 'Show crate popup')
            keymap('f', crates.show_features_popup, 'Show features popup')
            keymap('v', crates.show_versions_popup, 'Show versions popup')
        end,
    },
}
