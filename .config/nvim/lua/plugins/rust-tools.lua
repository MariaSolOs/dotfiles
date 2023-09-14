-- Extra rust goodies.
return {
    {
        'simrat39/rust-tools.nvim',
        event = { 'BufReadPost *.rs', 'BufNewFile *.rs' },
        opts = function()
            local rt = require 'rust-tools'

            -- Adapter shenanigans.
            local extension_path = require('mason-registry').get_package('codelldb'):get_install_path() .. '/extension/'
            local codelldb_path = extension_path .. 'adapter/codelldb'
            local liblldb_path = extension_path .. 'lldb/lib/liblldb.dylib'
            local adapter = require('rust-tools.dap').get_codelldb_adapter(codelldb_path, liblldb_path)

            return {
                tools = {
                    -- Disable inlay hints since Neovim now supports them.
                    inlay_hints = {
                        auto = false,
                        show_parameter_hints = false,
                    },
                    hover_actions = {
                        max_height = 20,
                        max_width = 120,
                    },
                },
                server = {
                    capabilities = require('lsp').client_capabilities(),
                    on_attach = function(client, bufnr)
                        require('lsp').on_attach(client, bufnr)

                        -- Format on save.
                        vim.keymap.set('n', 'K', rt.hover_actions.hover_actions, {
                            buffer = bufnr,
                            desc = 'Hover',
                        })
                        local function keymap(key, rhs, desc)
                            vim.keymap.set('n', '<leader>c' .. key, rhs, { desc = desc, buffer = bufnr })
                        end
                        keymap('c', rt.open_cargo_toml.open_cargo_toml, 'Open Cargo.toml')
                        keymap('m', rt.expand_macro.expand_macro, 'Expand macro')
                        keymap('R', rt.runnables.runnables, 'Runnables')
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
                dap = { adapter = adapter },
            }
        end,
    },
}
