-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  [MARKAB] CUSTOM TODO TRACKER PLUGIN                             ║
-- ║  Highlights TODOs and tracks them across the git project.        ║
-- ╚══════════════════════════════════════════════════════════════════╝

local M = {}

-- Define the Brutalist colors for TODOs
local function setup_highlights()
  vim.api.nvim_set_hl(0, "MarkabTodoHighlight", { fg = "#1C1427", bg = "#7ECA9C", bold = true })
  vim.api.nvim_set_hl(0, "MarkabFixmeHighlight", { fg = "#1C1427", bg = "#FF6B6B", bold = true })
end

-- Automatically highlight TODO and FIXME in all buffers
function M.setup()
  setup_highlights()
  
  -- Create autocommands to apply highlights whenever a buffer is opened
  local group = vim.api.nvim_create_augroup("MarkabTodoHighlighter", { clear = true })
  
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "Syntax" }, {
    group = group,
    callback = function()
      -- Highlight just the word TODO and FIXME (not the rest of the line)
      vim.fn.matchadd("MarkabTodoHighlight", "\\<TODO\\>")
      vim.fn.matchadd("MarkabFixmeHighlight", "\\<FIXME\\>")
    end,
  })
end

-- Find nearest .git directory
local function find_git_root()
  local current_dir = vim.fn.expand("%:p:h")
  local git_dir = vim.fn.finddir(".git", current_dir .. ";")
  if git_dir == "" then
    return vim.fn.getcwd() -- Fallback to current working directory
  end
  return vim.fn.fnamemodify(git_dir, ":h")
end

-- Brutalist floating window for TODOs
local function create_todo_panel(title)
  local buf = vim.api.nvim_create_buf(false, true)
  local w = math.floor(vim.o.columns * 0.8)
  local h = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - h) / 2)
  local col = math.floor((vim.o.columns - w) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = w, height = h, row = row, col = col,
    style = "minimal", border = "single",
    title = " " .. title .. " ", title_pos = "center",
    footer = " [Enter] Jump | [q] Close ", footer_pos = "center",
  })

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = true
  vim.wo[win].cursorline = true

  -- Close binds
  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, silent = true })

  return buf, win
end

-- Parse and display TODOs
function M.project_todos()
  local root = find_git_root()
  
  -- Run Ripgrep to find TODOs in the project
  local cmd = string.format("rg '(TODO|FIXME)' --vimgrep --trim %s", vim.fn.shellescape(root))
  local output = vim.fn.systemlist(cmd)
  
  if vim.v.shell_error ~= 0 and #output == 0 then
    vim.notify("No TODOs found in project!", vim.log.levels.INFO)
    return
  end

  local buf, win = create_todo_panel("PROJECT TASKS [" .. vim.fn.fnamemodify(root, ":t") .. "]")
  
  -- Format the output for the UI
  local display_lines = {
    "┌─ FOUND " .. #output .. " TASKS ──────────────────────────────────────────────┐",
  }
  
  -- Store raw data for jumping
  local jump_data = {}

  for i, line in ipairs(output) do
    -- rg --vimgrep format: file:line:col:text
    local file, lnum, col, text = line:match("([^:]+):(%d+):(%d+):(.*)")
    if file then
      local rel_file = vim.fn.fnamemodify(file, ":.")
      local formatted = string.format("  %-30s │ %s", rel_file .. ":" .. lnum, text)
      table.insert(display_lines, formatted)
      jump_data[#display_lines] = { file = file, lnum = tonumber(lnum), col = tonumber(col) }
    end
  end
  table.insert(display_lines, "└─────────────────────────────────────────────────────────────┘")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)
  vim.bo[buf].modifiable = false

  -- Enter to jump to the file
  vim.keymap.set("n", "<CR>", function()
    local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
    local target = jump_data[cursor_line]
    if target then
      vim.api.nvim_win_close(win, true)
      vim.cmd("edit " .. vim.fn.fnameescape(target.file))
      vim.api.nvim_win_set_cursor(0, { target.lnum, target.col - 1 })
      -- Center screen
      vim.cmd("normal! zz")
    end
  end, { buffer = buf, silent = true })

end

return M
