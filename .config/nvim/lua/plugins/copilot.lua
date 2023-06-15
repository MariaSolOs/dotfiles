-- Copilot.
-- I'm using an integration for listing the actual suggestions
-- inside the completion menu.
return {
    {
        'zbirenbaum/copilot-cmp',
        dependencies = {
            'zbirenbaum/copilot.lua',
            opts = {
                suggestion = { enabled = false },
                panel = { enabled = false }
            }
        },
        config = true
    }
}
