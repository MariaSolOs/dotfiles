-- NOTE: Ordered alphabetically by group name.

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('mariasolos/close_with_q', { clear = true }),
    desc = 'Close with <q>',
    pattern = {
        'help',
        'man',
        'qf',
        'query',
        'scratch',
        'spectre_panel',
    },
    callback = function(args)
        vim.keymap.set('n', 'q', '<cmd>quit<cr>', { buffer = args.buf })
    end,
})

vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('mariasolos/dotfiles_setup', { clear = true }),
    desc = 'Special dotfiles setup',
    callback = function()
        local ok, inside_dotfiles = pcall(vim.startswith, vim.fn.getcwd(), vim.env.XDG_CONFIG_HOME)
        if not ok or not inside_dotfiles then
            return
        end

        -- Configure git environment.
        vim.env.GIT_WORK_TREE = vim.env.HOME
        vim.env.GIT_DIR = vim.env.HOME .. '/.cfg'

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
    end,
})

vim.api.nvim_create_autocmd('CmdwinEnter', {
    group = vim.api.nvim_create_augroup('mariasolos/execute_cmd_and_stay', { clear = true }),
    desc = 'Execute command and stay in the command-line window',
    callback = function(args)
        vim.keymap.set({ 'n', 'i' }, '<S-CR>', '<cr>q:', { buffer = args.buf })
    end,
})

vim.api.nvim_create_autocmd('BufReadPost', {
    group = vim.api.nvim_create_augroup('mariasolos/last_location', { clear = true }),
    desc = 'Go to the last location when opening a buffer',
    callback = function(args)
        local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
        local line_count = vim.api.nvim_buf_line_count(args.buf)
        if mark[1] > 0 and mark[1] <= line_count then
            vim.cmd 'normal! g`"zz'
        end
    end,
})

local line_numbers_group = vim.api.nvim_create_augroup('mariasolos/toggle_line_numbers', {})
vim.api.nvim_create_autocmd({ 'BufEnter', 'FocusGained', 'InsertLeave', 'CmdlineLeave', 'WinEnter' }, {
    group = line_numbers_group,
    desc = 'Toggle relative line numbers on',
    callback = function()
        if vim.wo.nu and not vim.startswith(vim.api.nvim_get_mode().mode, 'i') then
            vim.wo.relativenumber = true
        end
    end,
})
vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost', 'InsertEnter', 'CmdlineEnter', 'WinLeave' }, {
    group = line_numbers_group,
    desc = 'Toggle relative line numbers off',
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

vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = vim.api.nvim_create_augroup('mariasolos/wshada_on_buf_delete', { clear = true }),
    desc = 'Write to ShaDa when deleting/wiping out buffers',
    command = 'wshada',
})

vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('mariasolos/yank_highlight', { clear = true }),
    desc = 'Highlight on yank',
    callback = function()
        -- Setting a priority higher than the LSP references one.
        vim.highlight.on_yank { higroup = 'Visual', priority = 250 }
    end,
})
