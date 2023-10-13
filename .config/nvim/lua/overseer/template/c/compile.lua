return {
    name = 'gcc: compile program',
    builder = function()
        return {
            cmd = { 'gcc' },
            args = { vim.fn.expand '%:p', '-o', vim.fn.expand '%:t:r' },
        }
    end,
    condition = {
        filetype = { 'c' },
    },
}
