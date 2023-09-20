return {
    {
        'neovim/nvim-lspconfig',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = {
            'williamboman/mason-lspconfig.nvim',
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
        },
        config = function()
            local lspconfig = require 'lspconfig'
            local capabilities = require('lsp').client_capabilities

            -- I like rounded borders ok??
            require('lspconfig.ui.windows').default_options.border = 'rounded'

            require('mason-lspconfig').setup {
                ensure_installed = {
                    'bashls',
                    'clangd',
                    'eslint',
                    'jsonls',
                    'lua_ls',
                    'marksman',
                    'taplo',
                },
                handlers = {
                    function(server)
                        lspconfig[server].setup { capabilities = capabilities() }
                    end,
                    clangd = function()
                        lspconfig.clangd.setup {
                            capabilities = vim.tbl_deep_extend('error', capabilities(), {
                                -- Prevents the  multiple different client offset_encodings detected for buffer' warning.
                                offsetEncoding = { 'utf-16' },
                            }),
                        }
                    end,
                    eslint = function()
                        lspconfig.eslint.setup {
                            capabilities = capabilities(),
                            settings = { format = false },
                        }
                    end,
                    jsonls = function()
                        lspconfig.jsonls.setup {
                            capabilities = capabilities(),
                            settings = {
                                json = {
                                    validate = { enable = true },
                                    format = { enable = true },
                                },
                            },
                            -- Lazy-load schemas.
                            on_new_config = function(config)
                                config.settings.json.schemas = config.settings.json.schemas or {}
                                vim.list_extend(config.settings.json.schemas, require('schemastore').json.schemas())
                            end,
                        }
                    end,
                    lua_ls = function()
                        lspconfig.lua_ls.setup {
                            capabilities = capabilities(),
                            on_init = function(client)
                                local path = client.workspace_folders[1].name
                                if
                                    not vim.uv.fs_stat(path .. '/.luarc.json')
                                    and not vim.uv.fs_stat(path .. '/.luarc.jsonc')
                                then
                                    client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
                                        Lua = {
                                            runtime = {
                                                version = 'LuaJIT',
                                            },
                                            workspace = {
                                                checkThirdParty = false,
                                                library = {
                                                    vim.env.VIMRUNTIME,
                                                    '${3rd}/luv/library',
                                                },
                                            },
                                        },
                                    })
                                    client.notify(
                                        vim.lsp.protocol.Methods.workspace_didChangeConfiguration,
                                        { settings = client.config.settings }
                                    )
                                end

                                return true
                            end,
                            settings = {
                                Lua = {
                                    -- Using stylua for formatting.
                                    format = { enable = false },
                                    hint = {
                                        enable = true,
                                        arrayIndex = 'Disable',
                                    },
                                    completion = { callSnippet = 'Replace' },
                                },
                            },
                        }
                    end,
                },
            }
        end,
    },
}
