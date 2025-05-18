-- Task runner.
return {
    {
        'stevearc/overseer.nvim',
        opts = {
            -- Setup DAP later when lazy-loading the plugin.
            dap = false,
            task_list = {
                default_detail = 2,
                direction = 'bottom',
                max_width = { 600, 0.7 },
                bindings = {
                    ['<C-b>'] = 'ScrollOutputUp',
                    ['<C-f>'] = 'ScrollOutputDown',
                    ['H'] = 'IncreaseAllDetail',
                    ['L'] = 'DecreaseAllDetail',
                    -- Disable mappings I don't use.
                    ['g?'] = false,
                    ['<C-l>'] = false,
                    ['<C-h>'] = false,
                    ['{'] = false,
                    ['}'] = false,
                },
            },
            form = {
                win_opts = { winblend = 0 },
            },
            confirm = {
                win_opts = { winblend = 5 },
            },
            task_win = {
                win_opts = { winblend = 5 },
            },
        },
        keys = {
            {
                '<leader>ot',
                '<cmd>OverseerToggle<cr>',
                desc = 'Toggle task window',
            },
            {
                '<leader>o<',
                function()
                    local overseer = require 'overseer'

                    local tasks = overseer.list_tasks { recent_first = true }
                    if vim.tbl_isempty(tasks) then
                        vim.notify('No tasks found', vim.log.levels.WARN)
                    else
                        overseer.run_action(tasks[1], 'restart')
                        overseer.open { enter = false }
                    end
                end,
                desc = 'Restart last task',
            },
            {
                '<leader>or',
                function()
                    local overseer = require 'overseer'

                    overseer.run_template({}, function(task)
                        if task then
                            overseer.open { enter = false }
                        end
                    end)
                end,
                desc = 'Run task',
            },
        },
    },
}
