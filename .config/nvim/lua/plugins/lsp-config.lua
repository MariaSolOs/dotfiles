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

    nmap('<leader>rn', '<cmd>Lspsaga rename<cr>', '[R]e[n]ame')
    nmap('ca', '<cmd>Lspsaga code_action<cr>', '[C]ode [A]ction')
    nmap('<leader>o', '<cmd>Lspsaga outline<cr>', 'Toggle [O]utline')
    nmap('gd', '<cmd>Lspsaga goto_definition<cr>', '[G]oto [D]efinition')
    nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
    nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
    nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
    nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
    nmap('K', '<cmd>Lspsaga hover_doc<cr>', 'Hover Documentation')
    nmap('<leader>sd', vim.lsp.buf.signature_help, '[S]ignature [D]ocumentation')
    nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    nmap('[d', '<cmd>Lspsaga diagnostic_jump_prev<cr>', 'Previous diagnostic')
    nmap(']d', '<cmd>Lspsaga diagnostic_jump_next<cr>', 'Next diagnostic')
    nmap('<leader>Wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>Wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>Wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')

    -- Toggle the floating terminal.
    vim.keymap.set({ 'n', 't' }, '<M-t>', '<cmd>Lspsaga term_toggle<cr>', { desc = 'Toggle floating terminal' })

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
                                parameter_hints_prefix = '',
                                show_parameter_hints = false
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

    -- Extra goodies for rust.
    { 'simrat39/rust-tools.nvim' },

    -- Nicer UI.
    {
        'glepnir/lspsaga.nvim',
        events = 'LspAttach',
        dependencies = {
            { 'nvim-tree/nvim-web-devicons' },
            { 'nvim-treesitter/nvim-treesitter' }
        },
        opts = {
            ui = {
                border = 'rounded',
                code_action = ''
            }
        }
    }
}
