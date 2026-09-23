require "nvchad.options"

-- ── [MARKAB] BRUTALIST GEOMETRY OPTIONS ──────────────────────────
local o = vim.o

-- No transparency, solid background
o.termguicolors = true
o.pumblend = 0          -- No popup transparency
o.winblend = 0          -- No floating window transparency

-- Strict window separators
o.fillchars = "vert:│,horiz:─,horizup:┴,horizdown:┬,vertleft:┤,vertright:├,verthoriz:┼"

-- Cursor line for telemetry precision
o.cursorline = true
o.cursorlineopt = "both"

-- Reduce the timeout length to 250ms to fix the "lag" feeling when pressing <Space>
-- This defines how long Neovim waits for a mapped key sequence to complete.
o.timeoutlen = 250

-- Relative line numbers for easier vertical movement
o.relativenumber = true
vim.g.lua_snippets_path = vim.fn.stdpath("config") .. "/snippets"
