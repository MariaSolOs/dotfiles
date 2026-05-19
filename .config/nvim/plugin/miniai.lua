local add_on_event = require('vim-pack').add_on_event

-- Better text objects.
add_on_event('BufReadPre', {
    {
        src = 'nvim-treesitter/nvim-treesitter-textobjects',
        setup = false,
    },
    {
        src = 'nvim-mini/mini.ai',
        opts = function()
            local miniai = require 'mini.ai'

            return {
                n_lines = 300,
                -- TODO: Add more custom entries?
                custom_textobjects = {
                    f = miniai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }, {}),
                },
                -- Disable error feedback.
                silent = true,
                -- Don't use the previous or next text object.
                search_method = 'cover',
                mappings = {
                    -- Disable next/last variants.
                    around_next = '',
                    inside_next = '',
                    around_last = '',
                    inside_last = '',
                },
            }
        end,
    },
})
