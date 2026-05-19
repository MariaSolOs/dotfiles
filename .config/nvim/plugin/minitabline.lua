local add_on_event = require('vim-pack').add_on_event

-- Pretty tabline showing listed buffers.
add_on_event('VimEnter', { { src = 'nvim-mini/mini.tabline' } })
