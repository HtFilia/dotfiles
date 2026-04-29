-- Bootstrap lazy.nvim (requires Neovim >= 0.8, no LazyVim framework)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- ── Colorscheme ──────────────────────────────────────────────────────────
  {
    "folke/tokyonight.nvim",
    lazy = false, priority = 1000,
    opts = {
      style = "moon",
      transparent = false,
      terminal_colors = true,
      styles = { comments = { italic = true }, keywords = { italic = true } },
      on_highlights = function(hl, c)
        hl.LineNr       = { fg = c.fg_gutter }
        hl.CursorLineNr = { fg = c.orange, bold = true }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight-moon")
    end,
  },

  -- ── Status line ──────────────────────────────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    opts = { options = { theme = "tokyonight", globalstatus = true } },
  },

  -- ── Fuzzy finder ─────────────────────────────────────────────────────────
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>",  desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",   desc = "Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",     desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",   desc = "Help" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>",    desc = "Recent files" },
    },
  },

  -- ── Syntax highlighting ───────────────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "python", "go", "rust", "bash",
          "json", "yaml", "toml", "markdown", "markdown_inline",
        },
        highlight = { enable = true },
        indent    = { enable = true },
      })
    end,
  },

  -- ── LSP (no Mason — binaries come from apt or offline assets) ────────────
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lsp = require("lspconfig")
      local caps = vim.lsp.protocol.make_client_capabilities()

      -- Keymaps attached when an LSP server connects
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local map = function(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = desc })
          end
          map("gd",        vim.lsp.buf.definition,      "Go to definition")
          map("gD",        vim.lsp.buf.declaration,     "Go to declaration")
          map("gr",        vim.lsp.buf.references,      "References")
          map("gi",        vim.lsp.buf.implementation,  "Implementation")
          map("K",         vim.lsp.buf.hover,           "Hover docs")
          map("<leader>rn",vim.lsp.buf.rename,          "Rename")
          map("<leader>ca",vim.lsp.buf.code_action,     "Code action")
          map("<leader>f", vim.lsp.buf.format,          "Format")
        end,
      })

      -- Servers installed via apt (restricted) or rustup/go
      lsp.rust_analyzer.setup({ capabilities = caps })
      lsp.gopls.setup({ capabilities = caps })
      lsp.pylsp.setup({ capabilities = caps })
      -- bashls needs npm — comment out if not available
      -- lsp.bashls.setup({ capabilities = caps })
    end,
  },

  -- ── Completion ───────────────────────────────────────────────────────────
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
          ["<C-f>"]     = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = false }),
          ["<Tab>"]     = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- ── Git ──────────────────────────────────────────────────────────────────
  { "lewis6991/gitsigns.nvim", opts = {} },

  -- ── Editor niceties ──────────────────────────────────────────────────────
  { "echasnovski/mini.pairs",   version = false, opts = {} },
  { "echasnovski/mini.surround",version = false, opts = {} },
  { "numToStr/Comment.nvim",    opts = {} },
  { "folke/which-key.nvim",     opts = {} },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = { indent = { char = "│" } },
  },

}, {
  install  = { colorscheme = { "tokyonight", "habamax" } },
  checker  = { enabled = false },
  performance = {
    rtp = { disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" } },
  },
})
