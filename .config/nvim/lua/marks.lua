---Custom mark API.
---Implementation slightly inspired by https://github.com/chentoast/marks.nvim, but this is
---much simpler.

---Map of mark information per buffer.
---@type table<integer, table<string, {line: integer, id: integer}>>
local marks = {}

---Keeps track of the signs I've already created.
---@type table<string, boolean>
local sign_cache = {}

---The sign and autocommand group name.
local sign_group_name = 'mariasolos/marks_signs'

---@param mark string
local function is_lowercase_mark(mark)
    return 97 <= mark:byte() and mark:byte() <= 122
end

---@param mark string
local function is_uppercase_mark(mark)
    return 65 <= mark:byte() and mark:byte() <= 90
end

---@param mark string
local function is_letter_mark(mark)
    return is_lowercase_mark(mark) or is_uppercase_mark(mark)
end

---@param mark string
---@param bufnr integer
local function delete_mark(mark, bufnr)
    local buffer_marks = marks[bufnr]
    if not buffer_marks or not buffer_marks[mark] then
        return
    end

    vim.fn.sign_unplace(sign_group_name, { buffer = bufnr, id = buffer_marks[mark].id })
    buffer_marks[mark] = nil

    if is_letter_mark(mark) then
        vim.cmd('delmarks ' .. mark)
    end
end

---@param mark string
---@param bufnr integer
---@param line? integer
local function register_mark(mark, bufnr, line)
    local buffer_marks = marks[bufnr]
    if not buffer_marks then
        return
    end

    if buffer_marks[mark] then
        -- Mark already exists, remove it first.
        delete_mark(mark, bufnr)
    end

    -- Add the sign to the tracking table.
    local id = mark:byte() * 100
    line = line or vim.api.nvim_win_get_cursor(0)[1]
    buffer_marks[mark] = { line = line, id = id }

    -- Create the sign.
    local sign_name = 'marks_' .. mark
    if not sign_cache[sign_name] then
        vim.fn.sign_define(sign_name, { text = mark, texthl = 'DiagnosticSignOk' })
        sign_cache[sign_name] = true
    end
    vim.fn.sign_place(id, sign_group_name, sign_name, bufnr, {
        lnum = line,
        priority = 10,
    })
end

---@param bufnr integer
local function set_keymaps(bufnr)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'm', '', {
        desc = 'Add mark',
        callback = function()
            local ok, mark = pcall(function()
                return vim.fn.getcharstr()
            end)
            if not ok then
                return
            end

            if is_letter_mark(mark) then
                register_mark(mark, bufnr)
                vim.cmd('normal! m' .. mark)
            end
        end,
    })

    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'dm', '', {
        desc = 'Delete mark',
        callback = function()
            local ok, mark = pcall(function()
                return vim.fn.getcharstr()
            end)
            if not ok then
                return
            end

            if is_letter_mark(mark) then
                delete_mark(mark, bufnr)
            end
        end,
    })

    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'dm-', '', {
        desc = 'Delete all buffer marks',
        callback = function()
            -- NOTE: This will delete the builtin marks too, but I'll restore
            -- them on cursor move so whatever.
            marks[bufnr] = {}
            vim.fn.sign_unplace(sign_group_name, { buffer = bufnr })
            vim.cmd 'delmarks!'
        end,
    })
end

---@param bufnr integer
local function refresh_builtin_marks(bufnr)
    for _, builtin_mark in ipairs { '.', '`' } do
        local pos = vim.fn.getpos("'" .. builtin_mark)
        local cached_mark = marks[bufnr][builtin_mark]
        if (pos[1] == 0 or pos[1] == bufnr) and pos[2] ~= 0 and (not cached_mark or pos[2] ~= cached_mark.line) then
            register_mark(builtin_mark, bufnr, pos[2])
        end
    end
end

vim.api.nvim_create_autocmd('BufWinEnter', {
    group = vim.api.nvim_create_augroup(sign_group_name, { clear = true }),
    desc = 'Configure mark signs',
    callback = function(event)
        local bufnr = event.buf

        -- Only handle normal buffers.
        if vim.bo[bufnr].bt ~= '' then
            return
        end

        -- Set custom mappings.
        set_keymaps(bufnr)

        if not marks[bufnr] then
            marks[bufnr] = {}
        end

        -- Remove all marks that were deleted.
        for mark, _ in pairs(marks[bufnr]) do
            if vim.api.nvim_buf_get_mark(bufnr, mark)[1] == 0 then
                delete_mark(mark, bufnr)
            end
        end

        -- Register the letter marks.
        for _, data in ipairs(vim.fn.getmarklist()) do
            local mark = data.mark:sub(2, 3)
            local pos = data.pos
            local cached_mark = marks[bufnr][mark]

            if is_uppercase_mark(mark) and pos[1] == bufnr and (not cached_mark or pos[2] ~= cached_mark.line) then
                register_mark(mark, bufnr, pos[2])
            end
        end
        for _, data in ipairs(vim.fn.getmarklist '%') do
            local mark = data.mark:sub(2, 3)
            local pos = data.pos
            local cached_mark = marks[bufnr][mark]

            if is_lowercase_mark(mark) and (not cached_mark or pos[2] ~= cached_mark.line) then
                register_mark(mark, bufnr, pos[2])
            end
        end

        local buf_group_name = sign_group_name .. tostring(bufnr)
        if pcall(vim.api.nvim_get_autocmds, { group = buf_group_name, buffer = bufnr }) then
            return
        end
        refresh_builtin_marks(bufnr)
        local marks_buf_group = vim.api.nvim_create_augroup(buf_group_name, { clear = true })
        vim.api.nvim_create_autocmd('CursorMoved', {
            group = marks_buf_group,
            desc = 'Refresh signs for builtin marks',
            buffer = bufnr,
            callback = function()
                refresh_builtin_marks(bufnr)
            end,
        })
    end,
})
