-- Use Neovim as a language server.
return {
    {
        'jose-elias-alvarez/null-ls.nvim',
        dependencies = 'nvim-lua/plenary.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        config = function()
            local null_ls = require 'null-ls'

            null_ls.setup {
                sources = {
                    -- Formatters.
                    null_ls.builtins.formatting.clang_format,
                    null_ls.builtins.formatting.stylua,
                },
            }
        end,
    },
}
