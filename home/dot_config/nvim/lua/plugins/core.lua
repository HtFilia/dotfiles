return {
  -- Dusk: base16 colours from lua/dusk_palette.lua, generated from the
  -- Alpenglow & Dusk palette so the editor matches Kitty and tmux.
  {
    "nvim-mini/mini.base16",
    commit = "e1bb1cb70aa33dc7038cd79bb597325e51597fa1",
    lazy = false,
    priority = 1000,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        vim.o.background = "dark"
        require("mini.base16").setup({ palette = require("dusk_palette"), use_cterm = true })
        vim.g.colors_name = "dusk"
      end,
    },
  },
  -- Language servers come from uv, rustup, npm and the system packages, at
  -- the versions pinned in the dotfiles (.chezmoidata/packages.yaml), so
  -- Mason is not loaded.
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      local servers = {
        lua_ls = "lua-language-server",
        pyrefly = "pyrefly",
        ruff = "ruff",
        gopls = "gopls",
        rust_analyzer = "rust-analyzer",
        ts_ls = "typescript-language-server",
        bashls = "bash-language-server",
        clangd = "clangd",
      }
      for server, binary in pairs(servers) do
        -- A server starts only on a machine where its binary is installed.
        opts.servers[server] = vim.tbl_deep_extend("force", opts.servers[server] or {}, {
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
