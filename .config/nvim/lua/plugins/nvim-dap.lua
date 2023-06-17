return {
    {
        'mfussenegger/nvim-dap',
        dependencies = {
            --     -- Fancy UI for the debugger.
            --     {
            --         'rcarriga/nvim-dap-ui',
            --         keys = {
            --             { '<leader>du', function() require('dapui').toggle({}) end, desc = 'Dap UI' },
            --             { '<leader>de', function() require('dapui').eval() end,     desc = 'Eval',  mode = { 'n', 'v' } },
            --         },
            --         opts = {},
            --         config = function(_, opts)
            --             local dap = require('dap')
            --             local dapui = require('dapui')
            --             dapui.setup(opts)
            --             dap.listeners.after.event_initialized['dapui_config'] = function()
            --                 dapui.open({})
            --             end
            --             dap.listeners.before.event_terminated['dapui_config'] = function()
            --                 dapui.close({})
            --             end
            --             dap.listeners.before.event_exited['dapui_config'] = function()
            --                 dapui.close({})
            --             end
            --         end,
            --     },
            --
            --     -- virtual text for the debugger
            --     {
            --         'theHamsta/nvim-dap-virtual-text',
            --         opts = {},
            --     },

            -- mason.nvim integration
            {
                'jay-babu/mason-nvim-dap.nvim',
                dependencies = 'mason.nvim',
                cmd = { 'DapInstall', 'DapUninstall' },
                opts = {
                    automatic_installation = true,
                },
            },

            -- Debug adapter for Lua.
            {
                'jbyuki/one-small-step-for-vimkind',
                keys = {
                    {
                        '<leader>daL',
                        function()
                            require('osv').launch { port = 8086 }
                        end,
                        desc = 'Lua Server Adapter',
                    },
                    -- TODO: Do I need this?
                    {
                        '<leader>dal',
                        function()
                            require('osv').run_this()
                        end,
                        desc = 'Lua Adapter',
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
            --     {
            --         '<leader>dc',
            --         function() require('dap').continue() end,
            --         desc =
            --         'Continue'
            --     },
            --     {
            --         '<leader>dC',
            --         function() require('dap').run_to_cursor() end,
            --         desc =
            --         'Run to Cursor'
            --     },
            --     {
            --         '<leader>dg',
            --         function() require('dap').goto_() end,
            --         desc =
            --         'Go to line (no execute)'
            --     },
            --     {
            --         '<leader>di',
            --         function() require('dap').step_into() end,
            --         desc =
            --         'Step Into'
            --     },
            --     {
            --         '<leader>dj',
            --         function() require('dap').down() end,
            --         desc =
            --         'Down'
            --     },
            --     {
            --         '<leader>dk',
            --         function() require('dap').up() end,
            --         desc =
            --         'Up'
            --     },
            --     {
            --         '<leader>dl',
            --         function() require('dap').run_last() end,
            --         desc =
            --         'Run Last'
            --     },
            --     {
            --         '<leader>do',
            --         function() require('dap').step_out() end,
            --         desc =
            --         'Step Out'
            --     },
            --     {
            --         '<leader>dO',
            --         function() require('dap').step_over() end,
            --         desc =
            --         'Step Over'
            --     },
            --     {
            --         '<leader>dp',
            --         function() require('dap').pause() end,
            --         desc =
            --         'Pause'
            --     },
            --     {
            --         '<leader>dr',
            --         function() require('dap').repl.toggle() end,
            --         desc =
            --         'Toggle REPL'
            --     },
            --     {
            --         '<leader>ds',
            --         function() require('dap').session() end,
            --         desc =
            --         'Session'
            --     },
            --     {
            --         '<leader>dt',
            --         function() require('dap').terminate() end,
            --         desc =
            --         'Terminate'
            --     },
            --     {
            --         '<leader>dw',
            --         function() require('dap.ui.widgets').hover() end,
            --         desc =
            --         'Widgets'
            --     },
        },
        -- config = function()
        --     local Config = require('lazyvim.config')
        --     vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, link = 'Visual' })
        --
        --     for name, sign in pairs(Config.icons.dap) do
        --         sign = type(sign) == 'table' and sign or { sign }
        --         vim.fn.sign_define(
        --             'Dap' .. name,
        --             { text = sign[1], texthl = sign[2] or 'DiagnosticInfo', linehl = sign[3], numhl = sign[3] }
        --         )
        --     end
        -- end,
    },
}
