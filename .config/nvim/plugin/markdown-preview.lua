local add_on_file_type = require('vim-pack').add_on_file_type

-- Markdown preview on the browser.
add_on_file_type('markdown', {
    {
        src = 'sammaji/markdown-preview.nvim',
        on_setup = function()
            vim.keymap.set('n', '<leader>cp', '<cmd>MarkdownPreviewToggle<cr>', {
                desc = 'Markdown Preview',
            })
        end,
    },
})

vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(args)
        if args.data.spec.name == 'markdown-preview.nvim' and args.data.kind ~= 'delete' then
            local cmd = vim.fn.has('win32') == 1 and { 'cmd.exe', '/c', 'install.cmd' } or { './install.sh' }
            vim.system(cmd, { cwd = args.data.path .. '/app' })
        end
    end,
})
