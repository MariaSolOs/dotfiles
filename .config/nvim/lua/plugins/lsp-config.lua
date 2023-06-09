-- Enable the following language servers.
local servers = {
    lua_ls = {
        Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
        },
    },
    jdtls = {},
    tsserver = {}
}

local on_attach = function(_, bufnr)
    local nmap = function(keys, func, desc)
        if desc then
            desc = 'LSP: ' .. desc
        end

        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end

    nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
    nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
    nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
    nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
    nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
    nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
    nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
    nmap('<leader>sd', vim.lsp.buf.signature_help, '[S]ignature [D]ocumentation')
    nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')

    -- Create a command `:Fmt` local to the LSP buffer
    vim.api.nvim_buf_create_user_command(bufnr, 'Fmt', function(_)
        vim.lsp.buf.format()
    end, { desc = 'Format current buffer with LSP' })
end

return {
    {
        'neovim/nvim-lspconfig',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = {
            {
                'williamboman/mason.nvim',
                cmd = { 'Mason', 'LspInstall', 'LspUnInstall' },
                config = function(_, _)
                    require('mason').setup()
                    -- Ensure the servers above are installed.
                    require('mason-lspconfig').setup {
                        ensure_installed = vim.tbl_keys(servers),
                    }
                end
            },
            { 'williamboman/mason-lspconfig.nvim', lazy = true },
            { 'folke/neodev.nvim',                 lazy = true }
        },
        config = function(_, _)
            -- Setup neovim lua configuration.
            require('neodev').setup()

            -- nvim-cmp supports additional completion capabilities, so broadcast that to servers.
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

            require('mason-lspconfig').setup_handlers {
                function(server_name)
                    require('lspconfig')[server_name].setup {
                        capabilities = capabilities,
                        on_attach = on_attach,
                        settings = servers[server_name],
                    }
                end,
                -- idk why but I need to configure rust-tools separately.
                rust_analyzer = function()
                    require('rust-tools').setup {
                        tools = {
                            inlay_hints = {
                                other_hints_prefix = '',
                                parameter_hints_prefix = ''
                            }
                        },
                        server = {
                            capabilities = capabilities,
                            on_attach = on_attach
                        }
                    }
                end
            }
        end
    },

    { 'simrat39/rust-tools.nvim' },
}
