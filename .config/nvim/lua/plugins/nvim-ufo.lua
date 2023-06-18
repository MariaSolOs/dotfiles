local nmap = require('helpers.keybindings').nmap

-- Folding ranges.
return {
    {
        'kevinhwang91/nvim-ufo',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = {
            'kevinhwang91/promise-async',
            -- Get rid of the numbers in the folding column.
            {
                'luukvbaal/statuscol.nvim',
                config = function()
                    local builtin = require 'statuscol.builtin'
                    require('statuscol').setup {
                        segments = {
                            { text = { builtin.foldfunc },      click = 'v:lua.ScFa' },
                            { text = { '%s' },                  click = 'v:lua.ScSa' },
                            { text = { builtin.lnumfunc, ' ' }, click = 'v:lua.ScLa' },
                        },
                    }
                end,
            },
        },
        opts = {
            provider_selector = function()
                return { 'treesitter', 'indent' }
            end,
        },
        init = function()
            vim.o.foldcolumn = '1'
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true
            vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

            nmap('zR', require('ufo').openAllFolds)
            nmap('zM', require('ufo').closeAllFolds)
        end,
    },
}
