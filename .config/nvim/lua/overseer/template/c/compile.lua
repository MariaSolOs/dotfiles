-- Task to compile C programs.
return {
    name = 'gcc: compile',
    builder = function()
        return {
            name = 'gcc: compile',
            cmd = { 'gcc' },
            args = {
                '-O',
                '-Wall',
                '-W',
                '-pedantic',
                '-ansi',
                vim.fn.expand '%:p',
                '-o',
                vim.fn.expand '%:t:r',
            },
        }
    end,
    condition = {
        filetype = { 'c' },
    },
}
