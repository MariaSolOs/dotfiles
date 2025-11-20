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
            {
                'igorlfs/nvim-dap-view',
                opts = {
                    winbar = {
                        sections = { 'scopes', 'breakpoints', 'threads', 'exceptions', 'repl', 'console' },
                        default_section = 'scopes',
                    },
                    windows = { height = 18 },
                    -- When jumping through the call stack, try to switch to the buffer if already open in
                    -- a window, else use the last window to open the buffer.
                    switchbuf = 'usetab,uselast',
                },
            },
            -- Virtual text.
            {
                'theHamsta/nvim-dap-virtual-text',
                opts = { virt_text_pos = 'eol' },
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
            local dv = require 'dap-view'

            -- Automatically open the UI when a new debug session is created.
            dap.listeners.before.attach['dap-view-config'] = function()
                dv.open()
            end
            dap.listeners.before.launch['dap-view-config'] = function()
                dv.open()
            end
            dap.listeners.before.event_terminated['dap-view-config'] = function()
                dv.close()
            end
            dap.listeners.before.event_exited['dap-view-config'] = function()
                dv.close()
            end

            -- Use overseer for running preLaunchTask and postDebugTask.
            require('overseer').enable_dap()
            require('dap.ext.vscode').json_decode = require('overseer.json').decode

            -- Lua configurations.
            dap.adapters.nlua = function(callback, config)
                callback { type = 'server', host = config.host or '127.0.0.1', port = config.port or 8086 }
            end
            dap.configurations['lua'] = {
                {
                    type = 'nlua',
                    request = 'attach',
                    name = 'Attach to running Neovim instance',
                },
            }

            -- C configurations.
            dap.adapters.codelldb = {
                type = 'server',
                host = 'localhost',
                port = '${port}',
                executable = {
                    command = 'codelldb',
                    args = { '--port', '${port}' },
                },
            }
        end,
    },
}
