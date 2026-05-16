return {
  { "folke/tokyonight.nvim", opts = { style = "moon" } },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {},
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {},
      automatic_enable = false,
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = { mason = false },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = false,
    opts = {
      ensure_installed = {},
    },
  },
}
