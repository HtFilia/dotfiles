local map = vim.keymap.set

map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "Save" })
map("x", "p", '"_dP', { desc = "Paste without yanking" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
