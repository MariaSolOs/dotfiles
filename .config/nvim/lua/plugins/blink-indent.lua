-- Indentation guides.
return {
    {
        'saghen/blink.indent',
        opts = {
            static = {
                char = require('icons').misc.vertical_bar,
            },
            scope = {
                char = require('icons').misc.vertical_bar,
                highlights = { 'LineNr' },
            },
        },
    },
}
