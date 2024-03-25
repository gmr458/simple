local M = {}

M.winbar_filetype_exclude = {
    'help',
    'netrw',
    '',
}

M.get_filename = function()
    local filename = vim.fn.expand '%:.'
    local utils = require 'gmr.utils'

    if not utils.is_nil_or_empty_string(filename) then
        local readonly = ''
        if vim.bo.readonly then
            readonly = ' %#WarningMsg#READONLY%*'
            -- readonly = ' READONLY'
        end

        return readonly .. ' ' .. '%#WinBar#' .. filename .. '%*'
    end
end

local excludes = function()
    if vim.tbl_contains(M.winbar_filetype_exclude, vim.bo.filetype) then
        vim.opt_local.winbar = nil
        return true
    end

    return false
end

M.get_winbar = function()
    if excludes() then
        return
    end

    local utils = require 'gmr.utils'
    local value = M.get_filename()

    if not utils.is_nil_or_empty_string(value) and utils.is_unsaved() then
        local mod = '%#WarningMsg#*%*'
        value = value .. mod
    end

    local num_tabs = #vim.api.nvim_list_tabpages()

    if num_tabs > 1 and not utils.is_nil_or_empty_string(value) then
        local tabpage_number = tostring(vim.api.nvim_tabpage_get_number(0))
        value = value .. '%=' .. tabpage_number .. '/' .. tostring(num_tabs)
    end

    local status_ok, _ = pcall(
        vim.api.nvim_set_option_value,
        'winbar',
        value,
        { scope = 'local' }
    )

    if not status_ok then
        return
    end
end

M.create_winbar = function()
    vim.api.nvim_create_augroup('gmr_winbar', {})

    vim.api.nvim_create_autocmd({
        'CursorMoved',
        'CursorHold',
        'BufWinEnter',
        'BufFilePost',
        'InsertEnter',
        'BufWritePost',
        'TabClosed',
    }, {
        group = 'gmr_winbar',
        callback = function()
            require('gmr.winbar').get_winbar()
        end,
    })
end

M.create_winbar()

return M
