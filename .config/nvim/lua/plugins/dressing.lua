-- Select and input UI.
-- TODO: Replace this with something else now that the plugin got archived.
return {
    {
        'stevearc/dressing.nvim',
        lazy = true,
        opts = {
            select = {
                trim_prompt = false,
                get_config = function(opts)
                    local winopts = { height = 0.6, width = 0.5 }

                    -- Smaller menu for snippet choices.
                    if opts.kind == 'luasnip' then
                        opts.prompt = 'Snippet choice: '
                        winopts = {
                            relative = 'cursor',
                            height = 0.35,
                            width = 0.3,
                        }
                    end

                    -- Smaller menu for messages from LSP select requests.
                    if opts.kind == 'lsp_message' then
                        winopts = { height = 0.3, width = 0.3 }
                    end

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
        end,
    },
}
