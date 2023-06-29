-- Scrollbar.
return {
    'petertriho/nvim-scrollbar',
    event = 'BufReadPost',
    opts = {
        handle = {
            blend = 0,
        },
        handlers = {
            cursor = false,
        },
    },
}
