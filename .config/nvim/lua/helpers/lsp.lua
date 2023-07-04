local M = {}

M.on_attach = function(buf_client, bufnr)
    local keymap = function(lhs, rhs, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
    end

    if buf_client.server_capabilities.codeActionProvider then
        keymap('<leader>c', ':Lspsaga code_action<cr>', 'Code action', { 'n', 'v' })
    end

    if buf_client.server_capabilities.renameProvider then
        keymap('<leader>r', ':Lspsaga rename<cr>', 'Rename')
    end

    if buf_client.server_capabilities.implementationProvider then
        keymap('gI', ':Telescope lsp_implementations<cr>', 'Go to implementation(s)')
    end

    if buf_client.server_capabilities.typeDefinitionProvider then
        keymap('gt', ':Telescope lsp_type_definitions<cr>', 'Go to type definition(s)')
    end

    if buf_client.server_capabilities.definitionProvider then
        keymap('gd', ':Lspsaga goto_definition<cr>', 'Go to definition')
    end

    if buf_client.server_capabilities.signatureHelpProvider then
        keymap('<C-k>', vim.lsp.buf.signature_help, 'Signature help', 'i')
    end

    if buf_client.server_capabilities.workspaceSymbolProvider then
        keymap('<leader>tw', function()
            require('telescope.builtin').lsp_dynamic_workspace_symbols()
        end, 'Workspace symbols')
    end

    if buf_client.server_capabilities.referencesProvider then
        keymap('gr', ':Telescope lsp_references<cr>', 'Go to references')
    end

    if buf_client.server_capabilities.documentSymbolProvider then
        require('nvim-navic').attach(buf_client, bufnr)
    end

    keymap('<leader>td', function()
        require('telescope.builtin').lsp_document_symbols()
    end, 'Document symbols')
    keymap('<leader>o', ':Lspsaga outline<cr>', 'Toggle outline')
    keymap('[d', ':Lspsaga diagnostic_jump_prev<cr>', 'Previous diagnostic')
    keymap(']d', ':Lspsaga diagnostic_jump_next<cr>', 'Next diagnostic')
    keymap('[e', function()
        require('lspsaga.diagnostic'):goto_prev { severity = vim.diagnostic.severity.ERROR }
    end, 'Previous error')
    keymap(']e', function()
        require('lspsaga.diagnostic'):goto_next { severity = vim.diagnostic.severity.ERROR }
    end, 'Next error')

    -- noice deals with the UI.
    keymap('K', vim.lsp.buf.hover, 'Hover')

    -- Toggle the floating terminal.
    -- NOTE: The <cmd> below is needed to exit terminal mode.
    vim.keymap.set({ 'n', 't' }, '<M-t>', '<cmd>Lspsaga term_toggle<cr>', { desc = 'Toggle floating terminal' })

    -- Enable inlay hints if the client supports it.
    if buf_client.server_capabilities.inlayHintProvider then
        local inlay_hints_group = vim.api.nvim_create_augroup('InlayHints', {})

        -- Initial inlay hint display.
        local mode = vim.api.nvim_get_mode().mode
        vim.lsp.inlay_hint(bufnr, mode == 'n' or mode == 'v')

        vim.api.nvim_create_autocmd('InsertEnter', {
            group = inlay_hints_group,
            buffer = bufnr,
            callback = function()
                vim.lsp.inlay_hint(bufnr, false)
            end,
        })
        vim.api.nvim_create_autocmd('InsertLeave', {
            group = inlay_hints_group,
            buffer = bufnr,
            callback = function()
                vim.lsp.inlay_hint(bufnr, true)
            end,
        })
    end

    -- Set up format command.
    vim.api.nvim_buf_create_user_command(bufnr, 'Fmt', function()
        vim.lsp.buf.format()
    end, { desc = 'Format current buffer' })

    -- Set up format on save.
    vim.api.nvim_create_autocmd('BufWritePre', {
        group = vim.api.nvim_create_augroup('FormatOnSave', {}),
        pattern = { '*.lua', '*.rs' },
        callback = function()
            local buf = vim.api.nvim_get_current_buf()
            local ft = vim.bo[buf].filetype

            -- When a null-ls formatter is available for the current filetype, only null-ls formatters are returned.
            local null_ls = package.loaded['null-ls']
                    and require('null-ls.sources').get_available(ft, 'NULL_LS_FORMATTING')
                or {}
            local clients = vim.lsp.get_active_clients { bufnr = buf }
            local available = {}
            for _, client in ipairs(clients) do
                if
                    client.supports_method 'textDocument/formatting'
                    or client.supports_method 'textDocument/rangeFormatting'
                then
                    if (#null_ls > 0 and client.name == 'null-ls') or #null_ls == 0 then
                        table.insert(available, client.id)
                    end
                end
            end

            if #available == 0 then
                return
            end

            vim.lsp.buf.format {
                bufnr = buf,
                filter = function(client)
                    return vim.tbl_contains(available, client.id)
                end,
            }
        end,
    })
end

return M
