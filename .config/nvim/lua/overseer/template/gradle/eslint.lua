return {
    name = 'gw eslint',
    builder = function()
        return {
            cmd = 'gw',
            args = { 'eslint', '--continue' },
            components = {
                { 'on_output_parse', problem_matcher = '$eslint-stylish' },
                { 'on_result_diagnostics_quickfix', open = true },
                'default',
            },
        }
    end,
    condition = {
        dir = vim.g.work_projects_dir,
    },
}
