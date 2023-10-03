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
                    -- Add a colon to the prompt if it doesn't have one.
                    if opts.prompt and not opts.prompt:match ':%s*$' then
                        opts.prompt = opts.prompt .. ': '
                    end

                    if opts.kind == 'luasnip' then
                        -- Smaller menu for snippet choices.
                        return {
                            backend = 'fzf_lua',
                            fzf_lua = {
                                winopts = {
                                    height = 0.35,
                                    width = 0.3,
                                },
                            },
                        }
                    end

                    if opts.kind == 'codeaction' or opts.kind == 'codelens' then
                        -- Cute and compact menu.
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

                    -- Default selector.
                    return {
                        backend = 'fzf_lua',
                        fzf_lua = {
                            winopts = {
                                height = 0.6,
                                width = 0.5,
                            },
                        },
                    }
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
