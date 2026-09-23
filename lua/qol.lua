-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  [MARKAB] QUALITY OF LIFE (QoL) MAPPINGS                       ║
-- ║  Fast navigation in insert mode & quick block moving           ║
-- ╚══════════════════════════════════════════════════════════════════╝

local map = vim.keymap.set

-- ==========================================
-- INSERT MODE NAVIGATION (Readline Style)
-- ==========================================
-- Goal: Never leave insert mode for simple movements
map("i", "<C-b>", "<Left>", { desc = "Navigation: Move Left" })
map("i", "<C-f>", "<Right>", { desc = "Navigation: Move Right (jump over brackets)" })
map("i", "<C-a>", function()
  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_win_set_cursor(0, {r, 0})
end, { desc = "Navigation: Jump to beginning of line (Instant)" })

map("i", "<C-e>", function()
  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local line_len = string.len(vim.api.nvim_get_current_line())
  vim.api.nvim_win_set_cursor(0, {r, line_len})
end, { desc = "Navigation: Jump to end of line (Instant)" })
map("i", "<C-u>", "<C-o>u", { desc = "Undo in insert mode" })

-- Extra: Undo break points (creates undo steps when typing punctuation)
-- This allows you to undo typing parts of a sentence rather than the whole insert session
local undo_chars = { ",", ".", "!", "?", ";", ":" }
for _, char in ipairs(undo_chars) do
  map("i", char, char .. "<c-g>u", { desc = "Auto undo break point" })
end

-- ==========================================
-- MOVE LINES UP & DOWN (VSCode Style)
-- ==========================================
-- Normal Mode (Alt + J/K)
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })

-- Insert Mode (Alt + J/K)
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move line down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move line up" })

-- Visual Mode (Alt + J/K)
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- ==========================================
-- SCOPE NAVIGATION (Jumping blocks)
-- ==========================================
-- Jump to the beginning or end of the current code block (functions, loops, ifs)
map({"n", "v"}, "[s", "[{", { desc = "Navigation: Jump to start of scope" })
map({"n", "v"}, "]s", "]}", { desc = "Navigation: Jump to end of scope" })
map({"n", "v"}, "[p", "[(", { desc = "Navigation: Jump to start of parentheses" })
map({"n", "v"}, "]p", "])", { desc = "Navigation: Jump to end of parentheses" })
