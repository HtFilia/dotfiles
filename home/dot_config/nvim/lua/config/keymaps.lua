-- ~/.config/nvim/lua/config/keymaps.lua
-- Additional keymaps (loaded alongside LazyVim's defaults)

local map = vim.keymap.set

-- Save with Ctrl-S in all modes
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "Save" })

-- Better paste (don't replace clipboard when pasting over selection)
map("x", "p", '"_dP', { desc = "Paste without yanking" })

-- Stay in indent mode
map("v", "<", "<gv", { desc = "Decrease indent" })
map("v", ">", ">gv", { desc = "Increase indent" })

-- Move lines up/down
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep cursor centered
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Quick buffer navigation
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
