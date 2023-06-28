local servers = {
    rust_analyzer = {
        settings = {
            ['rust-analyzer'] = {
                inlayHints = {
                    -- These are a bit too much.
                    chainingHints = { enable = false },
                },
            },
        },
    },
    lua_ls = {
        settings = {
            Lua = {
                workspace = { checkThirdParty = false },
                telemetry = { enable = false },
                hint = { enable = true, arrayIndex = false },
                -- Disabling this since otherwise there are A LOT
                -- of progress notifications.
                window = { progressBar = false },
            },
        },
    },
    -- Markdown.
    marksman = {},
    -- TOML (mostly used for rust).
    taplo = {},
}

-- Global diagnostic setup.
-- Show a severity icon as the prefix for the virtual text and
-- disable the signs in the gutter.
vim.diagnostic.config {
    virtual_text = {
        source = 'if_many',
        prefix = function(diagnostic)
            local icons = require('helpers.icons').diagnostics
            for d, icon in pairs(icons) do
                if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
                    return icon
                end
            end
        end,
    },
    signs = false,
}

return {
    {
        'neovim/nvim-lspconfig',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = {
            'mason.nvim',
            {
                'williamboman/mason-lspconfig.nvim',
                opts = {
                    ensure_installed = vim.tbl_keys(servers),
                },
            },
            {
                'folke/neodev.nvim',
                config = true,
            },
            -- JSON schemas.
            { 'b0o/SchemaStore.nvim', version = false },
        },
        config = function()
            local on_attach = require('helpers.lsp').on_attach

            -- nvim-cmp supports additional completion capabilities, so broadcast that to servers.
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

            require('mason-lspconfig').setup_handlers {
                function(server)
                    local settings = vim.tbl_extend('force', {
                        capabilities = capabilities,
                        on_attach = on_attach,
                    }, servers[server] or {})

                    require('lspconfig')[server].setup(settings)
                end,
                clangd = function()
                    -- Fixes 'warning: multiple different client offset'.
                    local clangd_capabilities = vim.deepcopy(capabilities)
                    clangd_capabilities.offsetEncoding = 'utf-8'

                    require('lspconfig').clangd.setup {
                        capabilities = clangd_capabilities,
                        on_attach = on_attach,
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
                -- Special handler for ESLint since I don't need capabilities or on_attach.
                eslint = function()
                    require('lspconfig').eslint.setup {
                        settings = {
                            format = false,
                        },
                    }
                end,
            }
        end,
    },
}
