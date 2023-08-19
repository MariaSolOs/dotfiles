local diagnostic_icons = require('utils.icons').diagnostics

vim.diagnostic.config {
    virtual_text = {
        -- Show severity icons as prefixes.
        prefix = function(diagnostic)
            return diagnostic_icons[vim.diagnostic.severity[diagnostic.severity]] .. ' '
        end,
        -- Show only the first line of each diagnostic.
        format = function(diagnostic)
            local lines = vim.split(diagnostic.message, '\n')
            return lines[1]
        end,
    },
    float = {
        border = 'rounded',
        source = 'if_many',
        -- Show severity icons as prefixes.
        prefix = function(diag)
            local level = vim.diagnostic.severity[diag.severity]
            local prefix = string.format(' %s ', diagnostic_icons[level])
            return prefix, 'Diagnostic' .. level:gsub('^%l', string.upper)
        end,
    },
    -- Disable signs in the gutter.
    signs = false,
}

-- Neovim does not currently correctly report the related locations for diagnostics.
-- TODO: Remove this hack if https://github.com/neovim/neovim/issues/19649 gets fixed.
local publish_diagnostic = vim.lsp.protocol.Methods.textDocument_publishDiagnostics
local original_handler = vim.lsp.handlers[publish_diagnostic]
vim.lsp.handlers[publish_diagnostic] = function(err, result, ctx, config)
    result.diagnostics = vim.tbl_map(function(diag)
        if not diag.relatedInformation or diag.relatedInformation == 0 then
            return diag
        end

        for _, info in ipairs(diag.relatedInformation) do
            diag.message = ('%s\n- %s(%d:%d): %s'):format(
                diag.message,
                vim.fn.fnamemodify(vim.uri_to_fname(info.location.uri), ':p:.'),
                info.location.range.start.line + 1,
                info.location.range.start.character + 1,
                info.message
            )
        end

        return diag
    end, result.diagnostics)
    original_handler(err, result, ctx, config)
end

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
                        'shellcheck',
                        'shfmt',
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
                        'bashls',
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
            -- Formatting on save.
            { 'lukas-reineke/lsp-format.nvim', config = true },
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
                        formatCommand = string.format('%s --color Never -', vim.fn.exepath 'stylua'),
                        formatStdin = true,
                        rootMarkers = { 'stylua.toml', '.stylua.toml' },
                    },
                },
                sh = {
                    { formatCommand = 'shfmt -i 2 -ci -bn' },
                },
            }

            lspconfig.efm.setup {
                capabilities = capabilities,
                on_attach = require('lsp-format').on_attach,
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
                        on_attach = on_attach(false),
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
                        on_attach = on_attach(true),
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
                        on_attach = on_attach(false),
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
                                -- Using stylua for formatting.
                                format = { enable = false },
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

                            on_attach(false)(client, bufnr)
                        end,
                    }
                end,
            }
        end,
    },
}
