-- Folding ranges.
return {
    {
        'kevinhwang91/nvim-ufo',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = 'kevinhwang91/promise-async',
        opts = {
            provider_selector = function(_, _, _)
                return { 'treesitter', 'indent' }
            end
        },
        init = function(_)
            vim.o.foldcolumn = '1'
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true

            vim.keymap.set({ 'n' }, 'zR', require('ufo').openAllFolds)
            vim.keymap.set({ 'n' }, 'zM', require('ufo').closeAllFolds)
        end
    }
}
