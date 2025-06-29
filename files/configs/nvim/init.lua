local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("aliases")
require("options")

return require("lazy").setup({
  --------------
  -- Look & Feel
  --------------
  -- Barbar (file tabs)
  {
    "romgrk/barbar.nvim",
    dependencies = "kyazdani42/nvim-web-devicons",
  },

  -- Nord (color scheme)
  {
    "shaunsingh/nord.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require('nord').set()
    end,
  },

  -- Dressing.nvim (make selection dialogs nicer)
  {
    "stevearc/dressing.nvim"
  },

  -- NvimTree (file browser)
  {
    "kyazdani42/nvim-tree.lua",
    lazy = true,
    cmd = {
      "NvimTreeClipboard",
      "NvimTreeClose",
      "NvimTreeCollapse",
      "NvimTreeCollapseKeepBuffers",
      "NvimTreeFindFile",
      "NvimTreeFindFileToggle",
      "NvimTreeFocus",
      "NvimTreeOpen",
      "NvimTreeRefresh",
      "NvimTreeResize",
      "NvimTreeToggle"
    },
    dependencies = "kyazdani42/nvim-web-devicons",
    config = function()
      require "config.nvim-tree"
    end
  },

  -- Lualine (status bar)
  {
    "nvim-lualine/lualine.nvim",
		config = function()
		  require "config.lualine"
		end
  },
  
  -------------
  -- Navigation
  -------------
  -- Telescope-Project (project list in Telescope)
  {
    "nvim-telescope/telescope-project.nvim",
    lazy = true,
    cmd = "Telescope project",
    config = function()
      require("telescope").load_extension("project")
    end
  },

  -- Telescope (general purpose search tool)
  {
    "nvim-telescope/telescope.nvim",
    lazy = true,
    module = {
      "telescope"
    },
    dependencies = {
      {
        "nvim-lua/plenary.nvim",
        module = {
          "plenary.strings"
        }
      }
    },
    config = function()
      require "telescope".setup()
    end
  },
  --------------------------
  -- Development/LSP Engines
  --------------------------
  -- Mason (LSP installer)
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup()
    end
  },

  {
    "williamboman/mason-lspconfig.nvim",
  },

  -- Navigator (Tools for navigating code)
  {
    "ray-x/navigator.lua",
    dependencies = {
      "neovim/nvim-lspconfig",
      { "ray-x/guihua.lua", build = "cd lua/fzy && make" },
      {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
          require "config.treesitter"
        end
      },
    },
    config = function()
      require "config.navigator"
    end
  },

  -- Nvim-bqf (Quickfix previews)
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf"
  },

  -- LazyGit (Git frontend GUI)
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = { "LazyGit" } 
  },

  -- Nvim-JDTLS (Java LSP Extensions)
  {
    "mfussenegger/nvim-jdtls"
  },

  -- Nvim-DAP (Debugger)
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap, dapui = require('dap'), require('dapui')
      require("dapui").setup()
      vim.fn.sign_define('DapBreakpoint', { text = '🔴', texthl = '', linehl = '', numhl = '' })
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end
  },

  -- Nvim-DAP-UI (UI extensions for DAP)
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio"
    },
    config = function()
      local dap, dapui = require('dap'), require('dapui')
      require("dapui").setup()
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end
  },

  -- Nvim-CMP (Autocomplete)
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      { "onsails/lspkind-nvim" },
    },
    config = function()
      require "config.cmp"
    end
  },

  -- LSP-Signature (Shows function signatures in CMP)
  -- seems broken in nvim8
  -- {
  --   "ray-x/lsp_signature.nvim",
  --   config = function()
  --     require "lsp_signature".setup({
  --       toggle_key = '<M-k>',
  --       select_signature_key = '<M-n>'
  --     })
  --   end
  -- },
  -- LuaSnip (Snippets for CMP)
  {
    "L3MON4D3/LuaSnip"
  },

  {
    "liuchengxu/vista.vim",
    lazy = true,
    cmd = {
      "Vista"
    },
  },

  {
    "khaveesh/vim-fish-syntax"
  },

  -- Indent Blankline (Tab Indicators)
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {}
  }
})
