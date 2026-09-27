-- Read-only: load installed parsers without starting the plugin manager.
local parsers = {
  lua = { "lua", "luadoc" }, python = { "python" },
  go = { "go", "gomod", "gowork" }, rust = { "rust" },
  node = { "javascript", "typescript", "tsx", "json" }, shell = { "bash" },
}
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/site")
local ok, err = pcall(function()
  local selection = vim.env.DOTFILES_EDITOR_LANGUAGES or ""
  assert(selection:match("%S"), "Empty editor selection")
  for language in selection:gmatch("%S+") do
    for _, parser in ipairs(assert(parsers[language], "Unknown language: " .. language)) do
      assert(vim.treesitter.language.add(parser), "Parser missing: " .. parser)
    end
  end
end)
if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
else
  vim.cmd("qa")
end
