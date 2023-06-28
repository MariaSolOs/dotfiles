-- Folding ranges.
return {
    {
        'kevinhwang91/nvim-ufo',
        event = 'BufReadPost',
        dependencies = {
            'kevinhwang91/promise-async',
            -- Get rid of the numbers in the folding column.
            {
                'luukvbaal/statuscol.nvim',
                config = function()
                    local builtin = require 'statuscol.builtin'
                    require('statuscol').setup {
                        segments = {
                            { text = { builtin.foldfunc }, click = 'v:lua.ScFa' },
                            { text = { '%s' }, click = 'v:lua.ScSa' },
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
        keys = {
            {
                'zR',
                function()
                    require('ufo').openAllFolds()
                    vim.cmd 'IndentBlanklineRefresh'
                end,
            },
            {
                'zM',
                function()
                    require('ufo').closeAllFolds()
                    vim.cmd 'IndentBlanklineRefresh'
                end,
            },
        },
        init = function()
            vim.o.foldcolumn = '1'
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true
            vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

            -- HACK: Refresh indent lines after folding/unfolding.
            local nmap = function(lhs, rhs)
                require('helpers.keybindings').nmap(lhs, rhs, { noremap = true, silent = true })
            end
            for _, keymap in pairs {
                'zo',
                'zO',
                'zc',
                'zC',
                'za',
                'zA',
                'zv',
                'zx',
                'zX',
                'zm',
                'zr',
            } do
                nmap(keymap, keymap .. ':IndentBlanklineRefresh<cr>')
            end
        end,
    },
}
