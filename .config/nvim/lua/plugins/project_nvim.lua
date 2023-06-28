-- Project management.
return {
    {
        'ahmedkhalf/project.nvim',
        event = 'VeryLazy',
        config = function(_, opts)
            require('project_nvim').setup(opts)
        end,
    },
}
