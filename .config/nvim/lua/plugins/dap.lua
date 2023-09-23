local arrows = require('icons').arrows

-- Set up icons.
local icons = {
    Stopped = { '', 'DiagnosticWarn', 'DapStoppedLine' },
    Breakpoint = '',
    BreakpointCondition = '',
    BreakpointRejected = { '', 'DiagnosticError' },
    LogPoint = arrows.right,
}
for name, sign in pairs(icons) do
    sign = type(sign) == 'table' and sign or { sign }
    vim.fn.sign_define('Dap' .. name, {
        -- stylua: ignore
        text = sign[1] --[[@as string]] .. ' ',
        texthl = sign[2] or 'DiagnosticInfo',
        linehl = sign[3],
        numhl = sign[3],
    })
end

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
                    icons = {
                        collapsed = arrows.right,
                        current_frame = arrows.right,
                        expanded = arrows.down,
                    },
                    floating = { border = 'rounded' },
                    layouts = {
                        {
                            elements = {
                                { id = 'stacks', size = 0.30 },
                                { id = 'breakpoints', size = 0.20 },
                                { id = 'scopes', size = 0.50 },
                            },
                            position = 'left',
                            size = 40,
                        },
                    },
                },
            },
            -- Virtual text.
            {
                'theHamsta/nvim-dap-virtual-text',
                opts = { virt_text_pos = 'eol' },
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
                build = 'npm i && npm run compile vsDebugServerBundle && mv -f dist out',
            },
            -- Lua adapter.
            {
                'jbyuki/one-small-step-for-vimkind',
                keys = {
                    {
                        '<leader>dl',
                        function()
                            require('osv').launch { port = 8086 }
                        end,
                        desc = 'Launch Lua adapter',
                    },
                },
            },
        },
        keys = {
            {
                '<leader>db',
                function()
                    require('dap').toggle_breakpoint()
                end,
                desc = 'Toggle breakpoint',
            },
            {
                '<leader>dB',
                '<cmd>FzfLua dap_breakpoints<cr>',
                desc = 'List breakpoints',
            },
            {
                '<leader>dc',
                function()
                    require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
                end,
                desc = 'Breakpoint condition',
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
                desc = 'Step over',
            },
            {
                '<F11>',
                function()
                    require('dap').step_into()
                end,
                desc = 'Step into',
            },
            {
                '<F12>',
                function()
                    require('dap').step_out()
                end,
                desc = 'Step Out',
            },
        },
        config = function()
            local dap = require 'dap'
            local dapui = require 'dapui'
            local pick_process = require('dap.utils').pick_process

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

            -- Set up adapter configurations.
            dap.adapters.nlua = function(callback, config)
                callback { type = 'server', host = config.host or '127.0.0.1', port = config.port or 8086 }
            end
            -- TODO: Is it fine to ignore this warning?
            ---@diagnostic disable-next-line: inject-field
            dap.configurations.lua = {
                {
                    type = 'nlua',
                    request = 'attach',
                    name = 'Attach to running Neovim instance',
                },
            }

            for _, language in ipairs { 'typescript', 'javascript' } do
                dap.configurations[language] = {
                    {
                        type = 'pwa-node',
                        request = 'attach',
                        processId = pick_process,
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
