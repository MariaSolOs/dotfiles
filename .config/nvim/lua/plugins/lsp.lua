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
                hint = { enable = true },
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

local nmap = function(lhs, rhs, desc, bufnr)
    require('helpers.keybindings').nmap(lhs, rhs, { buffer = bufnr, desc = desc })
end

local on_attach = function(buf_client, bufnr)
    nmap('<leader>c', ':Lspsaga code_action<cr>', 'Code action', bufnr)
    nmap('<leader>o', ':Lspsaga outline<cr>', 'Toggle outline', bufnr)
    nmap('<leader>r', ':Lspsaga rename<cr>', 'Rename', bufnr)

    nmap('<leader>sd', function()
        require('telescope.builtin').lsp_document_symbols()
    end, 'Search document symbols', bufnr)
    nmap('<leader>sw', function()
        require('telescope.builtin').lsp_dynamic_workspace_symbols()
    end, 'Search workspace symbols', bufnr)

    nmap('gd', ':Lspsaga goto_definition<cr>', 'Go to definition', bufnr)
    nmap('gr', ':Telescope lsp_references<cr>', 'Go to references', bufnr)
    if buf_client.server_capabilities.implementationProvider then
        nmap('gI', ':Telescope lsp_implementations<cr>', 'Go to implementation(s)', bufnr)
    end
    if buf_client.server_capabilities.typeDefinitionProvider then
        nmap('gt', ':Telescope lsp_type_definitions<cr>', 'Go to type definition(s)', bufnr)
    end

    -- noice deals with the UI.
    nmap('K', vim.lsp.buf.hover, 'Hover', bufnr)

    nmap('[d', ':Lspsaga diagnostic_jump_prev<cr>', 'Previous diagnostic', bufnr)
    nmap(']d', ':Lspsaga diagnostic_jump_next<cr>', 'Next diagnostic', bufnr)

    -- Enable inlay hints if the client supports it.
    if buf_client.server_capabilities.inlayHintProvider then
        vim.lsp.buf.inlay_hint(bufnr, true)
    end

    -- Toggle the floating terminal.
    -- NOTE: The <cmd> below is needed to exit terminal mode.
    vim.keymap.set({ 'n', 't' }, '<M-t>', '<cmd>Lspsaga term_toggle<cr>', { desc = 'Toggle floating terminal' })

    -- Create a command `:Fmt` local to the LSP buffer
    vim.api.nvim_buf_create_user_command(bufnr, 'Fmt', function()
        vim.lsp.buf.format()
    end, { desc = 'Format current buffer' })

    -- Set up format on save.
    vim.api.nvim_create_autocmd('BufWritePre', {
        group = require('helpers.commands').augroup 'FormatOnSave',
        pattern = { '*.lua', '*.rs' },
        callback = function()
            local buf = vim.api.nvim_get_current_buf()
            local ft = vim.bo[buf].filetype

            -- When a null-ls formatter is available for the current filetype, only null-ls formatters are returned.
            local null_ls = package.loaded['null-ls']
                    and require('null-ls.sources').get_available(ft, 'NULL_LS_FORMATTING')
                or {}
            local clients = vim.lsp.get_active_clients { bufnr = buf }
            local available = {}
            for _, client in ipairs(clients) do
                if
                    client.supports_method 'textDocument/formatting'
                    or client.supports_method 'textDocument/rangeFormatting'
                then
                    if (#null_ls > 0 and client.name == 'null-ls') or #null_ls == 0 then
                        table.insert(available, client.id)
                    end
                end
            end

            if #available == 0 then
                return
            end

            vim.lsp.buf.format {
                bufnr = buf,
                filter = function(client)
                    return vim.tbl_contains(available, client.id)
                end,
            }
        end,
    })
end

return {
    -- LSP server tools.
    {
        'williamboman/mason.nvim',
        cmd = 'Mason',
        config = true,
    },

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

    -- Nicer UI.
    {
        'glepnir/lspsaga.nvim',
        cmd = 'Lspsaga',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
            'nvim-treesitter/nvim-treesitter',
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

    -- "Native" TSServer client.
    {
        'pmizio/typescript-tools.nvim',
        event = { 'BufReadPre *.ts,*.tsx,*.js,*.jsx', 'BufNewFile *.ts,*.tsx,*.js,*.jsx' },
        dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
        opts = {
            on_attach = on_attach,
            settings = {
                tsserver_file_preferences = {
                    includeInlayParameterNameHints = 'all',
                    includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                    includeInlayFunctionParameterTypeHints = true,
                    includeInlayVariableTypeHints = true,
                    includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                    includeInlayFunctionLikeReturnTypeHints = true,
                },
            },
        },
    },

    -- Use Neovim as a language server.
    {
        'jose-elias-alvarez/null-ls.nvim',
        dependencies = 'nvim-lua/plenary.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        config = function()
            local null_ls = require 'null-ls'

            null_ls.setup {
                sources = {
                    -- Formatters.
                    null_ls.builtins.formatting.clang_format,
                    null_ls.builtins.formatting.stylua,
                },
            }
        end,
    },
}
