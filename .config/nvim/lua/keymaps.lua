-- Make all keymaps silent by default.
local keymap_set = vim.keymap.set
---@diagnostic disable-next-line: duplicate-set-field
vim.keymap.set = function(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.silent = opts.silent ~= false
    return keymap_set(mode, lhs, rhs, opts)
end

-- Make the leader a noop when not followed by something.
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>')

-- Remap for dealing with word wrap.
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- Keeping the cursor centered.
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll downwards' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll upwards' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next result' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous result' })

-- Add undo break-points.
vim.keymap.set('i', ',', ',<c-g>u')
vim.keymap.set('i', '.', '.<c-g>u')
vim.keymap.set('i', ';', ';<c-g>u')

-- Indent while remaining in visual mode.
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- Open the package manager.
vim.keymap.set('n', '<leader>L', '<cmd>Lazy<cr>', { desc = 'Lazy' })

-- Switch between windows.
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to the left window', remap = true })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to the bottom window', remap = true })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to the top window', remap = true })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to the right window', remap = true })

-- Clear search with <esc>
vim.keymap.set('n', '<esc>', '<cmd>noh<cr><esc>', { desc = 'Escape and clear hlsearch' })

-- Escape and save changes.
vim.keymap.set({ 's', 'i', 'n', 'v' }, '<C-s>', '<esc>:w<cr>', { desc = 'Exit insert mode and save changes.' })

-- Execute macro over visual region.
vim.keymap.set('x', '@', function()
    return ':norm @' .. vim.fn.getcharstr() .. '<cr>'
end, { expr = true })

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
end, { desc = 'Opens filepath or URI under cursor' })

-- HACK: <C-c> doesn't trigger the insert leave event, so remap it to escape so that it does.
vim.keymap.set('i', '<C-c>', '<esc>')

-- Floating terminal.
vim.keymap.set('n', '<M-t>', function()
    require('float_term').float_term(nil, {})
end, { desc = 'Open terminal' })
vim.keymap.set('t', '<M-t>', '<cmd>close<cr>', { desc = 'Close terminal' })
vim.keymap.set('t', '<C-p>', '<Up>', { desc = 'Previous command' })
vim.keymap.set('t', '<C-n>', '<Down>', { desc = 'Next command' })
