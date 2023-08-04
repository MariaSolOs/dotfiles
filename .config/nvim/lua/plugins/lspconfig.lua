vim.diagnostic.config {
    virtual_text = {
        -- Show severity icons as prefixes.
        prefix = function(diagnostic)
            local icons = require('utils.icons').diagnostics
            for d, icon in pairs(icons) do
                if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
                    return icon .. ' '
                end
            end
        end,
        -- Show only the first line of the diagnostic message.
        format = function(diagnostic)
            local newline_idx = diagnostic.message:find '\n'
            if newline_idx then
                return string.sub(diagnostic.message, 1, newline_idx - 1)
            else
                return diagnostic.message
            end
        end,
    },
    float = { border = 'rounded' },
    -- Disable signs in the gutter.
    signs = false,
}

return {
    {
        'neovim/nvim-lspconfig',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = {
            {
                'williamboman/mason.nvim',
                cmd = 'Mason',
                build = ':MasonUpdate',
                opts = {
                    ensure_installed = {
                        'black',
                        'codelldb',
                        'selene',
                        'stylua',
                    },
                    ui = {
                        border = 'rounded',
                        width = 0.7,
                        height = 0.8,
                    },
                },
            },
            {
                'williamboman/mason-lspconfig.nvim',
                opts = {
                    ensure_installed = {
                        'eslint',
                        'jsonls',
                        'lua_ls',
                        'marksman',
                        'pyright',
                        'ruff_lsp',
                        'rust_analyzer',
                        'taplo',
                    },
                },
            },
            { 'folke/neodev.nvim', config = true },
            -- JSON schemas.
            { 'b0o/SchemaStore.nvim', version = false },
        },
        config = function()
            local on_attach = require 'utils.lsp_on_attach'

            -- nvim-cmp supports additional completion capabilities, so broadcast that to servers.
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
            -- Enable folding.
            capabilities.textDocument.foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
            }

            require('mason-lspconfig').setup_handlers {
                function(server)
                    require('lspconfig')[server].setup {
                        capabilities = capabilities,
                        on_attach = on_attach,
                    }
                end,
                eslint = function()
                    require('lspconfig').eslint.setup {
                        settings = { format = false },
                    }
                end,
                jsonls = function()
                    require('lspconfig').jsonls.setup {
                        capabilities = capabilities,
                        on_attach = on_attach,
                        settings = {
                            json = {
                                schemas = require('schemastore').json.schemas(),
                                validate = { enable = true },
                            },
                        },
                    }
                end,
                lua_ls = function()
                    require('lspconfig').lua_ls.setup {
                        capabilities = capabilities,
                        on_attach = on_attach,
                        settings = {
                            Lua = {
                                workspace = { checkThirdParty = false },
                                telemetry = { enable = false },
                                hint = { enable = true, arrayIndex = 'Disable' },
                            },
                        },
                    }
                end,
                ruff_lsp = function()
                    require('lspconfig').ruff_lsp.setup {
                        on_attach = function(client, bufnr)
                            -- Disable hover in favor of pyright.
                            client.server_capabilities.hoverProvider = false

                            on_attach(client, bufnr)
                        end,
                    }
                end,
            }
        end,
    },
}
