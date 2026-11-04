local plugin_specs = {} --- @type LazySpecImport[]

--- @param plugin string
local function add(plugin)
    local spec = { import = plugin } --- @type LazySpecImport
    table.insert(plugin_specs, spec)
end

add 'gmr.plugins.colorschemes.cold'
add 'gmr.plugins.gitsigns'
add 'gmr.plugins.nvim-tree'
add 'gmr.plugins.scriptease'
add 'gmr.plugins.snacks'

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'

if not vim.uv.fs_stat(lazypath) then
    vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable',
        lazypath,
    }
end

vim.opt.rtp:prepend(lazypath)

require('lazy').setup(plugin_specs, {
    ui = {
        border = 'single',
        backdrop = 100,
    },
    change_detection = {
        enabled = false,
        notify = false,
    },
    performance = {
        rtp = {
            disabled_plugins = {
                'gzip',
                'matchit',
                -- 'matchparen',
                'tarPlugin',
                'tohtml',
                'tutor',
                'zipPlugin',
            },
        },
    },
})
