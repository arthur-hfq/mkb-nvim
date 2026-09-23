-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  [MARKAB] KEYBINDINGS — BRUTALIST TELEMETRY                    ║
-- ║  All mappings in English. Organized by workflow domain.         ║
-- ╚══════════════════════════════════════════════════════════════════╝

local map = vim.keymap.set

-- ==========================================
-- FILE EXPLORER
-- ==========================================
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Explorer: Toggle NvimTree" })

-- ==========================================
-- GENERAL PRODUCTIVITY
-- ==========================================
map("n", "<leader>w", "<cmd>w<CR>", { desc = "File: Save current buffer" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "File: Quit current window" })

map("n", "<leader>x", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "Buffer: Close current buffer" })

map("n", "<Tab>", function()
  require("nvchad.tabufline").next()
end, { desc = "Buffer: Go to next buffer" })

map("n", "<S-Tab>", function()
  require("nvchad.tabufline").prev()
end, { desc = "Buffer: Go to previous buffer" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "General: Clear search highlights" })

-- ==========================================
-- WINDOW MANAGEMENT (SPLITS)
-- ==========================================
map("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Window: Split vertically" })
map("n", "<leader>sh", "<cmd>split<CR>", { desc = "Window: Split horizontally" })
map("n", "<C-h>", "<C-w>h", { desc = "Window: Focus left" })
map("n", "<C-l>", "<C-w>l", { desc = "Window: Focus right" })
map("n", "<C-j>", "<C-w>j", { desc = "Window: Focus down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window: Focus up" })

-- ==========================================
-- TEXT MANIPULATION
-- ==========================================
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll: Down half page and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll: Up half page and center" })
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move: Shift selected block down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move: Shift selected block up" })

-- ==========================================
-- SNIPPETS (LuaSnip)
-- ==========================================
map({ "i", "s" }, "<C-l>", function()
  local ls = require("luasnip")
  if ls.expand_or_jumpable() then ls.expand_or_jump() end
end, { desc = "Snippet: Jump forward" })

map({ "i", "s" }, "<C-h>", function()
  local ls = require("luasnip")
  if ls.jumpable(-1) then ls.jump(-1) end
end, { desc = "Snippet: Jump backward" })

-- ==========================================
-- TERMINAL INTEGRATIONS
-- ==========================================
map("n", "<leader>ag", function()
  require("nvchad.term").toggle { pos = "float", id = "agy_terminal", cmd = "agy", float_opts = { border = "single" } }
end, { desc = "Terminal: Toggle Antigravity (agy)" })

map("n", "<leader>gl", function()
  require("nvchad.term").toggle { pos = "float", id = "lazygit_term", cmd = "lazygit", float_opts = { border = "single" } }
end, { desc = "Git: Toggle Lazygit" })

map("n", "<leader>ld", function()
  require("nvchad.term").toggle { pos = "float", id = "lazydocker_term", cmd = "lazydocker", float_opts = { border = "single" } }
end, { desc = "Docker: Toggle Lazydocker" })

map("t", "<Esc><Esc>", "<cmd>close<CR>", { desc = "Terminal: Hide floating window" })

-- ==========================================
-- GIT SHORTCUTS (Native)
-- ==========================================
local function run_git_float(cmd, title)
  local output = vim.fn.systemlist(cmd)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "single",
    title = " " .. title .. " (Press 'q' or '<Esc>' to close) ",
    title_pos = "center",
  })

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "git"

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, { buffer = buf, silent = true })
end

map("n", "<leader>gs", function()
  run_git_float("git status", "Git Status")
end, { desc = "Git: View status" })

map("n", "<leader>gt", function()
  run_git_float("git log --oneline --graph --all --decorate", "Git Tree")
end, { desc = "Git: View commit tree" })

map("n", "<leader>ga", function()
  vim.fn.system("git add .")
  vim.notify("All files staged (git add .)", vim.log.levels.INFO, { title = "Git" })
end, { desc = "Git: Add all files" })

map("n", "<leader>gc", function()
  vim.ui.input({ prompt = "Commit message: " }, function(msg)
    if msg and #msg > 0 then
      local result = vim.fn.system("git commit -m " .. vim.fn.shellescape(msg))
      vim.notify(result, vim.log.levels.INFO, { title = "Git: Commit" })
    end
  end)
end, { desc = "Git: Commit with message" })

map("n", "<leader>gA", function()
  vim.ui.input({ prompt = "Add & Commit message: " }, function(msg)
    if msg and #msg > 0 then
      vim.fn.system("git add .")
      local result = vim.fn.system("git commit -m " .. vim.fn.shellescape(msg))
      vim.notify(result, vim.log.levels.INFO, { title = "Git: Add & Commit" })
    end
  end)
end, { desc = "Git: Add all and commit" })

map("n", "<leader>gb", function()
  local raw_branches = vim.fn.systemlist("git branch --format='%(refname:short)'")
  if #raw_branches == 0 or raw_branches[1] == "" then
    vim.notify("No branches found or not a Git repository.", vim.log.levels.WARN, { title = "Git" })
    return
  end
  vim.ui.select(raw_branches, { prompt = "Select branch to checkout:" }, function(choice)
    if choice then
      local result = vim.fn.system("git checkout " .. vim.fn.shellescape(choice))
      vim.cmd("checktime")
      vim.notify(result, vim.log.levels.INFO, { title = "Git: Checkout" })
    end
  end)
end, { desc = "Git: Select and checkout branch" })

map("n", "<leader>gn", function()
  vim.ui.input({ prompt = "New branch name: " }, function(name)
    if name and #name > 0 then
      local result = vim.fn.system("git checkout -b " .. vim.fn.shellescape(name))
      vim.cmd("checktime")
      vim.notify(result, vim.log.levels.INFO, { title = "Git: New Branch" })
    end
  end)
end, { desc = "Git: Create & checkout new branch" })

-- ==========================================
-- DATABASE
-- ==========================================
map("n", "<leader>du", "<cmd>DBUIToggle<cr>", { desc = "Database: Toggle DBUI Panel" })
map("n", "<leader>dc", function() require("markab_tools").db_connect() end, { desc = "Database: Quick Connect" })
map("n", "<leader>dq", function() require("markab_tools").db_query() end, { desc = "Database: Run Quick Query" })

-- ==========================================
-- CODE RUNNER & SNIPPET TESTER
-- ==========================================
map("n", "<leader>rr", function() require("markab_tools").run_current_file() end, { desc = "Runner: Run current file" })
map("v", "<leader>rs", function() require("markab_tools").run_selection() end, { desc = "Runner: Run visual selection" })
map("n", "<leader>rn", function() require("markab_tools").scratch_pad() end, { desc = "Runner: New scratch pad" })

-- ==========================================
-- TEST FRAMEWORK (Neotest)
-- ==========================================
map("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, { desc = "Test: Run current file" })
map("n", "<leader>tn", function() require("neotest").run.run() end, { desc = "Test: Run nearest test" })
map("n", "<leader>to", function() require("neotest").output.open({ enter = true }) end, { desc = "Test: Show output" })
map("n", "<leader>ts", function() require("neotest").summary.toggle() end, { desc = "Test: Toggle summary panel" })

-- ==========================================
-- API STRESS TEST
-- ==========================================
map("n", "<leader>st", function() require("markab_tools").stress_test() end, { desc = "Stress: API load test" })

-- ==========================================
-- HTTP CLIENT (.http files)
-- ==========================================
map("n", "<leader>hn", function() require("markab_tools").new_http_file() end, { desc = "HTTP: New request file" })
map("n", "<leader>hr", function() require("markab_tools").run_http_under_cursor() end, { desc = "HTTP: Execute request under cursor" })

-- ==========================================
-- AGY (ANTIGRAVITY AI) INTEGRATIONS
-- ==========================================
map("n", "<leader>ai", function() require("agy_integration").generate_code() end, { desc = "AGY: Generate code at cursor" })
map("v", "<leader>as", function() require("agy_integration").suggest_code() end, { desc = "AGY: Suggest improvements (visual)" })
map("n", "<leader>au", function() require("agy_integration").generate_unit_test() end, { desc = "AGY: Generate isolated unit test" })
map("n", "<leader>cg", function() require("agy_integration").generate_file() end, { desc = "AGY: Generate Full File (PRO)" })
-- ==========================================
-- LIVE SERVER
-- ==========================================
map("n", "<leader>ls", function()
  -- Smart Live Server: Find project root (looking for .git or fallback to current directory)
  local root = vim.fs.root(0, { ".git", "package.json", "index.html" }) or vim.fn.getcwd()
  vim.cmd("LiveServerStart " .. vim.fn.fnameescape(root))
end, { desc = "Server: Smart Start Live Server at Root" })
map("n", "<leader>lS", "<cmd>LiveServerStop<CR>", { desc = "Server: Stop Live Server" })

-- ==========================================
-- PROJECT TODO TRACKER
-- ==========================================
map("n", "<leader>tt", function() require("markab_todo").project_todos() end, { desc = "Project: View all TODOs" })
