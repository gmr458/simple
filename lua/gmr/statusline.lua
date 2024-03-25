local statusline_augroup =
    vim.api.nvim_create_augroup('gmr_statusline', { clear = true })

--- @return string
local function mode()
    return string.format(
        '%%#StatusLineMode# %s %%*',
        vim.api.nvim_get_mode().mode
    )
end

--- @return string
local function file_percentage()
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_line_count(0)

    return string.format(
        '%%#StatusLineMedium# %d%%%% %%*',
        math.ceil(current_line / lines * 100)
    )
end

--- @return string
local function total_lines()
    local lines = vim.fn.line '$'
    return string.format('%%#StatusLineMedium#of %s %%*', lines)
end

StatusLine = {}

StatusLine.active = function()
    local statusline = {
        mode(),
        '%=',
        '%=',
        file_percentage(),
        total_lines(),
    }

    return table.concat(statusline)
end

vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
    group = statusline_augroup,
    pattern = { '*' },
    command = 'setlocal statusline=%!v:lua.StatusLine.active()',
})
