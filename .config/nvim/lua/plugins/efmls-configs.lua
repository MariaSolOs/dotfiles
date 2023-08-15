-- General purpose language server for linting and formatting.
-- TODO: Make sure :checkhealth doesn't crash once v1 is released.
return {
    {
        'creativenull/efmls-configs-nvim',
        dependencies = 'nvim-lspconfig',
        event = { 'BufReadPre', 'BufNewFile' },
        config = function()
            local efmls = require 'efmls-configs'

            efmls.init {
                init_options = { documentFormatting = true },
            }

            efmls.setup {
                lua = {
                    formatter = require 'efmls-configs.formatters.stylua',
                },
            }
        end,
    },
}
