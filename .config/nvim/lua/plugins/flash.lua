local disabled_filetypes = { 'qf' }

-- Navigation with jump motions.
return {
    {
        'folke/flash.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            jump = { nohlsearch = true },
        },
        keys = {
            {
                's',
                mode = { 'n', 'x', 'o' },
                function()
                    if not vim.iter(disabled_filetypes):find(vim.bo.filetype) then
                        vim.schedule(function()
                            require('flash').jump()
                        end)
                    end
                    return '<Ignore>'
                end,
                desc = 'Flash',
            },
            {
                'r',
                mode = 'o',
                function()
                    if not vim.iter(disabled_filetypes):find(vim.bo.filetype) then
                        vim.schedule(function()
                            require('flash').treesitter_search()
                        end)
                    end
                    return '<Ignore>'
                end,
                desc = 'Treesitter Search',
            },
        },
    },
}
