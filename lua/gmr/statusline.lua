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
local function python_env()
    local virtual_env = os.getenv 'VIRTUAL_ENV_PROMPT'
    if virtual_env == nil then
        return ''
    end

    virtual_env = virtual_env:gsub('%s+', '')
    return string.format('%%#StatusLineMedium# %s%%*', virtual_env)
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

--- @param hlgroup string
local function formatted_filetype_or_mode(hlgroup)
    local filetype = vim.bo.filetype or vim.fn.expand('%:e', false)
    return string.format('%%#%s# %s %%*', hlgroup, filetype)
end

StatusLine = {}

StatusLine.inactive = function()
    return table.concat {
        formatted_filetype_or_mode 'StatusLineMode',
    }
end

local redeable_filetypes = {
    ['qf'] = true,
    ['help'] = true,
    ['tsplayground'] = true,
}

StatusLine.active = function()
    local mode_str = vim.api.nvim_get_mode().mode
    if mode_str == 't' or mode_str == 'nt' then
        return table.concat {
            mode(),
            '%=',
            '%=',
            file_percentage(),
            total_lines(),
        }
    end

    if redeable_filetypes[vim.bo.filetype] or vim.o.modifiable == false then
        return table.concat {
            formatted_filetype_or_mode 'StatusLineMode',
            '%=',
            '%=',
            file_percentage(),
            total_lines(),
        }
    end

    local statusline = {
        mode(),
        '%=',
        '%=',
        '%S ',
        python_env(),
        file_percentage(),
        total_lines(),
    }

    return table.concat(statusline)
end

vim.opt.statusline = '%!v:lua.StatusLine.active()'

vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter', 'FileType' }, {
    group = statusline_augroup,
    pattern = {
        'netrw',
        'qf',
    },
    callback = function()
        vim.opt_local.statusline = '%!v:lua.StatusLine.inactive()'
    end,
})
