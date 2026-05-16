vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local map = function(keys, fn, desc)
      vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = desc })
    end
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("gr", vim.lsp.buf.references, "References")
    map("gi", vim.lsp.buf.implementation, "Implementation")
    map("K", vim.lsp.buf.hover, "Hover docs")
    map("<leader>rn", vim.lsp.buf.rename, "Rename")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>f", vim.lsp.buf.format, "Format")
  end,
})

local function root_dir(markers)
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    path = vim.loop.cwd()
  end
  local dir = vim.fs and vim.fs.dirname(path) or vim.fn.fnamemodify(path, ":p:h")
  if vim.fs and vim.fs.find then
    local found = vim.fs.find(markers, { upward = true, path = dir })[1]
    if found then
      return vim.fs.dirname(found)
    end
  end
  return dir
end

local servers = {
  rust = { name = "rust_analyzer", cmd = { "rust-analyzer" }, markers = { "Cargo.toml", ".git" } },
  go = { name = "gopls", cmd = { "gopls" }, markers = { "go.mod", ".git" } },
  python = { name = "pylsp", cmd = { "pylsp" }, markers = { "pyproject.toml", "setup.py", ".git" } },
}

vim.api.nvim_create_autocmd("FileType", {
  pattern = vim.tbl_keys(servers),
  callback = function()
    local server = servers[vim.bo.filetype]
    if server and vim.fn.executable(server.cmd[1]) == 1 then
      vim.lsp.start({
        name = server.name,
        cmd = server.cmd,
        root_dir = root_dir(server.markers),
      })
    end
  end,
})
