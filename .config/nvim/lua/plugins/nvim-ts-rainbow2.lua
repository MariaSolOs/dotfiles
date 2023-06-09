-- Rainbow brackets.
return {
    {
        'HiPhish/nvim-ts-rainbow2',
        dependencies = 'nvim-treesitter/nvim-treesitter',
        config = function(_, _)
            -- Set up the colors to use.
            vim.cmd('highlight TSRainbowRed guifg=#F266AB ctermfg=Red')
            vim.cmd('highlight TSRainbowOrange guifg=#FFB84C ctermfg=White')
            vim.cmd('highlight TSRainbowYellow guifg=#FFF56D ctermfg=Yellow')
            vim.cmd('highlight TSRainbowGreen guifg=#87E58E ctermfg=Green')
            vim.cmd('highlight TSRainbowCyan guifg=#A7DFEF ctermfg=Cyan')
            vim.cmd('highlight TSRainbowBlue guifg=#0079FF ctermfg=Blue')
            vim.cmd('highlight TSRainbowViolet guifg=#A459D1 ctermfg=Magenta')

            require('nvim-treesitter.configs').setup {
                rainbow = { enable = true }
            }
        end
    }
}
