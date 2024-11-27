require "navigator".setup({
  mason = true,
  lsp = {
    disable_lsp = { 'jdtls' },
    disply_diagnostic_qf = false
  },
  default_mapping = true,
  keymaps = {
    { key = '<Space>rn', func = vim.lsp.buf.rename, desc = 'rename' },
    { key = 'gr', func = require("telescope.builtin").lsp_references, desc = 'async_ref' },
    {
      key = '<Space>ca',
      mode = 'n',
      func = vim.lsp.buf.code_action,
      desc = 'code_action',
    }
  },
})
