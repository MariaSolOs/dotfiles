-- Extra rust goodies.
return {
    {
        'simrat39/rust-tools.nvim',
        dependencies = 'nvim-lspconfig',
        event = { 'BufReadPost *.rs', 'BufNewFile *.rs' },
        config = function()
            local rt = require 'rust-tools'

            -- Adapter shenanigans.
            local extension_path = require('mason-registry').get_package('codelldb'):get_install_path() .. '/extension/'
            local codelldb_path = extension_path .. 'adapter/codelldb'
            local liblldb_path = extension_path .. 'lldb/lib/liblldb.dylib'
            local adapter = require('rust-tools.dap').get_codelldb_adapter(codelldb_path, liblldb_path)

            rt.setup {
                tools = {
                    -- Disable inlay hints since Neovim now supports them.
                    inlay_hints = {
                        auto = false,
                        show_parameter_hints = false,
                    },
                },
                server = {
                    on_attach = function(client, bufnr)
                        require('helpers.lsp').on_attach(client, bufnr)

                        -- Set up extra Rust commands.
                        vim.keymap.set('n', 'K', rt.hover_actions.hover_actions, {
                            buffer = bufnr,
                            desc = 'Hover',
                        })
                        require('which-key').register {
                            ['<leader>R'] = {
                                name = '+rust',
                                m = {
                                    function()
                                        rt.expand_macro.expand_macro()
                                    end,
                                    'Expand macro',
                                    buffer = bufnr,
                                },
                                r = {
                                    function()
                                        rt.runnables.runnables()
                                    end,
                                    'Runnables',
                                    buffer = bufnr,
                                },
                                c = {
                                    function()
                                        rt.open_cargo_toml.open_cargo_toml()
                                    end,
                                    'Open Cargo.toml',
                                    buffer = bufnr,
                                },
                            },
                        }
                    end,
                    settings = {
                        ['rust-analyzer'] = {
                            inlayHints = {
                                -- These are a bit too much.
                                chainingHints = { enable = false },
                            },
                            completion = {
                                callable = {
                                    snippets = 'add_parentheses',
                                },
                            },
                        },
                    },
                },
                dap = {
                    adapter = adapter,
                },
            }
        end,
    },
}
