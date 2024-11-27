local cmp = require "cmp"
local check_back_space = function()
  local col = vim.fn.col "." - 1
  return col == 0 or vim.fn.getline("."):sub(col, col):match "%s" ~= nil
end
local function t(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end
cmp.setup({
  snippet = {
    expand = function(args)
      require "luasnip".lsp_expand(args.body)
    end
  },
  sources = cmp.config.sources({
    {name = "nvim_lsp"},
    {name = "nvim_lsp_signature_help"},
    {name = "luasnip"},
    {name = "nvim_lua"},
    {name = "buffer"},
    {name = "path"},
  }),
  formatting = {
    format = require "lspkind".cmp_format({with_text = true, menu = ({
      buffer = " ﬘",
      nvim_lsp = " ",
      luasnip = " 🐍",
      treesitter = " ",
      nvim_lua = " ",
      spell =  " 暈",
    })})
  },
  mapping = {
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.close(),
    ["<tab>"] = cmp.mapping(function(fallback)
      if vim.fn.pumvisible() == 1 then
        vim.fn.feedkeys(t("<C-n>"), "n")
        -- elseif require"snippy".can_expand_or_advance()  then
        --   vim.fn.feedkeys(t("<Plug>(snippy-expand-or-next)"), "")
      elseif require "luasnip".expand_or_jumpable() then
        vim.fn.feedkeys(t("<Plug>luasnip-expand-or-jump"), "")
      elseif check_back_space() then
        vim.fn.feedkeys(t("<tab>"), "n")
      else
        fallback()
      end
    end, {"i", "s"}),
    ["<S-tab>"] = cmp.mapping(function(fallback)
      if vim.fn.pumvisible() == 1 then
        vim.fn.feedkeys(t("<C-p>"), "n")
        -- elseif require"snippy".can_jump(-1) then
        --   vim.fn.feedkeys(t("<Plug>(snippy-previous)"), "")
      elseif require "luasnip".jumpable(-1) then
        vim.fn.feedkeys(t("<Plug>luasnip-jump-prev"), "")
      else
        fallback()
      end
    end, {"i", "s"}),
  },
})
cmp.setup.cmdline("/", {
  completion = { autocomplete = false },
  sources = {
    { name = "buffer", opts = { keyword_pattern = [=[[^[:blank:]].*]=] } }
  }
})
