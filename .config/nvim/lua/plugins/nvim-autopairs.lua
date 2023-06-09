-- Autoclosing braces.
return {
    {
        'windwp/nvim-autopairs',
        opts = { disable_filetype = { 'TelescopePrompt' } },
        config = function(_, opts)
            require('nvim-autopairs').setup(opts)

            -- Setup cmp for autopairs.
            local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
            require('cmp').event:on('confirm_done', cmp_autopairs.on_confirm_done())
        end,
    }
}
