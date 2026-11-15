local map = vim.keymap.set

map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "Save" })
map("x", "p", '"_dP', { desc = "Paste without yanking" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- AZERTY: [ and ] need AltGr, ( and ) are unshifted. They stand in for the
-- "previous / next" prefixes ((b, )d, (q…), at the cost of the sentence motions.
for _, pair in ipairs({ { "(", "[" }, { ")", "]" } }) do
  map({ "n", "x", "o" }, pair[1], pair[2], { remap = true, desc = "Same as " .. pair[2] })
end
