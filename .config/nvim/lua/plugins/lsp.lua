local servers = {
    lua_ls = {
        settings = {
            Lua = {
                workspace = { checkThirdParty = false },
                telemetry = { enable = false },
            },
        },
    },
    jdtls = {},
    marksman = {},
    tsserver = {},
}

local on_attach = function(_, bufnr)
    local nmap = function(lhs, rhs, desc)
        require('helpers.keybindings').nmap(lhs, rhs, { buffer = bufnr, desc = desc })
    end

    nmap('<leader>c', ':Lspsaga code_action<cr>', 'Code action')
    nmap('<leader>o', ':Lspsaga outline<cr>', 'Toggle outline')
    nmap('<leader>r', function()
        return ':IncRename ' .. vim.fn.expand '<cword>'
    end, 'Rename')

    nmap('<leader>ss', require('telescope.builtin').lsp_document_symbols, 'Search document symbols')
    nmap('<leader>sw', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Search workspace symbols')

    nmap('gd', ':Lspsaga goto_definition<cr>', 'Go to definition')
    nmap('gD', ':Lspsaga lsp_finder<cr>', 'Go to symbol definition')
    nmap('gr', require('telescope.builtin').lsp_references, 'Go to references')

    -- noice deals with the UI.
    nmap('K', vim.lsp.buf.hover, 'Hover')

    nmap('[d', ':Lspsaga diagnostic_jump_prev<cr>', 'Previous diagnostic')
    nmap(']d', ':Lspsaga diagnostic_jump_next<cr>', 'Next diagnostic')

    -- Toggle the floating terminal.
    -- NOTE: The <cmd> below is needed to exit terminal mode.
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
                config = function()
                    require('mason').setup()
                    -- Ensure the servers above are installed.
                    require('mason-lspconfig').setup {
                        ensure_installed = vim.tbl_keys(servers),
                    }
                end,
            },
            { 'williamboman/mason-lspconfig.nvim', lazy = true },
            { 'folke/neodev.nvim',                 lazy = true },
            { 'b0o/SchemaStore.nvim',              version = false },
        },
        config = function()
            -- Setup neovim lua configuration.
            require('neodev').setup()

            -- nvim-cmp supports additional completion capabilities, so broadcast that to servers.
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

            require('mason-lspconfig').setup_handlers {
                function(server)
                    local settings = vim.tbl_extend('force', {
                        capabilities = vim.deepcopy(capabilities),
                        on_attach = on_attach,
                    }, servers[server] or {})

                    require('lspconfig')[server].setup(settings)
                end,
                clangd = function()
                    capabilities = vim.deepcopy(capabilities)
                    -- Fixes the 'warning: multiple different client offset' error.
                    capabilities.offsetEncoding = 'utf-8'

                    require('lspconfig').clangd.setup {
                        capabilities = capabilities,
                        on_attach = on_attach,
                    }
                end,
                jsonls = function()
                    require('lspconfig').jsonls.setup {
                        capabilities = vim.deepcopy(capabilities),
                        on_attach = on_attach,
                        settings = {
                            json = {
                                schemas = require('schemastore').json.schemas(),
                                validate = { enable = true },
                            },
                        },
                    }
                end,
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
            finder = {
                keys = {
                    jump_to = '<Tab>',
                    expand_or_jump = '<cr>',
                },
            },
        },
    },

    -- Rename with preview spans.
    {
        'smjonas/inc-rename.nvim',
        config = true,
        cmd = 'IncRename',
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
