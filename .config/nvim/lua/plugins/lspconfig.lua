local servers = {
    lua_ls = {
        settings = {
            Lua = {
                workspace = { checkThirdParty = false },
                telemetry = { enable = false },
                hint = { enable = true, arrayIndex = 'Disable' },
            },
        },
    },
    marksman = {},
    pyright = {},
    ruff_lsp = {},
    rust_analyzer = {},
    taplo = {},
}

vim.diagnostic.config {
    virtual_text = {
        -- Show severity icons as prefixes.
        prefix = function(diagnostic)
            local icons = require('helpers.icons').diagnostics
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
    -- Disable signs in the gutter.
    signs = false,
    float = { border = 'rounded' },
}

return {
    {
        'neovim/nvim-lspconfig',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = {
            {
                'williamboman/mason.nvim',
                cmd = 'Mason',
                config = true,
            },
            {
                'williamboman/mason-lspconfig.nvim',
                opts = {
                    ensure_installed = vim.tbl_keys(servers),
                },
            },
            { 'folke/neodev.nvim', config = true },
            -- JSON schemas.
            { 'b0o/SchemaStore.nvim', version = false },
        },
        config = function()
            local on_attach = require('helpers.lsp').on_attach

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
                    local settings = vim.tbl_extend('force', {
                        capabilities = capabilities,
                        on_attach = on_attach,
                    }, servers[server] or {})

                    require('lspconfig')[server].setup(settings)
                end,
                -- Special handler for ESLint since I don't need capabilities or on_attach.
                eslint = function()
                    require('lspconfig').eslint.setup {
                        settings = {
                            format = false,
                        },
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
