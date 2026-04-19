-- ~/.config/nvim/lua/plugins/colorscheme.lua
-- Override LazyVim's default colorscheme to Tokyo Night (moon variant)
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "moon",             -- "storm" | "moon" | "night" | "day"
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
        sidebars = "dark",
        floats = "dark",
      },
      on_highlights = function(hl, c)
        hl.LineNr = { fg = c.fg_gutter }
        hl.CursorLineNr = { fg = c.orange, bold = true }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-moon",
    },
  },
}
