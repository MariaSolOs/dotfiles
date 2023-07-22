-- Make the leader a noop when not followed by something.
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap.
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Keeping the cursor centered.
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll downwards', silent = true })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll upwards', silent = true })
vim.keymap.set('n', 'n', 'nzzzv', { silent = true })
vim.keymap.set('n', 'N', 'Nzzzv', { silent = true })

-- Add undo break-points.
vim.keymap.set('i', ',', ',<c-g>u', { silent = true })
vim.keymap.set('i', '.', '.<c-g>u', { silent = true })
vim.keymap.set('i', ';', ';<c-g>u', { silent = true })

-- Indent while remaining in visual mode.
vim.keymap.set('v', '<', '<gv', { silent = true })
vim.keymap.set('v', '>', '>gv', { silent = true })

-- Command for opening this file.
vim.keymap.set('n', '<leader>C', ':e $MYVIMRC<cr>', { desc = 'Neovim configuration', silent = true })

-- Switch between windows.
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to the left window', silent = true, remap = true })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to the bottom window', silent = true, remap = true })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to the top window', silent = true, remap = true })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to the right window', silent = true, remap = true })

-- Clear search with <esc>
vim.keymap.set('n', '<esc>', ':noh<cr><esc>', { desc = 'Escape and clear hlsearch', silent = true })

-- Escape and save changes.
vim.keymap.set(
    { 's', 'i', 'n', 'v' },
    '<C-s>',
    '<esc>:w<cr>',
    { desc = 'Exit insert mode and save changes.', silent = true }
)

-- HACK: <C-c> doesn't trigger the insert leave event, so remap it to escape so that it does.
vim.keymap.set('i', '<C-c>', '<esc>', { silent = true })

-- Floating terminal.
vim.keymap.set('n', '<M-t>', function()
    require('helpers.float_term').float_term(nil, {})
end, { desc = 'Open terminal', silent = true })
vim.keymap.set('t', '<M-t>', '<cmd>close<cr>', { desc = 'Close terminal', silent = true })
