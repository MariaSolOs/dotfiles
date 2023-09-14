-- Select and input UI.
return {
    {
        'stevearc/dressing.nvim',
        keys = {
            -- Use dressing for spelling suggestions.
            {
                'z=',
                function()
                    vim.ui.select(
                        vim.fn.spellsuggest(vim.fn.expand '<cword>'),
                        {},
                        vim.schedule_wrap(function(selected)
                            if selected then
                                vim.cmd.normal { args = { 'ciw' .. selected }, bang = true }
                            end
                        end)
                    )
                end,
            },
        },
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
                    mappings = { ['q'] = 'Close' },
                    win_options = {
                        -- Same UI as the input field.
                        -- TODO: Remove the MatchParen highlight when https://github.com/neovim/neovim/pull/25096 gets merged.
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
    },
}
