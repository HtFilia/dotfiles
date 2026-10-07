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
  local state = (vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/dotfiles"
  local expected = {}
  for _, row in ipairs(vim.fn.readfile(state .. "/editor-parsers.tsv")) do
    local name, revision = row:match("^([^\t]+)\t(.+)$")
    expected[name] = revision
  end
  local data = vim.fn.stdpath("data") .. "/site"
  for language in selection:gmatch("%S+") do
    for _, parser in ipairs(assert(parsers[language], "Unknown language: " .. language)) do
      assert(vim.treesitter.language.add(parser), "Parser missing: " .. parser)
      local installed = vim.fn.readfile(data .. "/parser-info/" .. parser .. ".revision")[1]
      assert(expected[parser] and installed == expected[parser], "Parser revision differs: " .. parser)
    end
  end
end)
if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
else
  vim.cmd("qa")
end
