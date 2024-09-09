-- Completion.
return {
    {
        'yioneko/nvim-cmp',
        branch = 'perf',
        dependencies = {
            {
                'L3MON4D3/LuaSnip',
                keys = {
                    {
                        '<C-r>s',
                        function()
                            require('luasnip.extras.otf').on_the_fly 's'
                        end,
                        desc = 'Insert on-the-fly snippet',
                        mode = 'i',
                    },
                },
                opts = function()
                    local types = require 'luasnip.util.types'

                    return {
                        -- Check if the current snippet was deleted.
                        delete_check_events = 'TextChanged',
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

                    -- Load my custom snippets:
                    require('luasnip.loaders.from_vscode').lazy_load {
                        paths = vim.fn.stdpath 'config' .. '/codesnippets',
                    }

                    -- Use <C-c> to select a choice in a snippet.
                    vim.keymap.set({ 'i', 's' }, '<C-c>', function()
                        if luasnip.choice_active() then
                            require 'luasnip.extras.select_choice'()
                        end
                    end, { desc = 'Select choice' })

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
            'hrsh7th/cmp-path',
            'saadparwaiz1/cmp_luasnip',
        },
        version = false,
        event = 'InsertEnter',
        opts = function()
            local cmp = require 'cmp'
            local defaults = require 'cmp.config.default'()
            local luasnip = require 'luasnip'
            local symbol_kinds = require('icons').symbol_kinds

            local winhighlight = 'Normal:Normal,FloatBorder:Normal,CursorLine:Visual,Search:None'

            return {
                preselect = cmp.PreselectMode.None,
                formatting = {
                    fields = { 'kind', 'abbr', 'menu' },
                    format = function(_, vim_item)
                        local MAX_ABBR_WIDTH, MAX_MENU_WIDTH = 25, 30
                        local ellipsis = require('icons').misc.ellipsis

                        -- Add the icon (if given a kind).
                        if vim_item.kind then
                            vim_item.kind = symbol_kinds[vim_item.kind] .. ' ' .. vim_item.kind
                        end

                        -- Truncate the label.
                        if vim.api.nvim_strwidth(vim_item.abbr) > MAX_ABBR_WIDTH then
                            vim_item.abbr = vim.fn.strcharpart(vim_item.abbr, 0, MAX_ABBR_WIDTH) .. ellipsis
                        end

                        -- Truncate the description part.
                        if vim.api.nvim_strwidth(vim_item.menu or '') > MAX_MENU_WIDTH then
                            vim_item.menu = vim.fn.strcharpart(vim_item.menu, 0, MAX_MENU_WIDTH) .. ellipsis
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
                    ['<C-f>'] = cmp.mapping.complete {
                        config = {
                            sources = { { name = 'path' } },
                        },
                    },
                    ['<cr>'] = cmp.mapping.confirm {
                        behavior = cmp.ConfirmBehavior.Replace,
                    },
                    ['/'] = cmp.mapping.close(),
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                },
                sources = cmp.config.sources({
                    -- keyword_length = 2 to not show completions with single letter identifiers.
                    { name = 'nvim_lsp', keyword_length = 2 },
                    { name = 'luasnip' },
                }, {
                    {
                        name = 'buffer',
                        keyword_length = 3,
                        option = {
                            -- Buffer completions from all visible buffers.
                            get_bufnrs = function()
                                return vim.iter(vim.api.nvim_list_wins())
                                    :map(function(win)
                                        return vim.api.nvim_win_get_buf(win)
                                    end)
                                    :totable()
                            end,
                        },
                    },
                }),
                sorting = defaults.sorting,
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
