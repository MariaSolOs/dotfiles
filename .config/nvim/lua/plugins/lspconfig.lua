local capabilities = require('lsp').client_capabilities
local on_attach = require('lsp').on_attach

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
        },
        config = function()
            local lspconfig = require 'lspconfig'

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
                        lspconfig[server].setup {
                            capabilities = capabilities(),
                            on_attach = on_attach,
                        }
                    end,
                    clangd = function()
                        lspconfig.clangd.setup {
                            capabilities = vim.tbl_deep_extend('error', capabilities(), {
                                -- Prevents the  multiple different client offset_encodings detected for buffer' warning.
                                offsetEncoding = { 'utf-16' },
                            }),
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
                                    format = { enable = true },
                                },
                            },
                        }
                    end,
                    lua_ls = function()
                        lspconfig.lua_ls.setup {
                            capabilities = capabilities(),
                            on_attach = on_attach,
                            settings = {
                                Lua = {
                                    runtime = { version = 'LuaJIT' },
                                    workspace = {
                                        checkThirdParty = false,
                                        -- Make the server aware of Neovim runtime files.
                                        library = {
                                            vim.env.VIMRUNTIME,
                                            '${3rd}/luv/library',
                                        },
                                    },
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
