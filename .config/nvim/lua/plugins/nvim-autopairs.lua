-- Autoclosing braces.
return {
    {
        'windwp/nvim-autopairs',
        event = 'InsertEnter',
        config = function()
            local npairs = require 'nvim-autopairs'
            local Rule = require 'nvim-autopairs.rule'
            local conds = require 'nvim-autopairs.conds'

            npairs.setup()

            -- Autoclosing angle-brackets for Rust.
            npairs.add_rule(Rule('<', '>', 'rust'):with_pair(conds.before_regex '%a+'):with_move(function(opts)
                return opts.char == '>'
            end))
        end,
    },
}
