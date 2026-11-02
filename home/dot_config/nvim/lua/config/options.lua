vim.opt.relativenumber = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.confirm = true

-- Machine-specific options: ~/.config/nvim/lua/config/local.lua, never managed.
pcall(require, "config.local")
