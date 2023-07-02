-- Extra rust goodies.
return {
    {
        'simrat39/rust-tools.nvim',
        dependencies = 'nvim-lspconfig',
        event = { 'BufReadPost *.rs', 'BufNewFile *.rs' },
        config = function()
            local rt = require 'rust-tools'

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
                        vim.keymap.set('n', '<leader>Rm', rt.expand_macro.expand_macro, {
                            buffer = bufnr,
                            desc = 'Expand macro',
                        })
                        vim.keymap.set('n', '<leader>Rr', rt.runnables.runnables, {
                            buffer = bufnr,
                            desc = 'Runnables',
                        })
                        vim.keymap.set('n', '<leader>Rc', rt.open_cargo_toml.open_cargo_toml, {
                            buffer = bufnr,
                            desc = 'Open Cargo.toml',
                        })
                        require('which-key').register {
                            ['<leader>R'] = { name = '+rust' },
                        }
                    end,
                    settings = {
                        ['rust-analyzer'] = {
                            inlayHints = {
                                -- These are a bit too much.
                                chainingHints = { enable = false },
                            },
                        },
                    },
                },
            }
        end,
    },
}
