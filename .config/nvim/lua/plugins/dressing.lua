-- Select and input UI.
return {
    {
        'stevearc/dressing.nvim',
        lazy = true,
        opts = {
            input = {
                win_options = {
                    -- Use a purple-ish border.
                    winhighlight = 'FloatBorder:LspFloatWinBorder',
                    winblend = 5,
                },
            },
            select = {
                trim_prompt = false,
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
                                mappings = { ['q'] = 'Close' },
                                win_options = {
                                    -- Same UI as the input field.
                                    winhighlight = 'FloatBorder:LspFloatWinBorder,DressingSelectIdx:LspInfoTitle,MatchParen:Ignore',
                                    winblend = 5,
                                },
                            },
                        }
                    end

                    local winopts = { height = 0.6, width = 0.5 }

                    -- Fallback to fzf-lua.
                    return {
                        backend = 'fzf_lua',
                        fzf_lua = { winopts = winopts },
                    }
                end,
            },
        },
        init = function()
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.ui.select = function(items, opts, on_choice)
                if not package.loaded['dressing.nvim'] then
                    require('lazy').load { plugins = { 'dressing.nvim' } }
                end
                -- Don't show the picker if there's nothing to pick.
                if #items > 0 then
                    return vim.ui.select(items, opts, on_choice)
                end
            end
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.ui.input = function(...)
                if not package.loaded['dressing.nvim'] then
                    require('lazy').load { plugins = { 'dressing.nvim' } }
                end
                return vim.ui.input(...)
            end
        end,
    },
}
