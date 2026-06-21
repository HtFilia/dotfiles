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
