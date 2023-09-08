-- Make the leader a noop when not followed by something.
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>')

-- Remap for dealing with word wrap and adding jumps to the jumplist.
vim.keymap.set('n', 'j', [[(v:count > 1 ? 'm`' . v:count : '') . 'gj']], { expr = true, silent = true })
vim.keymap.set('n', 'k', [[(v:count > 1 ? 'm`' . v:count : '') . 'gk']], { expr = true, silent = true })

-- Keeping the cursor centered.
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll downwards' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll upwards' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next result' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous result' })

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

-- HACK: <C-c> doesn't trigger the insert leave event, so remap it to escape so that it does.
vim.keymap.set('i', '<C-c>', '<esc>')

-- Word navigation in non-normal modes.
vim.keymap.set({ 'i', 'c' }, '<C-h>', '<C-Left>', { desc = 'Move word(s) backwards' })
vim.keymap.set({ 'i', 'c' }, '<C-l>', '<C-Right>', { desc = 'Move word(s) forwards' })

-- Floating terminal.
vim.keymap.set('n', '<M-t>', function()
    require('float_term').float_term(nil, {})
end, { desc = 'Open terminal' })
vim.keymap.set('t', '<M-t>', '<cmd>close<cr>', { desc = 'Close terminal' })
vim.keymap.set('t', '<C-p>', '<Up>', { desc = 'Previous command' })
vim.keymap.set('t', '<C-n>', '<Down>', { desc = 'Next command' })
