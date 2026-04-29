local map = vim.keymap.set

-- Save
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "Save" })

-- Better paste (don't replace clipboard when pasting over selection)
map("x", "p", '"_dP', { desc = "Paste without yanking" })

-- Stay in indent mode
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Move lines
map("n", "<A-j>", ":m .+1<CR>==")
map("n", "<A-k>", ":m .-2<CR>==")
map("v", "<A-j>", ":m '>+1<CR>gv=gv")
map("v", "<A-k>", ":m '<-2<CR>gv=gv")

-- Keep cursor centered on scroll / search
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n",     "nzzzv")
map("n", "N",     "Nzzzv")

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Buffer navigation
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>",     { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Diagnostics
map("n", "[d", vim.diagnostic.goto_prev,  { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next,  { desc = "Next diagnostic" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
