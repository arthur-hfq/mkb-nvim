-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  [MARKAB] PLUGIN REGISTRY — BRUTALIST TELEMETRY TOOLKIT        ║
-- ╚══════════════════════════════════════════════════════════════════╝

return {
  -- ── FORMATTER ─────────────────────────────────────────────────
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    config = function()
      require "configs.conform"
    end,
  },

  -- ── LSP ───────────────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- ── DATABASE (vim-dadbod + UI + completion) ───────────────────
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_execute_on_save = 0
      -- Save query results and connections persistently
      vim.g.db_ui_save_location = vim.fn.expand("~/.local/share/db_ui")
      -- Brutalist flat border for DB output
      vim.g.db_ui_win_position = "left"
      vim.g.db_ui_winwidth = 40
    end,
  },

  -- ── CMP (with dadbod source) ─────────────────────────────────
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, { name = "vim-dadbod-completion" })
    end,
  },

  -- ── LIVE SERVER (frontend hot-reload) ─────────────────────────
  {
    "barrett-ruth/live-server.nvim",
    cmd = { "LiveServerStart", "LiveServerStop" },
    config = function() end,
  },

  -- ── NEOTEST (test runner framework) ───────────────────────────
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- Adapters for languages
      "nvim-neotest/neotest-python",
      "haydenmeade/neotest-jest",
    },
    cmd = { "Neotest" },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            dap = { justMyCode = false },
            runner = "pytest",
          }),
          require("neotest-jest")({
            jestCommand = "npx jest",
          }),
        },
        -- Brutalist flat output panel
        output = { open_on_run = true },
        status = { virtual_text = true },
        icons = {
          passed = "[PASS]",
          failed = "[FAIL]",
          running = "[RUN.]",
          skipped = "[SKIP]",
          unknown = "[????]",
        },
      })
    end,
  },

  -- ── SMOOTH SCROLLING (CRT EFFECT) ─────────────────────────────
  {
    "karb94/neoscroll.nvim",
    event = "WinScrolled",
    config = function()
      require("neoscroll").setup({
        -- Smooth, linear scroll (looks like an old teletype rolling)
        easing_function = "linear",
        hide_cursor = true,
        stop_eof = true,
        respect_scrolloff = false,
        cursor_scrolls_alone = true,
      })
    end,
  },
}
