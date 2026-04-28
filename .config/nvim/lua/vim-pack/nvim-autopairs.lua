local add_on_event = require('vim-pack').add_on_event

-- Autoclosing braces.
add_on_event('InsertEnter', {
    {
        src = 'windwp/nvim-autopairs',
        opts = {},
        on_setup = function()
            local Rule = require 'nvim-autopairs.rule'
            local conds = require 'nvim-autopairs.conds'

            -- Autoclosing angle-brackets.
            require('nvim-autopairs').add_rule(Rule('<', '>', {
                -- Avoid conflicts with nvim-ts-autotag.
                '-html',
                '-javascriptreact',
                '-typescriptreact',
            }):with_pair(conds.before_regex('%a+:?:?$', 3)):with_move(function(opts)
                return opts.char == '>'
            end))
        end,
    },
})
