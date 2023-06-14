-- Copilot.
return {
    {
        'zbirenbaum/copilot.lua',
        cmd = 'Copilot',
        event = 'InsertEnter',
        opts = {
            suggestion = {
                -- Use alt for interacting with the suggestions.
                keymap = {
                    accept = '<M-Enter>',
                    accept_word = '<M-Space>',
                    next = '<M-]>',
                    prev = '<M-[>',
                    dismiss = '<M-/>',
                },
                auto_trigger = true
            },
            -- I don't care or use the panel.
            panel = {
                enabled = false,
            }
        }
    },
}
