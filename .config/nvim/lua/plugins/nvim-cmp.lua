-- Icons to use in the completion menu.
-- These are the ones that VSCode uses.
local cmp_kinds = {
    Text = '  ',
    Method = '  ',
    Function = '  ',
    Constructor = '  ',
    Field = '  ',
    Variable = '  ',
    Class = '  ',
    Interface = '  ',
    Module = '  ',
    Property = '  ',
    Unit = '  ',
    Value = '  ',
    Enum = '  ',
    Keyword = '  ',
    Snippet = '  ',
    Color = '  ',
    File = '  ',
    Reference = '  ',
    Folder = '  ',
    EnumMember = '  ',
    Constant = '  ',
    Struct = '  ',
    Event = '  ',
    Operator = '  ',
    TypeParameter = '  ',
    Copilot = '  ',
}

return {
    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            {
                'L3MON4D3/LuaSnip',
                config = function()
                    local types = require 'luasnip.util.types'

                    require('luasnip.loaders.from_vscode').lazy_load()

                    require('luasnip').setup {
                        history = true,
                        delete_check_events = 'TextChanged',
                        -- Display a cursor-like placeholder in unvisited nodes
                        -- of the snippet.
                        ext_opts = {
                            [types.insertNode] = {
                                unvisited = {
                                    virt_text = { { '|', 'Conceal' } },
                                    virt_text_pos = 'inline',
                                },
                                snippet_passive = {
                                    hl_group = 'None',
                                },
                            },
                        },
                    }
                end,
            },
            {
                'Saecki/crates.nvim',
                event = 'BufRead Cargo.toml',
                config = true,
            },
            'saadparwaiz1/cmp_luasnip',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
        },
        version = false,
        event = 'InsertEnter',
        config = function()
            local cmp = require 'cmp'
            local luasnip = require 'luasnip'

            -- Inside a snippet, use backspace to remove the placeholder.
            vim.keymap.set('s', '<BS>', '<C-O>s', { silent = true })

            cmp.setup {
                -- Disable preselect. On enter, the first thing will be used if nothing
                -- is selected.
                preselect = cmp.PreselectMode.None,
                -- Add icons to the completion menu.
                formatting = {
                    format = function(_, vim_item)
                        vim_item.kind = (cmp_kinds[vim_item.kind] or '') .. vim_item.kind
                        return vim_item
                    end,
                },
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                window = {
                    -- Make the completion menu bordered.
                    completion = cmp.config.window.bordered(),
                    -- Disable the documentation popup. It gets too cluttered.
                    -- TODO: Make this toggleable.
                    documentation = cmp.config.disable,
                },
                mapping = cmp.mapping.preset.insert {
                    -- ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    -- ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<CR>'] = cmp.mapping.confirm {
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    },
                    -- Explicitly request completions.
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['/'] = cmp.mapping.abort(),
                    -- Overload tab to accept Copilot suggestions.
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        local copilot = require 'copilot.suggestion'
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif copilot.is_visible() then
                            copilot.accept()
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
                sources = {
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' },
                    { name = 'buffer' },
                    { name = 'crates' },
                },
            }
        end,
    },
}
