-- ~/.config/nvim/init.lua
-- LazyVim bootstrap
-- https://www.lazyvim.org/

-- Set leader keys early (before lazy.nvim)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.lazy")
