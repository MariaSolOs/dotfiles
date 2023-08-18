-- "Native" TSServer client.
return {
    {
        'pmizio/typescript-tools.nvim',
        event = { 'BufReadPost *.ts,*.tsx,*.js,*.jsx', 'BufNewFile *.ts,*.tsx,*.js,*.jsx' },
        dependencies = { 'nvim-lua/plenary.nvim', 'nvim-lspconfig' },
        opts = {
            on_attach = require 'utils.lsp_on_attach'(false),
            settings = {
                tsserver_file_preferences = {
                    includeInlayParameterNameHints = 'literals',
                    includeInlayVariableTypeHints = true,
                    includeInlayFunctionLikeReturnTypeHints = true,
                },
            },
        },
    },
}
