local methods = vim.lsp.protocol.Methods

---@param bufnr number
local function setup_inlay_hints(bufnr)
    local inlay_hints_group = vim.api.nvim_create_augroup('ToggleInlayHints', { clear = false })

    -- Initial inlay hint display.
    -- Idk why but without the delay inlay hints aren't displayed at the very start.
    vim.defer_fn(function()
        local mode = vim.api.nvim_get_mode().mode
        vim.lsp.inlay_hint(bufnr, mode == 'n' or mode == 'v')
    end, 500)

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

---Sets up LSP keymaps and autocommands for the given buffer.
---@param format_on_save boolean
local function on_attach(format_on_save)
    return function(buf_client, bufnr)
        local function keymap(lhs, rhs, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- Set up formatter if applicable.
        if format_on_save then
            require('lsp-format').on_attach(buf_client)
        end

        if buf_client.supports_method(methods.textDocument_codeAction) then
            keymap('<leader>ca', vim.lsp.buf.code_action, 'Code action', { 'n', 'v' })
        end

        if buf_client.supports_method(methods.textDocument_rename) then
            vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, { desc = 'Rename' })
        end

        if buf_client.supports_method(methods.textDocument_definition) then
            keymap('gd', function()
                require('fzf-lua').lsp_definitions { jump_to_single_result = true }
            end, 'Go to definition')
        end

        if buf_client.supports_method(methods.textDocument_signatureHelp) then
            keymap('<C-k>', vim.lsp.buf.signature_help, 'Signature help', 'i')
        end

        keymap('gr', '<cmd>FzfLua lsp_references<cr>', 'Go to references')
        keymap('gI', '<cmd>FzfLua lsp_implementations<cr>', 'Go to implementation')
        keymap('gD', '<cmd>FzfLua lsp_typedefs<cr>', 'Go to type definition')

        keymap('<leader>fd', '<cmd>FzfLua lsp_document_symbols<cr>', 'Document symbols')
        keymap('<leader>fw', function()
            -- Disable the grep switch header.
            require('fzf-lua').lsp_live_workspace_symbols { no_header_i = true }
        end, 'Workspace symbols')

        keymap('<leader>cd', vim.diagnostic.open_float, 'Line diagnostics')
        keymap('[d', vim.diagnostic.goto_prev, 'Previous diagnostic')
        keymap(']d', vim.diagnostic.goto_next, 'Next diagnostic')
        keymap('[e', function()
            vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.ERROR }
        end, 'Previous error')
        keymap(']e', function()
            vim.diagnostic.goto_next { severity = vim.diagnostic.severity.ERROR }
        end, 'Next error')

        -- noice deals with the UI.
        keymap('K', vim.lsp.buf.hover, 'Hover')

        -- Enable inlay hints if the client supports it.
        if buf_client.supports_method(methods.textDocument_inlayHint) then
            setup_inlay_hints(bufnr)
        end
    end
end

return on_attach
