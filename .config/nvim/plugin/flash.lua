local add_on_event = require('vim-pack').add_on_event

-- TODO: Remove this once Folke fixes https://github.com/folke/flash.nvim/issues/491.
-- Hacky fix taken from https://github.com/folke/flash.nvim/pull/492#issuecomment-5109768427.
local function patch_flash_searchstate()
    local Hacks = require 'flash.hacks' -- triggers flash's own ffi.cdef of the old symbols
    local ffi = require 'ffi'

    -- Old standalone symbol still resolvable? then leave flash's own hacks alone.
    if pcall(function()
        return ffi.C.search_match_lines
    end) then
        return
    end

    -- New: SearchState struct (src/nvim/search_defs.h), exported global `Search`.
    pcall(
        ffi.cdef,
        [[
      typedef struct {
        bool    hl_match;
        int32_t match_lines;
        int     match_endcol;
        int32_t first_line;
        int32_t last_line;
        bool    no_smartcase;
        int     cmdlen;
        bool    no_hlsearch;
      } SearchState;
      SearchState Search;
    ]]
    )

    -- Struct not resolvable? leave flash as-is (don't make it worse).
    if not pcall(function()
        return ffi.C.Search.match_lines
    end) then
        return
    end

    local C = ffi.C
    local Pos = require 'flash.search.pos'
    local incsearch_state = {}

    ---@diagnostic disable-next-line: duplicate-set-field
    function Hacks.get_end_pos(from)
        local ret = Pos {
            from[1] + C.Search.match_lines,
            math.max(0, C.Search.match_endcol - 1),
        }
        local line = vim.api.nvim_buf_get_lines(0, ret[1] - 1, ret[1], false)[1]
        local char_idx = vim.fn.charidx(line, ret[2])
        ret[2] = vim.fn.byteidx(line, char_idx)
        return ret
    end

    ---@diagnostic disable-next-line: duplicate-set-field
    function Hacks.save_incsearch_state()
        incsearch_state = {
            match_endcol = C.Search.match_endcol,
            match_lines = C.Search.match_lines,
        }
    end

    ---@diagnostic disable-next-line: duplicate-set-field
    function Hacks.restore_incsearch_state()
        C.Search.match_endcol = incsearch_state.match_endcol
        C.Search.match_lines = incsearch_state.match_lines
    end
end

-- Navigation with jump motions.
add_on_event('UIEnter', {
    {
        src = 'folke/flash.nvim',
        opts = {
            jump = { nohlsearch = true },
            prompt = {
                win_config = {
                    border = 'none',
                    -- Place the prompt above the statusline.
                    row = -3,
                },
            },
            search = {
                exclude = {
                    'flash_prompt',
                    'qf',
                    function(win)
                        -- Non-focusable windows.
                        return not vim.api.nvim_win_get_config(win).focusable
                    end,
                },
            },
            modes = {
                -- Enable flash when searching with ? or /
                search = { enabled = true },
            },
        },
        on_setup = function()
            patch_flash_searchstate()

            vim.keymap.set({ 'n', 'x', 'o' }, 's', function()
                require('flash').jump()
            end, { desc = 'Flash' })
            vim.keymap.set('o', 'r', function()
                require('flash').treesitter_search()
            end, { desc = 'Treesitter Search' })
            vim.keymap.set('o', 'R', function()
                require('flash').remote()
            end, { desc = 'Remote Flash' })
        end,
    },
})
