-- Ported from NMAC427/guess-indent.nvim (lua/guess-indent/init.lua).
-- Kept in the config so no plugin is required.

local M = {}

--- Return true if the string looks like an inline comment.
--- SEE: https://en.wikipedia.org/wiki/Comparison_of_programming_languages_(syntax)#Inline_comments
--- @param line string
--- @return boolean
local function is_comment_inline(line)
    -- stylua: ignore start
    return not not (
        line:match("^//") or    -- C style
        line:match("^#") or     -- Python, Shell, Perl
        line:match("^%-%-") or  -- Lua, Haskell
        line:match("^%%") or    -- TeX
        line:match("^;")        -- Lisp, Assembly
    )
    -- stylua: ignore end
end

--- Only check beginning of line. Else we would need an actual parser to
--- determine if a line contains a valid block comment start.
--- Returns either a Lua pattern to match the closing block comment or
--- nil if this line doesn't start a block comment.
--- SEE: https://en.wikipedia.org/wiki/Comparison_of_programming_languages_(syntax)#Block_comments
--- @param line string
--- @return string?
local function is_comment_block_start(line)
    if line:match '^/%*' then
        -- C style  /*  */
        return '%*/'
    elseif line:match '^<!%-%-' then
        -- HTML  <!--  -->
        return '%-%->'
    end

    return nil
end

--- Setting an option takes *significantly* more time than reading it.
--- This wrapper only sets the option if the new value differs.
--- @param bufnr integer
--- @param name string
--- @param value any
local function set_buffer_opt(bufnr, name, value)
    local current = vim.bo[bufnr][name]
    if value ~= current then
        vim.bo[bufnr][name] = value
    end
end

--- Guess the indentation of the given buffer.
--- @param bufnr integer
--- @return integer|"tabs"?
function M.guess_from_buffer(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    -- Line loading configuration. Instead of loading all lines at once,
    -- load them lazily in chunks.
    local max_num_lines = 1028
    local chunk_size = 64

    -- How many lines use spaces / tabs
    local space_lines_count = 0
    local tab_lines_count = 0

    -- How many spaces / tabs were used on the previous lines
    local last_space_count = 0
    local last_tab_count = 0

    -- How many spaces are used for indentation
    local spaces = {}
    -- How many spaces are used for indentation relative to previous level
    local relative_spaces = {}

    -- Stack of all indentation levels (absolute) in the current indentation
    -- block. Used to calculate the current relative indentation based on the
    -- difference to the next smaller absolute indentation in the block.
    local spaces_indent_stack = { 0 }

    -- Optional multiline comment termination pattern we're matching against.
    local multiline_pattern = nil

    local filetype = vim.bo[bufnr].filetype

    for chunk_start = 0, (max_num_lines - 1), chunk_size do
        local lines = vim.api.nvim_buf_get_lines(
            bufnr,
            chunk_start,
            math.min(chunk_start + chunk_size, max_num_lines),
            false
        )

        for l_idx, line in ipairs(lines) do
            l_idx = l_idx + chunk_start

            local space_count = 0
            local tab_count = 0

            -- Ignore empty lines. They screw up the last_xxx_count variables
            if not line:find '[^%s]' then
                goto next_line
            end

            -- Check if multiline comment terminates here
            if multiline_pattern then
                if line:match(multiline_pattern) then
                    multiline_pattern = nil
                end
                goto next_line
            end

            -- Special case for Google C++ (#15)
            if
                filetype == 'cpp'
                and (
                    line:match '^%s*public:'
                    or line:match '^%s*private:'
                    or line:match '^%s*protected:'
                )
            then
                goto next_line
            end

            -- Calculate indentation for this line
            for c_idx = 1, math.min(#line, 72) do
                local char = line:sub(c_idx, c_idx)
                if char == ' ' then
                    space_count = space_count + 1
                elseif char == '\t' then
                    tab_count = tab_count + 1
                else
                    -- If the line starts with whitespace followed by a letter
                    -- or number it very likely isn't the start of a comment.
                    if c_idx ~= 1 and char:match '[%w%d]' then
                        break
                    end

                    -- Take the first 10 non whitespace characters of the line.
                    local subline = line:sub(c_idx, c_idx + 9)

                    -- Inline / single line comments
                    if is_comment_inline(subline) then
                        goto next_line
                    end

                    -- Start of a multiline comment. We only consider block
                    -- comments that start at the beginning of a line.
                    multiline_pattern = is_comment_block_start(subline)
                    if multiline_pattern then
                        if line:match(multiline_pattern) then
                            multiline_pattern = nil
                        end

                        goto next_line
                    end

                    -- This line isn't a comment -> exit the loop
                    break
                end
            end

            if
                tab_count ~= 0
                and space_count == 0
                and last_space_count == 0
            then
                -- Is using tabs
                tab_lines_count = tab_lines_count + 1
            end

            if space_count ~= 0 and tab_count == 0 and last_tab_count == 0 then
                -- Is using spaces
                spaces[space_count] = (spaces[space_count] or 0) + 1

                -- Update stack of current indentation levels
                local last_popped_indent = space_count
                while spaces_indent_stack[#spaces_indent_stack] > space_count do
                    last_popped_indent = table.remove(spaces_indent_stack)
                end

                -- Get abs. indentation of previous level in current block
                local prev_indent = 0
                if spaces_indent_stack[#spaces_indent_stack] == space_count then
                    prev_indent = spaces_indent_stack[#spaces_indent_stack - 1]
                else
                    prev_indent = spaces_indent_stack[#spaces_indent_stack]
                    table.insert(spaces_indent_stack, space_count)
                end

                -- Delta is the current relative indentation
                local delta = space_count - prev_indent
                relative_spaces[delta] = (relative_spaces[delta] or 0) + 1
                space_lines_count = space_lines_count + 1

                -- Also account for deindentation
                local deindent_delta = last_popped_indent - space_count
                if deindent_delta ~= 0 then
                    relative_spaces[deindent_delta] = (
                        relative_spaces[deindent_delta] or 0
                    ) + 1
                end
            end

            if space_count == 0 and tab_count == 0 then
                spaces_indent_stack = { 0 }
            end

            last_space_count = space_count
            last_tab_count = tab_count

            -- We have gathered enough evidence to stop early
            if math.abs(space_lines_count - tab_lines_count) >= 128 then
                goto prepare_result
            end

            ::next_line::
        end
    end

    ::prepare_result::

    -- Get most common indentation style
    if tab_lines_count > space_lines_count and tab_lines_count > 0 then
        return 'tabs'
    elseif space_lines_count > 0 then
        local max_score = -1
        local max_spaces = 4

        for n_spaces, relative_count in pairs(relative_spaces) do
            -- Compute score. This is where the main SPACE HEURISTIC lives.
            local log_n_spaces = math.log(n_spaces)
            local score = relative_count / space_lines_count

            for abs_spaces, abs_count in pairs(spaces) do
                -- Check if this indentation would work for other lines
                if (abs_spaces % n_spaces) == 0 then
                    score = score
                        + (abs_count / space_lines_count)
                            * (log_n_spaces / math.log(abs_spaces + 1))
                end
            end

            -- Large penalty for absurdly large indentation
            if n_spaces > 8 then
                score = score - 1
            end

            if score > max_score then
                max_score = score
                max_spaces = n_spaces
            end
        end

        -- There must be a clear majority, else return nil
        if max_score < 0.75 then
            return nil
        end

        return max_spaces
    else
        -- Failed to detect indentation
        return nil
    end
end

--- @param indentation integer|"tabs"?
--- @param bufnr integer
local function set_indentation(indentation, bufnr)
    if indentation == 'tabs' then
        set_buffer_opt(bufnr, 'expandtab', false)
    elseif type(indentation) == 'number' and indentation > 0 then
        set_buffer_opt(bufnr, 'expandtab', true)
        set_buffer_opt(bufnr, 'tabstop', indentation)
        set_buffer_opt(bufnr, 'softtabstop', indentation)
        set_buffer_opt(bufnr, 'shiftwidth', indentation)
    end
end

local filetype_exclude = {
    netrw = true,
    tutor = true,
}

local buftype_exclude = {
    help = true,
    nofile = true,
    terminal = true,
    prompt = true,
}

--- Detect and set the indentation for the given buffer.
--- @param bufnr integer
function M.detect(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    if filetype_exclude[vim.bo[bufnr].filetype] then
        return
    end

    if buftype_exclude[vim.bo[bufnr].buftype] then
        return
    end

    set_indentation(M.guess_from_buffer(bufnr), bufnr)
end

return M
