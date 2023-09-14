-- Find TODOs.
vim.api.nvim_create_user_command('Todos', function()
    require('fzf-lua').grep { search = [[TODO:|todo!\(.*\)]], no_esc = true }
end, { desc = 'TODOs' })

-- Highlight on yank.
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
    callback = function()
        vim.highlight.on_yank { higroup = 'Visual' }
    end,
})

-- Close some filetypes with <q>.
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('CloseWithQ', { clear = true }),
    pattern = {
        'checkhealth',
        'help',
        'man',
        'qf',
        'query',
        'spectre_panel',
    },
    callback = function(event)
        vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf })
    end,
})

-- Do not include some filetypes in the buffer list.
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('Unlisted', { clear = true }),
    pattern = 'checkhealth',
    callback = function(event)
        vim.bo[event.buf].buflisted = false
    end,
})

-- Open plugin repos with gx.
vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('GxWithPlugins', { clear = true }),
    callback = function()
        if vim.fn.getcwd() == vim.fn.stdpath 'config' then
            vim.keymap.set('n', 'gx', function()
                local file = vim.fn.expand '<cfile>' --[[@as string]]

                -- First try the default behaviour from https://github.com/neovim/neovim/blob/597355deae2ebddcb8b930da9a8b45a65d05d09b/runtime/lua/vim/_editor.lua#L1084.
                local _, err = vim.ui.open(file)
                if not err then
                    return
                end

                -- Consider anything that looks like string/string a GitHub link.
                local link = file:match '%w[%w%-]+/[%w%-%._]+'
                if link then
                    _, err = vim.ui.open('https://www.github.com/' .. link)
                end

                -- If that fails, just blame me.
                if err then
                    vim.notify(err, vim.log.levels.ERROR)
                end
            end, { desc = 'Open filepath or URI under cursor' })
        end
    end,
})

-- Toggle relative line numbers.
local line_numbers_group = vim.api.nvim_create_augroup('ToggleLineNumbers', {})
vim.api.nvim_create_autocmd({ 'BufEnter', 'FocusGained', 'InsertLeave', 'CmdlineLeave', 'WinEnter' }, {
    group = line_numbers_group,
    callback = function()
        if vim.wo.nu and vim.api.nvim_get_mode().mode:sub(1, 1) ~= 'i' then
            vim.wo.relativenumber = true
        end
    end,
})
vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost', 'InsertEnter', 'CmdlineEnter', 'WinLeave' }, {
    group = line_numbers_group,
    callback = function(args)
        if vim.wo.nu then
            vim.wo.relativenumber = false
        end

        -- Redraw here to avoid having to first write something for the line numbers to update.
        if args.event == 'CmdlineEnter' then
            vim.cmd.redraw()
        end
    end,
})
