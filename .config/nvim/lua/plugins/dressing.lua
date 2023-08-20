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
        opts = {
            input = {
                win_options = {
                    -- Use a purple-ish border.
                    winhighlight = 'FloatBorder:LspFloatWinBorder',
                },
            },
            select = {
                backend = 'fzf_lua',
                trim_prompt = false,
                fzf_lua = {
                    winopts = {
                        height = 0.6,
                        width = 0.5,
                    },
                },
                get_config = function(opts)
                    if opts.kind == 'codeaction' then
                        return {
                            -- Cute and compact code action menu.
                            fzf_lua = {
                                winopts = {
                                    relative = 'cursor',
                                    row = 1,
                                    height = 0.33,
                                    width = 0.40,
                                },
                            },
                        }
                    end
                end,
            },
        },
    },
}
