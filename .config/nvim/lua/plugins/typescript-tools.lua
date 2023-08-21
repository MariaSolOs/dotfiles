-- "Native" TSServer client.
return {
    {
        'pmizio/typescript-tools.nvim',
        event = { 'BufReadPost *.ts,*.tsx,*.js,*.jsx', 'BufNewFile *.ts,*.tsx,*.js,*.jsx' },
        dependencies = { 'nvim-lua/plenary.nvim', 'nvim-lspconfig' },
        opts = {
            capabilities = require('lsp').client_capabilities(),
            on_attach = require('lsp').on_attach,
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
