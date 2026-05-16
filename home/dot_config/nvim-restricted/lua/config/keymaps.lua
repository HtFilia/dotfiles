local map = vim.keymap.set

map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "Save" })
map("x", "p", '"_dP', { desc = "Paste without yanking" })
map("v", "<", "<gv")
map("v", ">", ">gv")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
