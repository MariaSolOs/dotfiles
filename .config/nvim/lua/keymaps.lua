-- Remap for dealing with word wrap and adding jumps to the jumplist.
vim.keymap.set('n', 'j', [[(v:count > 1 ? 'm`' . v:count : 'g') . 'j']], { expr = true })
vim.keymap.set('n', 'k', [[(v:count > 1 ? 'm`' . v:count : 'g') . 'k']], { expr = true })

-- Keeping the cursor centered.
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll downwards' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll upwards' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next result' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous result' })

-- Indent while remaining in visual mode.
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- Formatting.
vim.keymap.set('n', 'gQ', 'mzgggqG`z<cmd>delmarks z<cr>zz', { desc = 'Format buffer' })

-- Toggle the quickfix/loclist window.
-- When toggling these, ignore error messages and restore the cursor to the original window when opening the list.
local silent_mods = { mods = { silent = true, emsg_silent = true } }
vim.keymap.set('n', '<leader>xq', function()
    if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
        vim.cmd.cclose(silent_mods)
    elseif #vim.fn.getqflist() > 0 then
        local win = vim.api.nvim_get_current_win()
        vim.cmd.copen(silent_mods)
        if win ~= vim.api.nvim_get_current_win() then
            vim.cmd.wincmd 'p'
        end
    end
end, { desc = 'Toggle quickfix list' })
vim.keymap.set('n', '<leader>xl', function()
    if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
        vim.cmd.lclose(silent_mods)
    elseif #vim.fn.getloclist(0) > 0 then
        local win = vim.api.nvim_get_current_win()
        vim.cmd.lopen(silent_mods)
        if win ~= vim.api.nvim_get_current_win() then
            vim.cmd.wincmd 'p'
        end
    end
end, { desc = 'Toggle location list' })
-- ...and navigating through the items.
vim.keymap.set('n', '[q', '<cmd>cprev<cr>zvzz', { desc = 'Previous quickfix item' })
vim.keymap.set('n', ']q', '<cmd>cnext<cr>zvzz', { desc = 'Next quickfix item' })
vim.keymap.set('n', '[l', '<cmd>lprev<cr>zvzz', { desc = 'Previous loclist item' })
vim.keymap.set('n', ']l', '<cmd>lnext<cr>zvzz', { desc = 'Next loclist item' })

-- Use dressing for spelling suggestions.
vim.keymap.set('n', 'z=', function()
    vim.ui.select(
        vim.fn.spellsuggest(vim.fn.expand '<cword>'),
        {},
        vim.schedule_wrap(function(selected)
            if selected then
                vim.cmd('normal! ciw' .. selected)
            end
        end)
    )
end, { desc = 'Spelling suggestions' })

-- Open the package manager.
vim.keymap.set('n', '<leader>L', '<cmd>Lazy<cr>', { desc = 'Lazy' })

-- Switch between windows.
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to the left window', remap = true })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to the bottom window', remap = true })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to the top window', remap = true })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to the right window', remap = true })

-- Tab navigation.
vim.keymap.set('n', '<leader>tc', '<cmd>tabclose<cr>', { desc = 'Close tab page' })
vim.keymap.set('n', '<leader>tn', '<cmd>tab split<cr>', { desc = 'New tab page' })
vim.keymap.set('n', '<leader>to', '<cmd>tabonly<cr>', { desc = 'Close other tab pages' })

-- Clear search with <esc>.
vim.keymap.set('n', '<esc>', '<cmd>noh<cr><esc>', { desc = 'Escape and clear hlsearch' })

-- Make U opposite to u.
vim.keymap.set('n', 'U', '<C-r>', { desc = 'Redo' })

-- Escape and save changes.
vim.keymap.set({ 's', 'i', 'n', 'v' }, '<C-s>', '<esc>:w<cr>', { desc = 'Exit insert mode and save changes.' })

-- Execute macro over a visual region.
vim.keymap.set('x', '@', function()
    return ':norm @' .. vim.fn.getcharstr() .. '<cr>'
end, { expr = true })

-- Word navigation in non-normal modes.
vim.keymap.set({ 'i', 'c' }, '<C-h>', '<C-Left>', { desc = 'Move word(s) backwards' })
vim.keymap.set({ 'i', 'c' }, '<C-l>', '<C-Right>', { desc = 'Move word(s) forwards' })
