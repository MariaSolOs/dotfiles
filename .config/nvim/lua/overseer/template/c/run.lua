-- Run C programs.
return {
    name = 'gcc: run',
    builder = function()
        return {
            name = 'gcc: run',
            cmd = { vim.fn.expand '%:p:r' },
            components = {
                { 'dependencies', task_names = { 'gcc: compile' } },
                'default',
            },
        }
    end,
    condition = {
        filetype = { 'c' },
    },
}
