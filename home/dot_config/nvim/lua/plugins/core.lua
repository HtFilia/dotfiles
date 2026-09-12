return {
  {
    "sainnhe/gruvbox-material",
    commit = "11d779b26a9ab2b3db8c22c6ac9fb6e8ed4fea79",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      vim.g.gruvbox_material_background = "medium"
      vim.g.gruvbox_material_foreground = "material"
      vim.g.gruvbox_material_better_performance = 1
      vim.cmd.colorscheme("gruvbox-material")
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = {}
    end,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = {}
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      local servers = {
        lua_ls = "lua-language-server",
        basedpyright = "basedpyright-langserver",
        ruff = "ruff",
        gopls = "gopls",
        rust_analyzer = "rust-analyzer",
        ts_ls = "typescript-language-server",
        bashls = "bash-language-server",
      }
      for server, binary in pairs(servers) do
        opts.servers[server] = vim.tbl_deep_extend("force", opts.servers[server] or {}, {
          mason = false,
          enabled = vim.fn.executable(binary) == 1,
        })
      end
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = false,
    opts = function(_, opts)
      -- Replace LazyVim's list; merging an empty table keeps its defaults.
      opts.ensure_installed = {}
    end,
  },
}
