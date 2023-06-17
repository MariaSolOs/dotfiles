-- Enable the following language servers.
local servers = {
    lua_ls = {
        Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
        },
    },
    jdtls = {},
    tsserver = {},
}

local on_attach = function(_, bufnr)
    local nmap = function(keys, func, desc)
        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end

    nmap('<leader>r', '<cmd>Lspsaga rename<cr>', 'Rename')
    nmap('<leader>c', '<cmd>Lspsaga code_action<cr>', 'Code action')
    nmap('<leader>o', '<cmd>Lspsaga outline<cr>', 'Toggle outline')

    nmap('<leader>ss', require('telescope.builtin').lsp_document_symbols, 'Search document symbols')
    nmap('<leader>sw', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Search workspace symbols')

    nmap('gd', '<cmd>Lspsaga goto_definition<cr>', 'Go to definition')
    nmap('gr', require('telescope.builtin').lsp_references, 'Go to references')
    nmap('gI', vim.lsp.buf.implementation, 'Go to implementation')
    nmap('gD', vim.lsp.buf.declaration, 'Go to declaration')
    nmap('gt', vim.lsp.buf.type_definition, 'Go to type definition')

    -- noice deals with the UI.
    nmap('K', vim.lsp.buf.hover, 'Hover')

    nmap('[d', '<cmd>Lspsaga diagnostic_jump_prev<cr>', 'Previous diagnostic')
    nmap(']d', '<cmd>Lspsaga diagnostic_jump_next<cr>', 'Next diagnostic')

    -- Toggle the floating terminal.
    vim.keymap.set({ 'n', 't' }, '<M-t>', '<cmd>Lspsaga term_toggle<cr>', { desc = 'Toggle floating terminal' })

    -- Create a command `:Fmt` local to the LSP buffer
    vim.api.nvim_buf_create_user_command(bufnr, 'Fmt', function(_)
        vim.lsp.buf.format()
    end, { desc = 'Format current buffer' })
end

return {
    {
        'neovim/nvim-lspconfig',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = {
            {
                'williamboman/mason.nvim',
                cmd = { 'Mason', 'LspInstall', 'LspUnInstall' },
                config = function(_, _)
                    require('mason').setup()
                    -- Ensure the servers above are installed.
                    require('mason-lspconfig').setup {
                        ensure_installed = vim.tbl_keys(servers),
                    }
                end,
            },
            { 'williamboman/mason-lspconfig.nvim', lazy = true },
            { 'folke/neodev.nvim',                 lazy = true },
        },
        config = function()
            -- Setup neovim lua configuration.
            require('neodev').setup()

            -- nvim-cmp supports additional completion capabilities, so broadcast that to servers.
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

            require('mason-lspconfig').setup_handlers {
                function(server_name)
                    require('lspconfig')[server_name].setup {
                        capabilities = capabilities,
                        on_attach = on_attach,
                        settings = servers[server_name],
                    }
                end,
                -- idk why but I need to configure rust-tools separately.
                rust_analyzer = function()
                    require('rust-tools').setup {
                        tools = {
                            inlay_hints = {
                                other_hints_prefix = '',
                                parameter_hints_prefix = '',
                                show_parameter_hints = false,
                            },
                        },
                        server = {
                            capabilities = capabilities,
                            on_attach = on_attach,
                        },
                    }
                end,
            }
        end,
    },

    -- Extra goodies for rust.
    { 'simrat39/rust-tools.nvim' },

    -- Nicer UI.
    {
        'glepnir/lspsaga.nvim',
        cmd = 'Lspsaga',
        dependencies = {
            { 'nvim-tree/nvim-web-devicons' },
            { 'nvim-treesitter/nvim-treesitter' },
        },
        opts = {
            ui = {
                border = 'rounded',
                code_action = '',
            },
            outline = {
                keys = {
                    expand_or_jump = '<cr>',
                },
                auto_resize = true,
            },
        },
    },

    -- Use Neovim as a language server.
    {
        'jose-elias-alvarez/null-ls.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        event = 'VeryLazy',
        config = function()
            local null_ls = require 'null-ls'
            null_ls.setup {
                sources = {
                    null_ls.builtins.code_actions.gitsigns,
                    null_ls.builtins.formatting.stylua,
                },
            }
        end,
    },
}
