local global_opts = {
  -- Visual
  background     = "dark";
  laststatus     = 2;
  number         = true;
  relativenumber = true,
  termguicolors  = true;
  updatetime     = 1000,

  -- Usability
  mouse = "a";
  autoindent = true;
  expandtab = true;
  ts = 2;
  sts = 0;
  sw = 0;

  -- Workflow
  backupdir = vim.fn.expand("$HOME") .. "/.config/nvim/backups//";
  directory = vim.fn.expand("$HOME") .. "/.config/nvim/backups//";
}

local vim_g_opts = {
  do_filetype_lua = 1,
  jdtls_dap_loaded = false
}

vim.cmd([[autocmd Filetype NvimTree set cursorline]])
vim.cmd([[autocmd VimEnter * highlight Comment cterm=italic gui=italic]])

for k, v in pairs(global_opts) do
  vim.o[k] = v
end

for k, v in pairs(vim_g_opts) do
  vim.g[k] = v
end

local M = {};

local function sleep(n)
  os.execute("sleep " .. tonumber(n))
end

function M.dap_load_and_continue()
  if not vim.g.jdtls_dap_loaded and vim.bo.filetype == "java" then
    require('jdtls.dap').setup_dap_main_class_configs()
    sleep(1)
    vim.g.jdtls_dap_loaded = true
  end

  require('dap').continue()
end

function M.dap_terminate()
  require('dap').terminate()
  require('dapui').close()
end

function M.telescope(func)
  local opt = {}
  require("telescope.builtin")[func](opt)
end

function M.telescope_ext(func)
  local opt = {}
  require("telescope").extensions[func][func](opt)
end

vim.cmd([[nnoremap <Leader>tt :lua require('options').telescope('builtin')<CR>]])
vim.cmd([[nnoremap <Leader>tT :lua require('options').telescope('current_buffer_tags')<CR>]])
vim.cmd([[nnoremap <Leader>tf :lua require('options').telescope('current_buffer_fuzzy_find')<CR>]])
vim.cmd([[nnoremap <Leader>td :lua require('options').telescope('diagnostics')<CR>]])
vim.cmd([[nnoremap <Leader>tw :lua require('options').telescope_ext('project')<CR>]])
vim.cmd([[nnoremap <Leader>te :lua require('options').telescope('find_files')<CR>]])
vim.cmd([[nnoremap <Leader>tg :lua require('options').telescope('git_files')<CR>]])
vim.cmd([[nnoremap <Leader>tb :lua require('options').telescope('buffers')<CR>]])
vim.cmd([[nnoremap <Leader>ts :lua require('options').telescope('treesitter')<CR>]])

vim.cmd([[nnoremap <Leader>T :lua require('options').tandem_compat()<CR>]])
vim.cmd([[nnoremap <Leader>R :lua require('options').tandem_compat_remove()<CR>]])
vim.cmd([[nnoremap <Leader>q :lua vim.diagnostic.setqflist()<CR>]])

vim.cmd([[nnoremap <Leader>lr :lua require('jdtls').update_project_config()<CR>]])
vim.cmd([[nnoremap <Leader>lc :lua require('jdtls').compile()<CR>]])

vim.cmd([[nnoremap <Leader>gg :LazyGit<CR>]])
vim.cmd([[nnoremap <Leader>gr :Gitsigns reset_hunk<CR>]])
vim.cmd([[nnoremap <Leader>gb :Gitsigns toggle_current_line_blame<CR>]])
vim.cmd([[nnoremap <Leader>ga :Gitsigns stage_hunk<CR>]])
vim.cmd([[nnoremap <Leader>gd :Gitsigns undo_stage_hunk<CR>]])

vim.cmd([[nnoremap <Leader>dc :lua require('jdtls').test_class()<CR>]])
vim.cmd([[nnoremap <Leader>dm :lua require('jdtls').test_nearest_method()<CR>]])
vim.cmd([[nnoremap <Leader>dt :lua require('options').dap_terminate()<CR>]])
vim.cmd([[nnoremap <Leader>c :lua require('options').dap_load_and_continue()<CR>]])
vim.cmd([[nnoremap <Leader>db :lua require('dap').toggle_breakpoint()<CR>]])
vim.cmd([[nnoremap <Leader>da :lua require('dap').step_over()<CR>]])
vim.cmd([[nnoremap <Leader>ds :lua require('dap').step_into()<CR>]])
vim.cmd([[nnoremap <Leader>dz :lua require('dap').run_to_cursor()<CR>]])

vim.cmd([[nnoremap <Leader>[ :BufferPrev<CR>]])
vim.cmd([[nnoremap <Leader>] :BufferNext<CR>]])
vim.cmd([[nnoremap <Leader>{ :BufferMovePrev<CR>]])
vim.cmd([[nnoremap <Leader>} :BufferMoveNext<CR>]])

vim.cmd([[nnoremap <Leader>o :lua require('jdtls').organize_imports()<CR>]])

vim.cmd([[nnoremap <Leader>bp :BufferPick<CR>]])
vim.cmd([[nnoremap <Leader>bc :BufferClose<CR>]])

vim.cmd([[nnoremap <Leader>n :set relativenumber!<CR>]])
vim.cmd([[nnoremap <Leader>f :NvimTreeFocus<CR>]])
vim.cmd([[nnoremap <Leader>v :NvimTreeToggle<CR>]])

vim.cmd([[nnoremap K :lua vim.lsp.buf.hover()<CR>]])
vim.cmd([[nnoremap gd :lua vim.lsp.buf.definition()<CR>]])
vim.cmd([[nnoremap gr :lua require('options').telescope('lsp_references')<CR>]])

vim.cmd([[nnoremap [d :lua vim.diagnostic.goto_prev()<CR>]])
vim.cmd([[nnoremap ]d :lua vim.diagnostic.goto_next()<CR>]])
vim.cmd([[nnoremap [g :Gitsigns prev_hunk<CR>]])
vim.cmd([[nnoremap ]g :Gitsigns next_hunk<CR>]])

vim.cmd([[tnoremap <C-esc> <C-\><C-n>]])

return M
