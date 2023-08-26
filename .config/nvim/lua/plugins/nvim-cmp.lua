local symbol_kinds = require('icons').symbol_kinds

-- Completion.
return {
    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            {
                'L3MON4D3/LuaSnip',
                opts = function()
                    local types = require 'luasnip.util.types'

                    return {
                        -- Display a cursor-like placeholder in unvisited nodes
                        -- of the snippet.
                        ext_opts = {
                            [types.insertNode] = {
                                unvisited = {
                                    virt_text = { { '|', 'Conceal' } },
                                    virt_text_pos = 'inline',
                                },
                            },
                            [types.exitNode] = {
                                unvisited = {
                                    virt_text = { { '|', 'Conceal' } },
                                    virt_text_pos = 'inline',
                                },
                            },
                        },
                    }
                end,
                config = function(_, opts)
                    local luasnip = require 'luasnip'

                    luasnip.setup(opts)
                    require('luasnip.loaders.from_vscode').lazy_load()

                    -- HACK: Cancel the snippet session when leaving insert mode.
                    vim.api.nvim_create_autocmd('ModeChanged', {
                        group = vim.api.nvim_create_augroup('UnlinkSnippetOnModeChange', { clear = true }),
                        pattern = { 's:n', 'i:*' },
                        callback = function(event)
                            if
                                luasnip.session
                                and luasnip.session.current_nodes[event.buf]
                                and not luasnip.session.jump_active
                            then
                                luasnip.unlink_current()
                            end
                        end,
                    })
                end,
            },
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-nvim-lsp',
            'saadparwaiz1/cmp_luasnip',
        },
        version = false,
        event = 'InsertEnter',
        opts = function()
            local cmp = require 'cmp'
            local luasnip = require 'luasnip'

            local winhighlight = 'Normal:Normal,FloatBorder:Normal,CursorLine:Visual,Search:None'

            return {
                -- Disable preselect. On enter, the first thing will be used if nothing
                -- is selected.
                preselect = cmp.PreselectMode.None,
                formatting = {
                    format = function(_, vim_item)
                        local ABBR_WIDTH, MAX_MENU_WIDTH, ELLIPSIS = 20, 25, '…'

                        -- Truncate the label, or pad it if it's too short.
                        local label, len = vim_item.abbr, vim.api.nvim_strwidth(vim_item.abbr)
                        if len < ABBR_WIDTH then
                            vim_item.abbr = label .. string.rep(' ', ABBR_WIDTH - len)
                        elseif len > ABBR_WIDTH then
                            vim_item.abbr = vim.fn.strcharpart(label, 0, ABBR_WIDTH) .. ELLIPSIS
                        end

                        -- Truncate the description part.
                        local menu = vim_item.menu
                        if menu and vim.api.nvim_strwidth(menu) > MAX_MENU_WIDTH then
                            vim_item.menu = vim.fn.strcharpart(menu, 0, MAX_MENU_WIDTH) .. ELLIPSIS
                        end

                        -- Add the icon.
                        vim_item.kind = (symbol_kinds[vim_item.kind] or '') .. '  ' .. vim_item.kind

                        return vim_item
                    end,
                },
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                window = {
                    completion = {
                        border = 'rounded',
                        winhighlight = winhighlight,
                        scrollbar = true,
                    },
                    documentation = {
                        border = 'rounded',
                        winhighlight = winhighlight,
                        max_height = math.floor(vim.o.lines * 0.5),
                        max_width = math.floor(vim.o.columns * 0.4),
                    },
                },
                mapping = cmp.mapping.preset.insert {
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<CR>'] = cmp.mapping.confirm {
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    },
                    -- Explicitly request completions.
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['/'] = cmp.mapping.close(),
                    -- Overload tab to accept Copilot suggestions.
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        local copilot = require 'copilot.suggestion'

                        if copilot.is_visible() then
                            copilot.accept()
                        elseif cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                    ['<S-Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.expand_or_locally_jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                    ['<C-d>'] = function()
                        if cmp.visible_docs() then
                            cmp.close_docs()
                        else
                            cmp.open_docs()
                        end
                    end,
                },
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' },
                }, {
                    { name = 'buffer', keyword_length = 4 },
                }),
            }
        end,
        config = function(_, opts)
            local cmp = require 'cmp'

            -- Inside a snippet, use backspace to remove the placeholder.
            vim.keymap.set('s', '<BS>', '<C-O>s')

            cmp.setup(opts)
        end,
    },
}
