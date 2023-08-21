-- Highlight rust todo!().
vim.b.minihipatterns_config = {
    highlighters = {
        rust_todo = { pattern = 'todo!', group = 'MiniHipatternsTodo' },
    },
}
