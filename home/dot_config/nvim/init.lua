vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local uv = vim.uv or vim.loop
local lazy_root = vim.fn.stdpath("data") .. "/lazy"
local lazypath = lazy_root .. "/lazy.nvim"
local lazy_commit = "85c7ff3711b730b4030d03144f6db6375044ae82"
local lazyvim_commit = "7c1301b89563198d1b2a295e673f6a7205adc076"

-- Clone a repository at a pinned commit unless it is already present.
local function clone_pinned(url, path, commit)
  if uv.fs_stat(path) then
    return
  end
  local clone = vim.fn.system({ "git", "clone", "--filter=blob:none", url, path })
  if vim.v.shell_error ~= 0 then
    error("Failed to clone " .. url .. ": " .. clone)
  end
  local checkout = vim.fn.system({ "git", "-C", path, "checkout", commit })
  if vim.v.shell_error ~= 0 then
    error("Failed to pin " .. url .. ": " .. checkout)
  end
end

clone_pinned("https://github.com/folke/lazy.nvim.git", lazypath, lazy_commit)
-- Refuse a drifted plugin manager instead of executing an unexpected checkout.
local installed_commit = vim.fn.system({ "git", "-C", lazypath, "rev-parse", "HEAD" }):gsub("%s+$", "")
if installed_commit ~= lazy_commit then
  error("lazy.nvim checkout differs from the pin; review it and restore " .. lazy_commit)
end
-- LazyVim is cloned up front as well, so lazy.nvim sees every plugin it imports
-- in its first install round and installs each at its lazy-lock.json commit.
clone_pinned("https://github.com/LazyVim/LazyVim.git", lazy_root .. "/LazyVim", lazyvim_commit)
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    {
      "LazyVim/LazyVim",
      commit = lazyvim_commit,
      import = "lazyvim.plugins",
    },
    { import = "plugins" },
  },
  defaults = { lazy = false, version = false },
  install = { colorscheme = { "gruvbox-material", "habamax" } },
  checker = { enabled = false },
  change_detection = { notify = false },
})
