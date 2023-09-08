local disabled_filetypes = { 'qf' }

-- Navigation with jump motions.
-- TODO: Remove local folding patch when https://github.com/folke/flash.nvim/pull/225 gets merged.
return {
    {
        'folke/flash.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            jump = { nohlsearch = true },
            prompt = {
                -- Place the prompt above the statusline.
                win_config = { row = -3 },
            },
        },
        keys = {
            {
                's',
                mode = { 'n', 'x', 'o' },
                function()
                    if vim.iter(disabled_filetypes):find(vim.bo.filetype) then
                        return 's'
                    else
                        vim.schedule(function()
                            require('flash').jump()
                        end)
                    end
                end,
                desc = 'Flash',
            },
            {
                'r',
                mode = 'o',
                function()
                    if vim.iter(disabled_filetypes):find(vim.bo.filetype) then
                        return 'r'
                    else
                        require('flash').treesitter_search()
                    end
                end,
                desc = 'Treesitter Search',
            },
        },
    },
}
