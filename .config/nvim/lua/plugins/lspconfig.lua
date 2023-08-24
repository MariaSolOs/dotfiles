local capabilities = require('lsp').client_capabilities
local on_attach = require('lsp').on_attach
local diagnostic_icons = require('icons').diagnostics

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

-- Update mappings when registering dynamic capabilities.
local register_method = vim.lsp.protocol.Methods.client_registerCapability
local register_capability = vim.lsp.handlers[register_method]
vim.lsp.handlers[register_method] = function(err, res, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    local bufnr = vim.api.nvim_get_current_buf()
    on_attach(client, bufnr)

    return register_capability(err, res, ctx)
end

return {
    {
        'williamboman/mason-lspconfig.nvim',
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
            'neovim/nvim-lspconfig',
            -- JSON schemas.
            { 'b0o/SchemaStore.nvim', version = false },
            -- Formatting on save.
            { 'lukas-reineke/lsp-format.nvim', config = true },
        },
        config = function()
            local lspconfig = require 'lspconfig'

            -- I like rounded borders ok??
            require('lspconfig.ui.windows').default_options.border = 'rounded'

            -- Set up EFM for general formatters.
            -- Configuring this separately since I don't install EFM with mason.
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
                capabilities = capabilities(),
                on_attach = require('lsp-format').on_attach,
                init_options = { documentFormatting = true },
                filetypes = vim.tbl_keys(languages),
                settings = {
                    rootMarkers = { '.git' },
                    languages = languages,
                },
            }

            require('mason-lspconfig').setup {
                ensure_installed = {
                    'bashls',
                    'eslint',
                    'jsonls',
                    'lua_ls',
                    'marksman',
                    'pyright',
                    'ruff_lsp',
                    'taplo',
                },
                handlers = {
                    function(server)
                        lspconfig[server].setup {
                            capabilities = capabilities(),
                            on_attach = on_attach,
                        }
                    end,
                    eslint = function()
                        lspconfig.eslint.setup {
                            capabilities = capabilities(),
                            on_attach = on_attach,
                            settings = { format = false },
                        }
                    end,
                    jsonls = function()
                        lspconfig.jsonls.setup {
                            capabilities = capabilities(),
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
                            capabilities = capabilities(),
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
                            capabilities = capabilities(),
                            on_attach = function(client, bufnr)
                                -- Disable hover in favor of pyright.
                                client.server_capabilities.hoverProvider = false

                                on_attach(client, bufnr)
                            end,
                        }
                    end,
                    taplo = function()
                        lspconfig.taplo.setup {
                            capabilities = capabilities(),
                            on_attach = on_attach,
                            settings = {
                                evenBetterToml = {
                                    -- TODO: Remove this hack when https://github.com/tamasfe/taplo/issues/463 gets fixed.
                                    schema = {
                                        catalogs = { 'https://taplo.tamasfe.dev/schema_index.json' },
                                    },
                                },
                            },
                        }
                    end,
                },
            }
        end,
    },
}
