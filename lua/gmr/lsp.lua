--- @class FileTypeEventArgs
--- @field buf number
--- @field event number
--- @field file number
--- @field id number
--- @field match string

local methods = vim.lsp.protocol.Methods

--- @param lhs string
--- @param rhs string|function
--- @param bufnr number
local function keymap(lhs, rhs, bufnr)
    vim.keymap.set(
        'n',
        lhs,
        rhs,
        { noremap = true, silent = true, buffer = bufnr }
    )
end

--- @param client vim.lsp.Client
--- @param bufnr integer
local function on_attach(client, bufnr)
    vim.api.nvim_set_option_value(
        'omnifunc',
        'v:lua.vim.lsp.omnifunc',
        { buf = bufnr }
    )

    keymap('<space>e', vim.diagnostic.open_float, bufnr)
    keymap('[d', function()
        vim.diagnostic.jump { count = -1, float = true }
    end, bufnr)
    keymap('[d', function()
        vim.diagnostic.jump { count = 1, float = true }
    end, bufnr)
    keymap('<space>q', vim.diagnostic.setloclist, bufnr)
    keymap('gd', vim.lsp.buf.definition, bufnr)
    keymap('J', vim.lsp.buf.hover, bufnr)
    keymap('gi', vim.lsp.buf.implementation, bufnr)
    keymap('K', vim.lsp.buf.signature_help, bufnr)
    keymap('<space>wa', vim.lsp.buf.add_workspace_folder, bufnr)
    keymap('<space>wr', vim.lsp.buf.remove_workspace_folder, bufnr)
    keymap('<space>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufnr)
    keymap('<space>D', vim.lsp.buf.type_definition, bufnr)
    keymap('<space>rn', vim.lsp.buf.rename, bufnr)
    keymap('<space>ca', vim.lsp.buf.code_action, bufnr)
    keymap('gr', vim.lsp.buf.references, bufnr)
    keymap('<space>fo', function()
        vim.lsp.buf.format { async = true }
    end, bufnr)
    keymap('<leader>ds', vim.lsp.buf.document_symbol, bufnr)
    keymap('<leader>ws', vim.lsp.buf.workspace_symbol, bufnr)

    if client.supports_method(methods.textDocument_declaration) then
        keymap('gD', vim.lsp.buf.declaration, bufnr)
    end

    if client.supports_method(methods.textDocument_documentHighlight) then
        local augroup = vim.api.nvim_create_augroup(
            'gmr_lsp_document_highlight',
            { clear = false }
        )

        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            group = augroup,
            desc = 'Highlight references under the cursor',
            buffer = bufnr,
            callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            group = augroup,
            desc = 'Clear highlight references after move cursor',
            buffer = bufnr,
            callback = vim.lsp.buf.clear_references,
        })
    end

    if client.supports_method(methods.textDocument_inlayHint) then
        keymap('<leader>ih', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end, bufnr)
    end
end

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'go',
    callback = function(args) --- @param args FileTypeEventArgs
        vim.lsp.start({
            cmd = { 'gopls' },
            filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
            root_dir = vim.fs.root(args.buf, { 'go.mod', 'go.work' }),
            on_attach = on_attach,
            settings = {
                gopls = {
                    gofumpt = true,
                    usePlaceholders = false,
                    semanticTokens = false,
                    ['ui.inlayhint.hints'] = {
                        assignVariableTypes = true,
                        compositeLiteralFields = true,
                        compositeLiteralTypes = false,
                        constantValues = true,
                        functionTypeParameters = true,
                        parameterNames = true,
                        rangeVariableTypes = true,
                    },
                },
            },
        }, { silent = false })
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'rust',
    callback = function(args) --- @param args FileTypeEventArgs
        vim.lsp.start({
            cmd = { 'rust-analyzer' },
            filetypes = { 'rust' },
            root_dir = vim.fs.root(args.buf, { 'Cargo.toml' }),
            on_attach = on_attach,
        }, { silent = false })
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = {
        'javascript',
        'typescript',
        'javascriptreact',
        'typescriptreact',
    },
    callback = function(args) --- @param args FileTypeEventArgs
        vim.lsp.start({
            cmd = { 'typescript-language-server', '--stdio' },
            root_dir = vim.fs.root(args.buf, { 'package.json' }),
            on_attach = on_attach,
            init_options = { hostInfo = 'neovim' },
            filetypes = {
                'javascript',
                'javascriptreact',
                'javascript.jsx',
                'typescript',
                'typescriptreact',
                'typescript.tsx',
            },
        }, { silent = false })
    end,
})

local severity_strings = {
    [1] = 'error',
    [2] = 'warn',
    [3] = 'info',
    [4] = 'hint',
}

vim.diagnostic.config {
    underline = true,
    virtual_text = {
        source = false,
        spacing = 1,
        suffix = '',
        format = function(diagnostic)
            return string.format(
                '%s: %s: %s ',
                severity_strings[diagnostic.severity],
                diagnostic.source,
                diagnostic.message
            )
        end,
    },
    signs = false,
    float = { source = true, border = 'single' },
    update_in_insert = false,
    severity_sort = true,
}

local function goto_definition()
    local util = vim.lsp.util
    local log = require 'vim.lsp.log'
    local api = vim.api

    local handler = function(_, result, ctx)
        local split_cmd = 'vsplit'

        if
            vim.uv.os_uname().sysname == 'Linux'
            and os.getenv 'DESKTOP_SESSION' == 'hyprland'
        then
            local output_hyprctl = vim.fn.system 'hyprctl -j activewindow'
            --- @class HyprlandWindow
            --- @field size number[]
            local json = vim.json.decode(output_hyprctl)

            local size_x, size_y = json.size[1], json.size[2]

            if size_y > size_x then
                split_cmd = 'split'
            end
        end

        if result == nil or vim.tbl_isempty(result) then
            local _ = log.info() and log.info(ctx.method, 'No location found')
            return nil
        end

        local first_visible_line = vim.fn.line 'w0'
        local last_visible_line = vim.fn.line 'w$'

        local definition = result[1]

        local buf = vim.api.nvim_get_current_buf()
        local filename = vim.api.nvim_buf_get_name(buf)

        local uri = definition.uri or definition.targetUri

        if 'file://' .. filename ~= uri then
            vim.cmd(split_cmd)
        else
            local range = definition.range or definition.targetSelectionRange
            local line_definition = range.start.line

            if line_definition == 0 then
                line_definition = 1
            end

            if
                line_definition < first_visible_line
                or line_definition > last_visible_line
            then
                vim.cmd(split_cmd)
            end
        end

        if vim.islist(result) then
            util.jump_to_location(result[1], 'utf-8')

            if #result > 1 then
                vim.fn.setqflist(util.locations_to_items(result, 'utf-8'))
                api.nvim_command 'copen'
                api.nvim_command 'wincmd p'
            end
        else
            util.jump_to_location(result, 'utf-8')
        end
    end

    return handler
end

vim.lsp.handlers[methods.textDocument_definition] = goto_definition()

vim.lsp.handlers[methods.textDocument_hover] =
    vim.lsp.with(vim.lsp.handlers.hover, { border = 'single' })

vim.lsp.handlers[methods.textDocument_signatureHelp] =
    vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'single' })
