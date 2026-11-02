-- Explicit Mason and Treesitter provisioning with completion/error reporting.
local targets = {
  lua = { tools = { "lua-language-server", "stylua" }, parsers = { "lua", "luadoc" } },
  python = { tools = { "basedpyright", "ruff" }, parsers = { "python" } },
  go = { tools = { "gopls", "goimports" }, parsers = { "go", "gomod", "gowork" } },
  rust = { tools = { "rust-analyzer" }, parsers = { "rust" } },
  node = { tools = { "typescript-language-server" }, parsers = { "javascript", "typescript", "tsx", "json" } },
  shell = { tools = { "bash-language-server", "shfmt", "shellcheck" }, parsers = { "bash" } },
}
local function provision()
  require("lazy").load({ plugins = { "mason.nvim", "nvim-treesitter" } })
  local registry = require("mason-registry")
  local refreshed, refresh_error
  registry.refresh(function(ok, err)
    refreshed, refresh_error = ok, err
  end)
  assert(vim.wait(120000, function() return refreshed ~= nil end, 100), "Mason registry refresh timed out")
  assert(refreshed, vim.inspect(refresh_error))
  local parsers, packages, failures = {}, {}, {}
  for language in vim.env.DOTFILES_EDITOR_LANGUAGES:gmatch("%S+") do
    local target = assert(targets[language], "Unknown language")
    vim.list_extend(parsers, target.parsers)
    for _, name in ipairs(target.tools) do
      local package = registry.get_package(name)
      packages[#packages + 1] = package
      if not package:is_installed() then
        package:install({}, function(success, install_error)
          if not success then failures[package.name] = tostring(install_error or "unknown Mason error") end
        end)
      end
    end
  end
  assert(vim.wait(600000, function()
    for _, package in ipairs(packages) do
      if package:is_installing() then return false end
    end
    return true
  end, 100), "Mason installation timed out")
  for _, package in ipairs(packages) do
    if not package:is_installed() then
      local detail = failures[package.name] or ("see " .. vim.fn.stdpath("state") .. "/mason.log")
      error("Failed package: " .. package.name .. " (" .. detail .. ")")
    end
  end
  local ts = require("nvim-treesitter")
  ts.install(parsers):wait(600000)
  local installed = ts.get_installed()
  for _, parser in ipairs(parsers) do
    assert(vim.tbl_contains(installed, parser), "Parser missing: " .. parser)
  end
  print("Editor tools and parsers installed. Restart Neovim to enable servers.")
end
local ok, err = pcall(provision)
if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
else
  vim.cmd("qa")
end
