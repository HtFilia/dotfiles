-- Explicit parser provisioning only; native language tools are installed first.
local targets = {
  lua = { tools = { "lua-language-server", "stylua" }, parsers = { "lua", "luadoc" } },
  python = { tools = { "basedpyright", "ruff" }, parsers = { "python" } },
  go = { tools = { "gopls", "goimports" }, parsers = { "go", "gomod", "gowork" } },
  rust = { tools = { "rust-analyzer" }, parsers = { "rust" } },
  node = { tools = { "typescript-language-server", "prettier" }, parsers = { "javascript", "typescript", "tsx", "json" } },
  shell = { tools = { "bash-language-server", "shfmt", "shellcheck" }, parsers = { "bash" } },
}
local function provision()
  require("lazy").load({ plugins = { "nvim-treesitter" } })
  local parsers = {}
  for language in vim.env.DOTFILES_EDITOR_LANGUAGES:gmatch("%S+") do
    local target = assert(targets[language], "Unknown language")
    vim.list_extend(parsers, target.parsers)
  end
  local ts = require("nvim-treesitter")
  ts.install(parsers):wait(600000)
  ts.update(parsers):wait(600000)
  local installed = ts.get_installed()
  for _, parser in ipairs(parsers) do
    assert(vim.tbl_contains(installed, parser), "Parser missing: " .. parser)
  end
  local state = (vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/dotfiles"
  vim.fn.mkdir(state, "p")
  local tools = vim.fn.readfile(state .. "/editor-tools.pending")
  for _, tool in ipairs(tools) do
    assert(vim.fn.executable(tool) == 1, "Missing selected editor tool: " .. tool)
  end
  -- Record exact parser revisions from the pinned plugin definitions.
  local revisions = {}
  local definitions = require("nvim-treesitter.parsers")
  for _, parser in ipairs(parsers) do
    local info = assert(definitions[parser].install_info)
    local revision = vim.fn.readfile(vim.fn.stdpath("data") .. "/site/parser-info/" .. parser .. ".revision")
    assert(revision[1] == info.revision, "Parser revision differs from pin: " .. parser)
    revisions[#revisions + 1] = parser .. "\t" .. tostring(info.revision)
  end
  vim.fn.writefile(revisions, state .. "/editor-parsers.tsv")
  vim.fn.writefile(tools, state .. "/editor-tools")
  vim.fn.delete(state .. "/editor-tools.pending")
  vim.fn.writefile({ vim.env.DOTFILES_EDITOR_LANGUAGES }, state .. "/editor-languages")
  print("Editor tools and parsers installed. Restart Neovim to enable servers.")
end
local ok, err = pcall(provision)
if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
else
  vim.cmd("qa")
end
