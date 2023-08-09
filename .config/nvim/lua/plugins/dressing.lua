-- Select and input UI.
return {
    {
        'stevearc/dressing.nvim',
        lazy = true,
        init = function()
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.ui.select = function(...)
                require('lazy').load { plugins = { 'dressing.nvim' } }
                return vim.ui.select(...)
            end
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.ui.input = function(...)
                require('lazy').load { plugins = { 'dressing.nvim' } }
                return vim.ui.input(...)
            end
        end,
        config = function()
            require('dressing').setup {
                input = {
                    win_options = {
                        -- Use a purple-ish border.
                        winhighlight = 'FloatBorder:LspFloatWinBorder',
                    },
                },
                select = {
                    -- Use a relative window with code actions.
                    get_config = function(opts)
                        if opts.kind == 'codeaction' then
                            return {
                                telescope = require('telescope.themes').get_cursor(),
                            }
                        end
                    end,
                },
            }
        end,
    },
}
