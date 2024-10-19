-- Generate and open GitHub links.
return {
    {
        'ruifm/gitlinker.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        -- Loaded when attaching gitsigns.
        lazy = true,
        opts = { mappings = '<leader>gc' },
        config = function()
            local gitlinker = require 'gitlinker'

            gitlinker.setup {
                mappings = '<leader>gc',
                callbacks = {
                    ['github.palantir.build'] = gitlinker.hosts.get_github_type_url,
                },
            }
        end,
    },
}
