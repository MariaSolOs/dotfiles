local methods = vim.lsp.protocol.Methods

local M = {}

-- Configure the diagnostic signs.
local diagnostic_icons = require('icons').diagnostics
for severity, icon in pairs(diagnostic_icons) do
    local hl = 'DiagnosticSign' .. severity:sub(1, 1) .. severity:sub(2):lower()
    vim.fn.sign_define(hl, { text = icon, texthl = hl })
end

-- Update diagnostic locations.
local diagnostic_group = vim.api.nvim_create_augroup('DiagnosticsToQf', { clear = true })
vim.api.nvim_create_autocmd('DiagnosticChanged', {
    group = diagnostic_group,
    callback = function(args)
        vim.diagnostic.setqflist { open = false }
        if #args.data.diagnostics == 0 then
            vim.cmd.cclose { mods = { silent = true, emsg_silent = true } }
        end
    end,
})

---Returns the editor's capabilities + some overrides.
M.client_capabilities = function()
    return vim.tbl_deep_extend(
        'force',
        vim.lsp.protocol.make_client_capabilities(),
        -- nvim-cmp supports additional completion capabilities, so broadcast that to servers.
        require('cmp_nvim_lsp').default_capabilities(),
        {
            workspace = {
                -- PERF: didChangeWatchedFiles is too slow.
                -- TODO: Remove this when https://github.com/neovim/neovim/issues/23291#issuecomment-1686709265 is fixed.
                didChangeWatchedFiles = { dynamicRegistration = false },
            },
        },
        {
            textDocument = {
                -- Enable folding.
                foldingRange = {
                    dynamicRegistration = false,
                    lineFoldingOnly = true,
                },
            },
        }
    )
end

---Sets up LSP keymaps and autocommands for the given buffer.
M.on_attach = function(client, bufnr)
    local function keymap(lhs, rhs, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    if client.supports_method(methods.textDocument_codeAction) then
        keymap('<leader>ca', vim.lsp.buf.code_action, 'Code action', { 'n', 'v' })
    end

    if client.supports_method(methods.textDocument_rename) then
        vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, { desc = 'Rename' })
    end

    if client.supports_method(methods.textDocument_definition) then
        keymap('gD', '<cmd>FzfLua lsp_definitions<cr>', 'Peek definition')
        keymap('gd', function()
            require('fzf-lua').lsp_definitions { jump_to_single_result = true }
        end, 'Go/jump to definition')
    end

    if client.supports_method(methods.textDocument_signatureHelp) then
        keymap('<C-k>', vim.lsp.buf.signature_help, 'Signature help', 'i')
    end

    if client.supports_method(methods.textDocument_implementation) then
        keymap('gm', '<cmd>FzfLua lsp_implementations<cr>', 'Go to implementation')
    end

    keymap('gr', '<cmd>FzfLua lsp_references<cr>', 'Go to references')
    keymap('gt', '<cmd>FzfLua lsp_typedefs<cr>', 'Go to type definition')

    keymap('<leader>fs', '<cmd>FzfLua lsp_document_symbols<cr>', 'Document symbols')
    keymap('<leader>fS', function()
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
    if client.supports_method(methods.textDocument_inlayHint) then
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
end

return M
