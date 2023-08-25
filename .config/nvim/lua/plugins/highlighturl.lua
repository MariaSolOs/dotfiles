-- Highlight URLs.
return {
    {
        'itchyny/vim-highlighturl',
        event = 'ColorScheme',
        -- Must be a function because lazy cannot handle config = true with vim plugins.
        config = function() end,
    },
}
