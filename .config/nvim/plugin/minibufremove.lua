local add = require('vim-pack').add

-- Save the window layout when closing a buffer.
add {
    {
        src = 'nvim-mini/mini.bufremove',
        on_setup = function()
            vim.keymap.set('n', '<leader>bd', function()
                require('mini.bufremove').delete(0, false)
            end, { desc = 'Delete current buffer' })
        end,
    },
}
