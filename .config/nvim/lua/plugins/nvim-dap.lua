-- Debugging.
return {
    {
        'mfussenegger/nvim-dap',
        dependencies = {
            -- Fancy UI for the debugger
            {
                'rcarriga/nvim-dap-ui',
                keys = {
                    {
                        '<leader>du',
                        function()
                            require('dapui').toggle {}
                        end,
                        desc = 'Toggle DAP UI',
                    },
                    {
                        '<leader>de',
                        function()
                            require('dapui').eval()
                        end,
                        desc = 'Evaluate expression',
                    },
                },
                config = function()
                    local dap = require 'dap'
                    local dapui = require 'dapui'

                    dapui.setup {
                        layouts = {
                            {
                                elements = {
                                    {
                                        id = 'scopes',
                                        size = 0.33,
                                    },
                                    {
                                        id = 'breakpoints',
                                        size = 0.33,
                                    },
                                    {
                                        id = 'stacks',
                                        size = 0.33,
                                    },
                                },
                                position = 'left',
                                size = 40,
                            },
                        },
                    }

                    -- Open automatically when a new debug session is created.
                    dap.listeners.after.event_initialized['dapui_config'] = function()
                        dapui.open {}
                    end
                    dap.listeners.before.event_terminated['dapui_config'] = function()
                        dapui.close {}
                    end
                    dap.listeners.before.event_exited['dapui_config'] = function()
                        dapui.close {}
                    end
                end,
            },

            -- mason.nvim integration
            {
                'jay-babu/mason-nvim-dap.nvim',
                dependencies = 'mason.nvim',
                cmd = { 'DapInstall', 'DapUninstall' },
                opts = {
                    automatic_installation = true,
                    handlers = {},
                    ensure_installed = {},
                },
            },

            -- Lua adapter.
            {
                'jbyuki/one-small-step-for-vimkind',
                keys = {
                    {
                        '<leader>dal',
                        function()
                            require('osv').launch { port = 8086 }
                        end,
                        desc = 'Lua',
                    },
                },
                config = function()
                    local dap = require 'dap'

                    dap.adapters.nlua = function(callback, config)
                        ---@diagnostic disable-next-line: undefined-field
                        callback { type = 'server', host = config.host or '127.0.0.1', port = config.port or 8086 }
                    end
                    dap.configurations.lua = {
                        {
                            type = 'nlua',
                            request = 'attach',
                            name = 'Attach to running Neovim instance',
                        },
                    }
                end,
            },
        },

        keys = {
            {
                '<leader>dB',
                function()
                    require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
                end,
                desc = 'Breakpoint Condition',
            },
            {
                '<leader>db',
                function()
                    require('dap').toggle_breakpoint()
                end,
                desc = 'Toggle Breakpoint',
            },
            {
                '<leader>dj',
                function()
                    require('dap').down()
                end,
                desc = 'Down in current stacktrace',
            },
            {
                '<leader>dk',
                function()
                    require('dap').up()
                end,
                desc = 'Up in current stacktrace',
            },
            {
                '<F5>',
                function()
                    require('dap').continue()
                end,
                desc = 'Continue',
            },
            {
                '<F10>',
                function()
                    require('dap').step_over()
                end,
                desc = 'Step Over',
            },
            {
                '<F11>',
                function()
                    require('dap').step_into()
                end,
                desc = 'Step Into',
            },
            {
                '<F12>',
                function()
                    require('dap').step_out()
                end,
                desc = 'Step Out',
            },
            {
                '<leader>dt',
                function()
                    require('dap').terminate()
                end,
                desc = 'Terminate',
            },
        },

        config = function()
            vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, link = 'Visual' })

            -- Set up icons.
            local icons = {
                Stopped = { ' ', 'DiagnosticWarn', 'DapStoppedLine' },
                Breakpoint = ' ',
                BreakpointCondition = ' ',
                BreakpointRejected = { ' ', 'DiagnosticError' },
                LogPoint = '.>',
            }
            for name, sign in pairs(icons) do
                sign = type(sign) == 'table' and sign or { sign }
                vim.fn.sign_define(
                    'Dap' .. name,
                    { text = sign[1], texthl = sign[2] or 'DiagnosticInfo', linehl = sign[3], numhl = sign[3] }
                )
            end
        end,
    },
}
