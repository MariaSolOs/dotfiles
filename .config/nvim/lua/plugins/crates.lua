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

            -- Lazily load the completion source.
            vim.api.nvim_create_autocmd('BufRead', {
                group = vim.api.nvim_create_augroup('CmpSourceCargo', { clear = true }),
                pattern = 'Cargo.toml',
                callback = function()
                    ---@diagnostic disable-next-line: missing-fields
                    require('cmp').setup.buffer { sources = { { name = 'crates' } } }
                end,
            })

            local function keymap(key, rhs, desc)
                vim.keymap.set('n', '<leader>c' .. key, function()
                    rhs()
                    crates.focus_popup()
                end, { desc = desc })
            end
            keymap('c', crates.show_crate_popup, 'Show crate popup')
            keymap('f', crates.show_features_popup, 'Show features popup')
            keymap('v', crates.show_versions_popup, 'Show versions popup')
        end,
    },
}
