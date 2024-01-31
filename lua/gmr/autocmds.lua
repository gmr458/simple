vim.api.nvim_create_autocmd('VimLeave', {
    group = vim.api.nvim_create_augroup(
        'gmr_restore_cursor_shape_on_exit',
        { clear = true }
    ),
    pattern = { '*' },
    desc = 'Restores horizontal shape cursor for Alacritty on exit',
    callback = function()
        vim.opt.guicursor = 'a:hor1'
    end,
})

vim.api.nvim_create_autocmd('TermOpen', {
    group = vim.api.nvim_create_augroup(
        'gmr_clean_term_mode',
        { clear = true }
    ),
    pattern = { '*' },
    desc = '',
    callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = 'no'
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup(
        'gmr_json_conceal_level_0',
        { clear = true }
    ),
    desc = 'Disable conceallevel and spell for JSON and JSONC',
    pattern = { 'json', 'jsonc' },
    callback = function()
        vim.opt_local.spell = false
        vim.opt_local.conceallevel = 0
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('gmr_close_with_q', { clear = true }),
    desc = 'Close with <q>',
    pattern = {
        'help',
        'man',
        'qf',
        'query',
        'scratch',
        'spectre_panel',
    },
    callback = function(args)
        vim.keymap.set('n', 'q', '<cmd>quit<cr>', { buffer = args.buf })
    end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup(
        'gmr_highlight_on_yank',
        { clear = true }
    ),
    desc = 'Highlight on yank',
    callback = function()
        -- Setting a priority higher than the LSP references one.
        vim.highlight.on_yank { higroup = 'Visual', priority = 250 }
    end,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
    group = vim.api.nvim_create_augroup(
        'gmr_avoid_comment_new_line',
        { clear = true }
    ),
    desc = 'Avoid comment on new line',
    command = 'set formatoptions-=cro',
})

vim.api.nvim_create_autocmd('VimResized', {
    group = vim.api.nvim_create_augroup(
        'gmr_consistent_size_buffers',
        { clear = true }
    ),
    desc = 'Keep consistent size for buffers',
    command = 'tabdo wincmd =',
})

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup(
        'gmr_wrap_spell_for_writing',
        { clear = true }
    ),
    pattern = { 'gitcommit', 'markdown' },
    desc = 'Enable wrap and spell on Git Commits and Markdown',
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end,
})

vim.api.nvim_create_autocmd('CmdlineEnter', {
    group = vim.api.nvim_create_augroup(
        'gmr_cmdheight_1_on_cmdlineenter',
        { clear = true }
    ),
    desc = 'Don\'t hide the status line when typing a command',
    command = ':set cmdheight=1',
})

vim.api.nvim_create_autocmd('CmdlineLeave', {
    group = vim.api.nvim_create_augroup(
        'gmr_cmdheight_0_on_cmdlineleave',
        { clear = true }
    ),
    desc = 'Hide cmdline when not typing a command',
    command = ':set cmdheight=0',
})

vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup(
        'gmr_hide_message_after_write',
        { clear = true }
    ),
    desc = 'Get rid of message after writing a file',
    pattern = { '*' },
    command = 'redrawstatus',
})