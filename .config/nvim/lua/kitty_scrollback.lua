--- Sets up the buffer for displaying kitty's scrollback. Inspired by https://gist.github.com/galaxia4Eva/9e91c4f275554b4bd844b6feece16b3d.
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_option_value('filetype', 'kitty_scrollback', { buf = buf })

-- Override some settings.
vim.wo.foldcolumn = '0'
vim.o.laststatus = 3

local term = vim.api.nvim_open_term(buf, {})

-- Setup autocommands.
local scrollback_group = vim.api.nvim_create_augroup('mariasolos/kitty_scrollback', { clear = true })
vim.api.nvim_create_autocmd('ModeChanged', {
    group = scrollback_group,
    desc = 'Stop insert mode inside the scrollback buffer',
    buffer = buf,
    command = 'stopinsert',
})
vim.api.nvim_create_autocmd('VimEnter', {
    group = scrollback_group,
    desc = 'Set the scrollback buffer',
    once = true,
    callback = function(ev)
        local win = vim.fn.win_getid()
        for _, line in ipairs(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)) do
            vim.api.nvim_chan_send(term, line)
            vim.api.nvim_chan_send(term, '\r\n')
        end

        vim.api.nvim_win_set_buf(win, buf)
        vim.api.nvim_buf_delete(ev.buf, { force = true })
    end,
})
vim.api.nvim_create_autocmd('TextYankPost', {
    group = scrollback_group,
    desc = 'Highlight on yank',
    callback = function()
        vim.highlight.on_yank { higroup = 'Visual' }
    end,
})
