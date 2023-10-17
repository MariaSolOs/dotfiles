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
                        snip_env = {
                            -- Helper function for showing a snippet if the Treesitter node
                            -- satisfies a given predicate.
                            ts_show = function(pred)
                                return function()
                                    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                                    local ok, node = pcall(vim.treesitter.get_node, { pos = { row - 1, col - 1 } })

                                    -- Show the snippet if Treesitter bails.
                                    if not ok or not node then
                                        return true
                                    end

                                    return pred(node:type())
                                end
                            end,
                        },
                    }
                end,
                config = function(_, opts)
                    local luasnip = require 'luasnip'

                    luasnip.setup(opts)

                    -- Use <C-c> to select a choice in a snippet.
                    vim.keymap.set({ 'i', 's' }, '<C-c>', function()
                        if luasnip.choice_active() then
                            require 'luasnip.extras.select_choice'()
                        end
                    end, { desc = 'Select choice' })

                    -- Load my snippets and the ones from VSCode.
                    require('luasnip.loaders.from_vscode').lazy_load()

                    require('luasnip.loaders.from_lua').lazy_load {
                        paths = {
                            -- Load local snippets if present.
                            vim.fn.getcwd() .. '/.luasnippets',
                            -- Global snippets.
                            vim.fn.stdpath 'config' .. '/luasnippets',
                        },
                    }

                    vim.api.nvim_create_autocmd('ModeChanged', {
                        group = vim.api.nvim_create_augroup('mariasolos/unlink_snippet', { clear = true }),
                        desc = 'Cancel the snippet session when leaving insert mode',
                        pattern = { 's:n', 'i:*' },
                        callback = function(args)
                            if
                                luasnip.session
                                and luasnip.session.current_nodes[args.buf]
                                and not luasnip.session.jump_active
                                and not luasnip.choice_active()
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
            local compare = require 'cmp.config.compare'
            local luasnip = require 'luasnip'
            local symbol_kinds = require('icons').symbol_kinds

            local winhighlight = 'Normal:Normal,FloatBorder:Normal,CursorLine:Visual,Search:None'

            return {
                -- Disable preselect. On enter, the first thing will be used if nothing
                -- is selected.
                preselect = cmp.PreselectMode.None,
                formatting = {
                    fields = { 'kind', 'abbr', 'menu' },
                    format = function(_, vim_item)
                        local MAX_ABBR_WIDTH, MAX_MENU_WIDTH = 25, 30
                        local ELLIPSIS = '…'

                        -- Add the icon.
                        vim_item.kind = (symbol_kinds[vim_item.kind] or symbol_kinds.Text) .. ' ' .. vim_item.kind

                        -- Truncate the label.
                        if vim.api.nvim_strwidth(vim_item.abbr) > MAX_ABBR_WIDTH then
                            vim_item.abbr = vim.fn.strcharpart(vim_item.abbr, 0, MAX_ABBR_WIDTH) .. ELLIPSIS
                        end

                        -- Truncate the description part.
                        if vim.api.nvim_strwidth(vim_item.menu or '') > MAX_MENU_WIDTH then
                            vim_item.menu = vim.fn.strcharpart(vim_item.menu, 0, MAX_MENU_WIDTH) .. ELLIPSIS
                        end

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
                    ['<cr>'] = cmp.mapping.confirm {
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
                },
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' },
                }, {
                    { name = 'buffer', keyword_length = 4 },
                }),
                sorting = {
                    comparators = {
                        compare.offset,
                        compare.exact,
                        compare.score,
                        compare.recently_used,
                        compare.sort_text,
                        compare.length,
                    },
                },
            }
        end,
        config = function(_, opts)
            local cmp = require 'cmp'

            -- Override the documentation handler to remove the redundant detail section.
            ---@diagnostic disable-next-line: duplicate-set-field
            require('cmp.entry').get_documentation = function(self)
                local item = self:get_completion_item()

                if item.documentation then
                    return vim.lsp.util.convert_input_to_markdown_lines(item.documentation)
                end

                -- Use the item's detail as a fallback if there's no documentation.
                if item.detail then
                    local ft = self.context.filetype
                    local dot_index = string.find(ft, '%.')
                    if dot_index ~= nil then
                        ft = string.sub(ft, 0, dot_index - 1)
                    end
                    return (vim.split(('```%s\n%s```'):format(ft, vim.trim(item.detail)), '\n'))
                end

                return {}
            end

            -- Inside a snippet, use backspace to remove the placeholder.
            vim.keymap.set('s', '<BS>', '<C-O>s')

            cmp.setup(opts)
        end,
    },
}
