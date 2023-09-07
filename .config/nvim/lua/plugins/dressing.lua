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
                    winblend = 5,
                },
            },
            select = {
                backend = { 'fzf_lua', 'builtin' },
                trim_prompt = false,
                fzf_lua = {
                    winopts = {
                        height = 0.6,
                        width = 0.5,
                    },
                },
                builtin = {
                    mappings = {
                        ['q'] = 'Close',
                    },
                    win_options = {
                        -- Same UI as the input field.
                        winhighlight = 'FloatBorder:LspFloatWinBorder,DressingSelectIdx:LspInfoTitle,MatchParen:Ignore',
                        winblend = 5,
                    },
                },
                get_config = function(opts)
                    if opts.kind == 'codeaction' then
                        -- Cute and compact code action menu.
                        return {
                            backend = 'builtin',
                            builtin = {
                                relative = 'cursor',
                                max_height = 0.33,
                                min_height = 5,
                                max_width = 0.40,
                            },
                        }
                    end
                end,
            },
        },
    },
}
