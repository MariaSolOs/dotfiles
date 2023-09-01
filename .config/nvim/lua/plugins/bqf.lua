-- Make the quickfix list greattt.

local silent_mods = { mods = { silent = true, emsg_silent = true } }

return {
    {
        'kevinhwang91/nvim-bqf',
        ft = 'qf',
        dependencies = {
            {
                'yorickpeterse/nvim-pqf',
                event = 'VeryLazy',
                opts = {
                    show_multiple_lines = true,
                    max_filename_length = 40,
                },
            },
        },
        keys = {
            -- When toggling these, ignore error messages and restore the cursor
            -- to the original window when opening the list.
            {
                '<leader>xq',
                function()
                    if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
                        vim.cmd.cclose(silent_mods)
                    elseif #vim.fn.getqflist() > 0 then
                        local win = vim.api.nvim_get_current_win()
                        vim.cmd.copen(silent_mods)
                        if win ~= vim.api.nvim_get_current_win() then
                            vim.cmd.wincmd 'p'
                        end
                    end
                end,
                desc = 'Toggle quickfix list',
            },
            {
                '<leader>xl',
                function()
                    if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
                        vim.cmd.lclose(silent_mods)
                    elseif #vim.fn.getloclist(0) > 0 then
                        local win = vim.api.nvim_get_current_win()
                        vim.cmd.lopen(silent_mods)
                        if win ~= vim.api.nvim_get_current_win() then
                            vim.cmd.wincmd 'p'
                        end
                    end
                end,
                desc = 'Toggle location list',
            },
            {
                '<leader>xd',
                vim.diagnostic.setqflist,
                desc = 'Diagnostics',
            },
            {
                '[q',
                '<cmd>cprev<cr>zz',
                desc = 'Previous quickfix item',
            },
            {
                ']q',
                '<cmd>cnext<cr>zz',
                desc = 'Next quickfix item',
            },
            {
                '[l',
                '<cmd>lprev<cr>zz',
                desc = 'Previous location list item',
            },
            {
                ']l',
                '<cmd>lnext<cr>zz',
                desc = 'Next location list item',
            },
        },
        opts = {
            func_map = {
                split = '<C-s>',
            },
        },
    },
}
