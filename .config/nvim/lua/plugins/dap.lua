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
                            -- Calling this twice to open and jump into the window.
                            require('dapui').eval()
                            require('dapui').eval()
                        end,
                        desc = 'Evaluate expression',
                    },
                },
                opts = {
                    layouts = {
                        {
                            elements = {
                                { id = 'scopes', size = 0.33 },
                                { id = 'breakpoints', size = 0.33 },
                                { id = 'stacks', size = 0.33 },
                            },
                            position = 'left',
                            size = 40,
                        },
                    },
                },
                config = function(_, opts)
                    local dap = require 'dap'
                    local dapui = require 'dapui'

                    dapui.setup(opts)

                    -- Automatically open the UI when a new debug session is created.
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
            -- JS/TS debugging.
            {
                'mxsdev/nvim-dap-vscode-js',
                opts = {
                    debugger_path = vim.fn.stdpath 'data' .. '/lazy/vscode-js-debug',
                    adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
                },
            },
            {
                'microsoft/vscode-js-debug',
                version = '1.x',
                build = 'npm i && npm run compile vsDebugServerBundle && mv dist out',
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
                        -- TODO: Understand if it's fine to ignore these errors.
                        ---@diagnostic disable-next-line: undefined-field, missing-fields
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
                '<leader>dr',
                function()
                    require('dap').repl.toggle()
                end,
                desc = 'Toggle REPL',
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
            local dap = require 'dap'

            -- Omnifunc completion for REPL.
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'dap-repl',
                callback = function()
                    require('dap.ext.autocompl').attach()
                end,
            })

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

            -- Set up adapter configurations.
            for _, language in ipairs { 'typescript', 'javascript' } do
                dap.configurations[language] = {
                    {
                        type = 'pwa-node',
                        request = 'attach',
                        processId = require('dap.utils').pick_process,
                        name = 'Attach debugger to existing node process',
                        sourceMaps = true,
                        cwd = '${workspaceFolder}',
                        resolveSourceMapLocations = {
                            '${workspaceFolder}/**',
                            '!**/node_modules/**',
                        },
                        outFiles = {
                            '${workspaceFolder}/**',
                            '!**/node_modules/**',
                        },
                        skipFiles = { '**/node_modules/**' },
                    },
                }
            end
        end,
    },
}
