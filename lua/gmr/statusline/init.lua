local statusline_augroup =
    vim.api.nvim_create_augroup('gmr_statusline', { clear = true })

local function mode()
    local current_mode = vim.api.nvim_get_mode().mode
    local modes = require 'gmr.statusline.modes'

    return string.format(
        '%%#StatusLineMode# %%*%%#StatusLineNeovimLogo#%%*%%#StatusLineMode# %s %%*',
        modes[current_mode]:upper()
    )
end

local function relative_path()
    local path = vim.fn.expand '%:.'
    local extension = vim.fn.expand '%:e'

    local ok, nvim_web_devicons = pcall(require, 'nvim-web-devicons')
    if ok then
        local icon, color = nvim_web_devicons.get_icon_color(
            path,
            extension,
            { default = true, strict = true }
        )

        local bg = vim.api.nvim_get_hl(0, { name = 'StatusLine' }).bg
        local hl_group = string.format('FileIconColor%s', extension)
        vim.api.nvim_set_hl(0, hl_group, { fg = color, bg = bg })

        return string.format(' %%#%s#%s%%* %s', hl_group, icon, path)
    end

    return string.format(' %s', path)
end

local function unsaved()
    if vim.api.nvim_get_option_value('mod', { buf = 0 }) then
        return '%#StatusLineUnsavedFileIcon#*%*'
    end

    return ''
end

local function readonly()
    if vim.bo.readonly then
        return ' '
    end

    return ''
end

local function file_percentage()
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_line_count(0)

    return string.format('%d%%%%', math.ceil(current_line / lines * 100))
end

local function total_lines()
    local lines = vim.fn.line '$'
    local visible_lines = vim.fn.line 'w$'

    if lines <= visible_lines then
        return ''
    end

    return string.format('  %s', lines)
end

--- @param hlgroup string
local function formatted_filetype(hlgroup)
    local filetype = vim.bo.filetype or vim.fn.expand('%:e', false)

    if filetype == '' then
        local buf = vim.api.nvim_get_current_buf()
        local bufname = vim.api.nvim_buf_get_name(buf)

        if bufname == vim.uv.cwd() then
            return string.format('%%#%s#  Directory %%*', hlgroup)
        end
    end

    local filetypes = require 'gmr.statusline.filetypes'

    -- return string.format('%%#StatusLineMedium# %s %%*', filetypes[filetype])
    return string.format('%%#%s# %s %%*', hlgroup, filetypes[filetype])
end

StatusLine = {}

StatusLine.active = function()
    if vim.o.filetype == 'alpha' then
        return table.concat {
            '%#Normal#',
        }
    end

    local mode_str = vim.api.nvim_get_mode()['mode']
    if mode_str == 't' or mode_str == 'nt' then
        return table.concat {
            mode(),
            '%=',
            '%=',
        }
    end

    return table.concat {
        mode(),
        -- relative_path(),
        -- unsaved(),
        -- readonly(),
        '%=',
        '%=',
        file_percentage(),
        total_lines(),
        formatted_filetype 'StatusLineMedium',
    }
end

StatusLine.inactive = function()
    return table.concat {
        formatted_filetype 'StatusLineMode',
    }
end

StatusLine.empty = function()
    return table.concat {
        '%#Normal#',
    }
end

vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
    group = statusline_augroup,
    pattern = { '*' },
    command = 'setlocal statusline=%!v:lua.StatusLine.active()',
})

local inactive_filetypes = {
    'NvimTree_1',
    'NvimTree',
    'qf',
    'TelescopePrompt',
    'fzf',
    'lspinfo',
    'lazy',
    'netrw',
    'mason',
    'help',
    'noice',
}

vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter', 'FileType' }, {
    group = statusline_augroup,
    pattern = inactive_filetypes,
    command = 'setlocal statusline=%!v:lua.StatusLine.inactive()',
})
