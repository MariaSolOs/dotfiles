local endpoint = vim.env.MINUET_ENDPOINT
if not endpoint or endpoint == '' then
    return -- Don't fall back to Minuet's default endpoint.
end

local add = require('vim-pack').add

-- AI completions.
add {
    {
        src = 'milanglacier/minuet-ai.nvim',
        module_name = 'minuet',
        opts = {
            provider = 'openai_compatible',
            n_completions = 1,
            provider_options = {
                openai_compatible = {
                    name = 'Femur',
                    model = 'gpt-4.1-mini',
                    end_point = endpoint,
                    api_key = 'LLM_PORTAL_TOKEN',
                    stream = false,
                    optional = { max_completion_tokens = 128 },
                },
            },
            virtualtext = {
                auto_trigger_ft = { '*' },
                show_on_completion_menu = true,
                keymap = {
                    next = '<M-n>',
                    accept = '<C-.>',
                    accept_line = '<M-l>',
                },
            },
        },
    },
}
