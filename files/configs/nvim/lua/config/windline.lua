local windline = require('windline')
local helper = require('windline.helpers')
local sep = helper.separators
local vim_components = require('windline.components.vim')

local b_components = require('windline.components.basic')
local state = _G.WindLine.state

local lsp_comps = require('windline.components.lsp')
local git_comps = require('windline.components.git')

local hl_list = {
    Black = { 'white', 'black' },
    White = { 'black', 'white' },
    Inactive = { 'InactiveFg', 'InactiveBg' },
    Active = { 'ActiveFg', 'ActiveBg' },
}
local basic = {}

basic.divider = { b_components.divider, '' }
basic.file_name_inactive = { b_components.full_file_name, hl_list.Inactive }
basic.line_col_inactive = { b_components.line_col, hl_list.Inactive }
basic.progress_inactive = { b_components.progress, hl_list.Inactive }

basic.vi_mode = {
    name = 'vi_mode',
    hl_colors = {
        Normal = { 'black', 'red', 'bold' },
        Insert = { 'black', 'green', 'bold' },
        Visual = { 'black', 'yellow', 'bold' },
        Replace = { 'black', 'blue_light', 'bold' },
        Command = { 'black', 'magenta', 'bold' },
        NormalBefore = { 'red', 'black' },
        InsertBefore = { 'green', 'black' },
        VisualBefore = { 'yellow', 'black' },
        ReplaceBefore = { 'blue_light', 'black' },
        CommandBefore = { 'magenta', 'black' },
        NormalAfter = { 'white', 'red' },
        InsertAfter = { 'white', 'green' },
        VisualAfter = { 'white', 'yellow' },
        ReplaceAfter = { 'white', 'blue_light' },
        CommandAfter = { 'white', 'magenta' },
    },
    text = function()
        return {
            { sep.left_rounded, state.mode[2] .. 'Before' },
            { state.mode[1] .. ' ', state.mode[2] },
            { sep.left_rounded, state.mode[2] .. 'After' },
        }
    end,
}

basic.lsp_diagnos = {
    name = 'diagnostic',
    hl_colors = {
        red = { 'red', 'black' },
        yellow = { 'yellow', 'black' },
        blue = { 'blue', 'black' },
    },
    width = 90,
    text = function(bufnr)
        if lsp_comps.check_lsp(bufnr) then
            return {
                { lsp_comps.lsp_error({ format = '  %s' }), 'red' },
                { lsp_comps.lsp_warning({ format = '  %s' }), 'yellow' },
                { lsp_comps.lsp_hint({ format = '  %s' }), 'blue' },
            }
        end
        return ''
    end,
}

basic.file = {
    name = 'file',
    hl_colors = {
        default = hl_list.White,
    },
    text = function()
        return {
            {b_components.cache_file_icon({ default = '' }), 'default'},
            { ' ', 'default' },
            { b_components.cache_file_name('[No Name]', 'unique') },
            { b_components.file_modified(' ')},
            { b_components.cache_file_size()},
        }
    end,
}

basic.right = {
    hl_colors = {
        sep_before = { 'black_light', 'black' },
        sep_after = { 'black_light', 'black' },
        text = { 'white', 'black_light' },
    },
    text = function()
        return {
            { sep.left_rounded, 'sep_before' },
            { 'l/n', 'text' },
            { b_components.line_col_lua },
            { '' },
            { b_components.progress_lua },
            { sep.right_rounded, 'sep_after' },
        }
    end,
}
basic.git = {
    name = 'git',
    width = 90,
    hl_colors = {
        green = { 'green', 'black' },
        red = { 'red', 'black' },
        blue = { 'blue', 'black' },
    },
    text = function(bufnr)
        if git_comps.is_git(bufnr) then
            return {
                { ' ' },
                { git_comps.diff_added({ format = ' %s' }), 'green' },
                { git_comps.diff_removed({ format = '  %s' }), 'red' },
                { git_comps.diff_changed({ format = ' 柳%s' }), 'blue' },
            }
        end
        return ''
    end,
}

local fmt = string.format

local options = {
  c_langs = {'arduino', 'c', 'cpp', 'cuda', 'go', 'javascript', 'ld', 'php'},
  max_lines = 5000,
}
local function search(pattern)
    return vim.fn.search(pattern, 'nw')
end

local function get_trailing()
    local num = search([[\s$]])
    if num > 0 then
        return fmt('  %d', search([[\s$]]))
    else
        return ''
    end
end

local function get_mix_indent()
    local tst = [[(^\t* +\t\s*\S)]]
    local tls = fmt([[(^\t+ {%d,}\S)]], vim.bo.tabstop)
    local pattern = fmt([[\v%s|%s]], tst, tls)
    local num = search(pattern)
    if num > 0 then
        return fmt('  %d', search(pattern))
    else
        return ''
    end
end

local function get_mix_indent_file()
    local head_spc = [[\v(^ +)]]
    if vim.tbl_contains(options.c_langs, vim.bo.filetype) then
        head_spc = [[\v(^ +\*@!)]]
    end
    local indent_tabs = vim.fn.search([[\v(^\t+)]], 'nw')
    local indent_spc = vim.fn.search(head_spc, 'nw')
    if indent_tabs == 0 or indent_spc == 0 then
        return ''
    end
    return fmt('  %d,%d', indent_spc, indent_tabs)
end


local function get_conflict()
    local annotation = [[\%([0-9A-Za-z_.:]\+\)\?]]
    local raw_pattern = [[^\%%(\%%(<\{7} %s\)\|\%%(=\{7\}\)\|\%%(>\{7\} %s\)\)$]]
    if vim.bo.filetype == 'rst' then
        raw_pattern = [[^\%%(\%%(<\{7} %s\)\|\%%(>\{7\} %s\)\)$]]
    end
    local pattern = fmt(raw_pattern, annotation, annotation)
    local num = search(pattern)
    if num > 0 then
        return fmt('  %d', num)
    else
        return ''
    end
end

basic.whitespace = {
    name = 'whitespace',
    width = 200,
    hl_colors = {
        default = { 'red', 'black' },
    },
    text = function()
        return {
            { get_trailing(), 'default' },
            { get_mix_indent(), 'default' },
            { get_mix_indent_file(), 'default' },
            { get_conflict(), 'default' },
            { ' ' },
        }
    end,
}

local default = {
    filetypes = { 'default' },
    active = {
        { ' ', hl_list.Black },
        basic.vi_mode,
        basic.file,
        { vim_components.search_count(), { 'red', 'white' } },
        { sep.right_rounded, hl_list.Black },
        basic.lsp_diagnos,
        basic.git,
        basic.divider,
        basic.whitespace,
        { git_comps.git_branch({ icon = '  ' }), { 'green', 'black' }, 90 },
        { ' ', hl_list.Black },
        basic.right,
        { ' ', hl_list.Black },
    },
    inactive = {
        basic.file_name_inactive,
        basic.divider,
        basic.divider,
        basic.line_col_inactive,
        { '', hl_list.Inactive },
        basic.progress_inactive,
    },
}

local quickfix = {
    filetypes = { 'qf', 'Trouble' },
    active = {
        { '🚦 Quickfix ', { 'white', 'black' } },
        { helper.separators.slant_right, { 'black', 'black_light' } },
        {
            function()
                return vim.fn.getqflist({ title = 0 }).title
            end,
            { 'cyan', 'black_light' },
        },
        { ' Total : %L ', { 'cyan', 'black_light' } },
        { helper.separators.slant_right, { 'black_light', 'InactiveBg' } },
        { ' ', { 'InactiveFg', 'InactiveBg' } },
        basic.divider,
        { helper.separators.slant_right, { 'InactiveBg', 'black' } },
        { '🧛 ', { 'white', 'black' } },
    },
    always_active = true,
    show_last_status = true
}

local explorer = {
    filetypes = { 'fern', 'NvimTree', 'lir' },
    active = {
        { '  ', { 'white', 'black_light' } },
        { helper.separators.slant_right, { 'black_light', 'NormalBg' } },
        { b_components.divider, '' },
        { b_components.file_name(''), { 'NormalFg', 'NormalBg' } },
    },
    always_active = true,
    show_last_status = true
}

windline.setup({
    colors_name = function(colors)
        -- ADD MORE COLOR HERE ----
        return colors
    end,
    statuslines = {
        default,
        explorer,
        quickfix,
    },
})
