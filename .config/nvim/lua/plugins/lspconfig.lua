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
        -- Show only the first line of each diagnostic.
        format = function(diagnostic)
            local lines = vim.split(diagnostic.message, '\n')
            return lines[1]
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
                        'codelldb',
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
            -- JSON schemas.
            { 'b0o/SchemaStore.nvim', version = false },
        },
        config = function()
            local lspconfig = require 'lspconfig'
            local on_attach = require 'utils.lsp_on_attach'

            -- nvim-cmp supports additional completion capabilities, so broadcast that to servers.
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

            -- Enable folding.
            capabilities.textDocument.foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
            }

            -- I like rounded borders ok??
            require('lspconfig.ui.windows').default_options.border = 'rounded'

            -- Set up EFM for general formatters.
            local languages = {
                lua = {
                    {
                        formatCommand = string.format(
                            '%s ${--range-start:charStart} ${--range-end:charEnd} --color Never -',
                            vim.fn.exepath 'stylua'
                        ),
                        formatStdin = true,
                        formatCanRange = true,
                        rootMarkers = { 'stylua.toml', '.stylua.toml' },
                    },
                },
            }
            lspconfig.efm.setup {
                init_options = { documentFormatting = true },
                filetypes = vim.tbl_keys(languages),
                settings = {
                    rootMarkers = { '.git' },
                    languages = languages,
                },
            }

            require('mason-lspconfig').setup_handlers {
                function(server)
                    lspconfig[server].setup {
                        capabilities = capabilities,
                        on_attach = on_attach,
                    }
                end,
                eslint = function()
                    lspconfig.eslint.setup {
                        settings = { format = false },
                    }
                end,
                jsonls = function()
                    lspconfig.jsonls.setup {
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
                    lspconfig.lua_ls.setup {
                        capabilities = capabilities,
                        on_attach = on_attach,
                        on_init = function(client)
                            local path = client.workspace_folders[1].name
                            if
                                not vim.uv.fs_stat(path .. '/.luarc.json')
                                and not vim.uv.fs_stat(path .. '/.luarc.jsonc')
                            then
                                -- Make the server aware of Neovim runtime files
                                client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
                                    Lua = {
                                        runtime = { version = 'LuaJIT' },
                                        workspace = {
                                            checkThirdParty = false,
                                            library = {
                                                vim.env.VIMRUNTIME,
                                                '${3rd}/luv/library',
                                            },
                                        },
                                    },
                                })
                                client.notify(vim.lsp.protocol.Methods.workspace_didChangeConfiguration, {
                                    settings = client.config.settings,
                                })
                            end
                        end,
                        settings = {
                            Lua = {
                                telemetry = { enable = false },
                                hint = {
                                    enable = true,
                                    arrayIndex = 'Disable',
                                },
                            },
                        },
                    }
                end,
                ruff_lsp = function()
                    lspconfig.ruff_lsp.setup {
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
