local M = {}

M.on_attach = function(buf_client, bufnr)
    local nmap = function(lhs, rhs, desc)
        require('helpers.keybindings').nmap(lhs, rhs, { buffer = bufnr, desc = desc })
    end

    nmap('<leader>c', ':Lspsaga code_action<cr>', 'Code action')
    nmap('<leader>o', ':Lspsaga outline<cr>', 'Toggle outline')
    nmap('<leader>r', ':Lspsaga rename<cr>', 'Rename')

    nmap('<leader>sd', function()
        require('telescope.builtin').lsp_document_symbols()
    end, 'Search document symbols')
    nmap('<leader>sw', function()
        require('telescope.builtin').lsp_dynamic_workspace_symbols()
    end, 'Search workspace symbols')

    nmap('gd', ':Lspsaga goto_definition<cr>', 'Go to definition')
    nmap('gr', ':Telescope lsp_references<cr>', 'Go to references')
    if buf_client.server_capabilities.implementationProvider then
        nmap('gI', ':Telescope lsp_implementations<cr>', 'Go to implementation(s)')
    end
    if buf_client.server_capabilities.typeDefinitionProvider then
        nmap('gt', ':Telescope lsp_type_definitions<cr>', 'Go to type definition(s)')
    end

    -- noice deals with the UI.
    nmap('K', vim.lsp.buf.hover, 'Hover')

    nmap('[d', ':Lspsaga diagnostic_jump_prev<cr>', 'Previous diagnostic')
    nmap(']d', ':Lspsaga diagnostic_jump_next<cr>', 'Next diagnostic')

    -- Enable inlay hints if the client supports it.
    if buf_client.server_capabilities.inlayHintProvider then
        vim.lsp.buf.inlay_hint(bufnr, true)
    end

    -- Toggle the floating terminal.
    -- NOTE: The <cmd> below is needed to exit terminal mode.
    vim.keymap.set({ 'n', 't' }, '<M-t>', '<cmd>Lspsaga term_toggle<cr>', { desc = 'Toggle floating terminal' })

    -- Set up format command.
    vim.api.nvim_buf_create_user_command(bufnr, 'Fmt', function()
        vim.lsp.buf.format()
    end, { desc = 'Format current buffer' })

    -- Set up format on save.
    vim.api.nvim_create_autocmd('BufWritePre', {
        group = require('helpers.commands').augroup 'FormatOnSave',
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
