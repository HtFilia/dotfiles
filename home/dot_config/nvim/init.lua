vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local uv = vim.uv or vim.loop
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazy_commit = "85c7ff3711b730b4030d03144f6db6375044ae82"
if not uv.fs_stat(lazypath) then
  local clone = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("Failed to clone lazy.nvim: " .. clone)
  end
  local checkout = vim.fn.system({ "git", "-C", lazypath, "checkout", lazy_commit })
  if vim.v.shell_error ~= 0 then
    error("Failed to pin lazy.nvim: " .. checkout)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    {
      "LazyVim/LazyVim",
      commit = "7c1301b89563198d1b2a295e673f6a7205adc076",
      import = "lazyvim.plugins",
    },
    { import = "plugins" },
  },
  defaults = { lazy = false, version = false },
  install = { colorscheme = { "gruvbox-material", "habamax" } },
  checker = { enabled = false },
  change_detection = { notify = false },
})
