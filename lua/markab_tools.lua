-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  [MARKAB] MARKAB TOOLS — CODE RUNNER / STRESS TEST / DB        ║
-- ║  Native Neovim API interfaces for development workflows        ║
-- ╚══════════════════════════════════════════════════════════════════╝

local M = {}

-- ── BRUTALIST FLOATING WINDOW FACTORY ───────────────────────────
-- All tool panels use this as a base. Single-pixel borders, no rounding.
local function create_panel(title, opts)
  opts = opts or {}
  local buf = vim.api.nvim_create_buf(false, true)
  local w = opts.width or math.floor(vim.o.columns * 0.85)
  local h = opts.height or math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - h) / 2)
  local col = math.floor((vim.o.columns - w) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = row,
    col = col,
    style = "minimal",
    border = "single",
    title = " " .. title .. " ",
    title_pos = "center",
    footer = " [q] Close | [r] Re-run ",
    footer_pos = "center",
  })

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = true
  vim.wo[win].wrap = true
  vim.wo[win].cursorline = true

  -- Close keybinds
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, { buffer = buf, silent = true })

  return buf, win
end

-- ── ASYNC COMMAND RUNNER ────────────────────────────────────────
-- Runs a shell command asynchronously and streams output into a buffer
local function run_async(cmd, buf, on_done)
  local all_lines = {}
  local display_cmd = cmd
  if display_cmd:find("markab_http_resp") then
    display_cmd = "Running HTTP Request (curl + jq)..."
  elseif display_cmd:find("markab_docker_stress%.sh") then
    display_cmd = "Initializing Docker Stress Test Engine..."
  elseif #display_cmd > 80 then
    display_cmd = display_cmd:sub(1, 77) .. "..."
  end
  
  if display_cmd:find("Initializing Docker Stress Test") then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "┌─ EXECUTING STRESS TEST ─────────────────────────┐", "  " .. display_cmd, "└─────────────────────────────────────────────────┘", "" })
  else
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "┌─ EXECUTING ─────────────────────────────────────┐", "  " .. display_cmd, "└─────────────────────────────────────────────────┘", "", "Waiting for output..." })
  end

  vim.fn.jobstart(cmd, {
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(all_lines, line) end
        end
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_set_lines(buf, 4, -1, false, all_lines)
          end
        end)
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(all_lines, "[STDERR] " .. line) end
        end
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_set_lines(buf, 4, -1, false, all_lines)
          end
        end)
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          table.insert(all_lines, "")
          table.insert(all_lines, "┌─ EXIT ──────────────────────────────────────────┐")
          table.insert(all_lines, string.format("  Exit Code: %d | %s", code, code == 0 and "SUCCESS" or "FAILURE"))
          table.insert(all_lines, "└─────────────────────────────────────────────────┘")
          vim.api.nvim_buf_set_lines(buf, 4, -1, false, all_lines)
          vim.bo[buf].modifiable = false
        end
        if on_done then on_done(code, all_lines) end
      end)
    end,
  })
end

-- ══════════════════════════════════════════════════════════════════
-- 1. CODE SNIPPET RUNNER (Scratch Pad)
-- ══════════════════════════════════════════════════════════════════

-- Run the current buffer or a visual selection as a standalone snippet
function M.run_current_file()
  local ft = vim.bo.filetype
  local file = vim.fn.expand("%:p")

  local runners = {
    python = "python3 " .. file,
    javascript = "node " .. file,
    typescript = "npx tsx " .. file,
    lua = "lua " .. file,
    bash = "bash " .. file,
    sh = "bash " .. file,
    rust = "cargo run --quiet",
    go = "go run " .. file,
    c = "gcc -o /tmp/markab_c_out " .. file .. " && /tmp/markab_c_out",
    cpp = "g++ -o /tmp/markab_cpp_out " .. file .. " && /tmp/markab_cpp_out",
  }

  local cmd = runners[ft]
  if not cmd then
    vim.notify("No runner configured for filetype: " .. ft, vim.log.levels.WARN)
    return
  end

  if vim.bo.buftype == "nofile" or file == "" then
    local ext_map = { python = "py", javascript = "js", typescript = "ts", lua = "lua", bash = "sh", sh = "sh", go = "go", c = "c", cpp = "cpp", rust = "rs" }
    local ext = ext_map[ft] or "txt"
    
    -- Use the current working directory so imports/requires work correctly
    local base_name = "/.markab_temp_run"
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local code_content = table.concat(lines, "\n")
    
    -- Auto-detect if we need a .test extension for Jest
    if (ft == "javascript" or ft == "typescript") and (code_content:match("describe%(") or code_content:match("test%(")) then
      base_name = "/.markab_temp_run.test"
    end
    
    file = vim.fn.getcwd() .. base_name .. "." .. ext
    vim.fn.writefile(lines, file)
    
    -- update cmd to use the temp file
    if ft == "go" or ft == "lua" or ft == "python" or ft == "bash" or ft == "sh" or ft == "javascript" or ft == "typescript" then
      -- Auto-detect tests
      if (ft == "javascript" or ft == "typescript") then
        if code_content:match("describe%(") or code_content:match("test%(") then
          cmd = "npx --yes jest "
          if code_content:match("supertest") then
            cmd = "npm install --no-save supertest && " .. cmd
          end
        end
      elseif ft == "python" then
        if code_content:match("def test_") or code_content:match("import unittest") or code_content:match("import pytest") then
          cmd = "pytest "
        end
      end
      cmd = string.gsub(cmd, " $", " " .. file)
    elseif ft == "c" or ft == "cpp" then
      cmd = runners[ft] -- Re-eval if needed
      if ft == "c" then cmd = "gcc -o .markab_c_out " .. file .. " && ./.markab_c_out" end
      if ft == "cpp" then cmd = "g++ -o .markab_cpp_out " .. file .. " && ./.markab_cpp_out" end
    end
  else
    vim.cmd("w") -- Save first if it's a real file
    -- Auto-detect for real files too
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local code_content = table.concat(lines, "\n")
    if (ft == "javascript" or ft == "typescript") then
      if code_content:match("describe%(") or code_content:match("test%(") then
        cmd = "npx --yes jest " .. file
        if code_content:match("supertest") then
          cmd = "npm install --no-save supertest && " .. cmd
        end
      end
    elseif ft == "python" then
      if code_content:match("def test_") or code_content:match("import unittest") or code_content:match("import pytest") then
        cmd = "pytest " .. file
      end
    end
  end

  local buf, win = create_panel("CODE RUNNER [" .. string.upper(ft) .. "]")

  -- Bind 'r' to re-run
  vim.keymap.set("n", "r", function()
    vim.bo[buf].modifiable = true
    run_async(cmd, buf)
  end, { buffer = buf, silent = true })

  run_async(cmd, buf)
end

-- Run only the visually selected lines as a snippet
function M.run_selection()
  local ft = vim.bo.filetype
  local interpreters = {
    python = "python3",
    javascript = "node -e",
    bash = "bash -c",
    sh = "bash -c",
    lua = "lua -e",
  }

  local interpreter = interpreters[ft]
  if not interpreter then
    vim.notify("No interpreter for filetype: " .. ft, vim.log.levels.WARN)
    return
  end

  -- Get visual selection
  local _, srow, _, _ = unpack(vim.fn.getpos("'<"))
  local _, erow, _, _ = unpack(vim.fn.getpos("'>"))
  local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
  local code = table.concat(lines, "\n")

  -- Write snippet to a temp file to avoid shell escaping nightmares
  local tmpfile = "/tmp/markab_snippet." .. (ft == "python" and "py" or ft)
  local f = io.open(tmpfile, "w")
  if f then
    f:write(code)
    f:close()
  end

  local cmd = interpreter .. " " .. tmpfile
  local buf, win = create_panel("SNIPPET RUNNER [" .. string.upper(ft) .. "] (" .. #lines .. " lines)")
  run_async(cmd, buf)
end

-- Open a disposable scratch buffer for quick experiments
function M.scratch_pad()
  vim.ui.select(
    { "python", "javascript", "bash", "lua", "sql", "go", "rust", "c" },
    { prompt = "Select language for scratch pad:" },
    function(choice)
      if not choice then return end
      local ext_map = {
        python = "py", javascript = "js", bash = "sh", lua = "lua",
        sql = "sql", go = "go", rust = "rs", c = "c",
      }
      local ext = ext_map[choice] or choice
      local tmpfile = "/tmp/markab_scratch." .. ext
      vim.cmd("edit " .. tmpfile)
      vim.bo.filetype = choice

      -- Insert a header comment
      local comment_map = {
        python = "#", javascript = "//", bash = "#", lua = "--",
        sql = "--", go = "//", rust = "//", c = "//",
      }
      local c = comment_map[choice] or "#"
      vim.api.nvim_buf_set_lines(0, 0, 0, false, {
        c .. " ╔══════════════════════════════════════════╗",
        c .. " ║  [MARKAB] SCRATCH PAD — " .. string.upper(choice) .. string.rep(" ", 16 - #choice) .. "║",
        c .. " ╚══════════════════════════════════════════╝",
        "",
      })
      vim.api.nvim_win_set_cursor(0, { 5, 0 })
    end
  )
end


-- ══════════════════════════════════════════════════════════════════
-- 2. API STRESS TEST (Docker-Isolated)
--    Spins up a resource-constrained container, boots the server,
--    runs load from the HOST, and generates a full report with
--    P95/P99 latency, throughput, and container metrics.
-- ══════════════════════════════════════════════════════════════════

-- Auto-detect project type from files in the current working directory
local function detect_project_type(dir)
  local checks = {
    { file = "package.json", label = "Node.js", cmd = "node server.js" },
    { file = "requirements.txt", label = "Python", cmd = "python3 app.py" },
    { file = "pyproject.toml", label = "Python", cmd = "python3 -m uvicorn main:app --host 0.0.0.0" },
    { file = "go.mod", label = "Go", cmd = "go run ." },
    { file = "composer.json", label = "PHP/Laravel", cmd = "php artisan serve --host=0.0.0.0 --port=8000" },
    { file = "Cargo.toml", label = "Rust", cmd = "cargo run --release" },
    { file = "Gemfile", label = "Ruby", cmd = "ruby app.rb" },
  }
  for _, c in ipairs(checks) do
    if vim.fn.filereadable(dir .. "/" .. c.file) == 1 then
      return c.label, c.cmd
    end
  end
  return "Unknown", ""
end

function M.stress_test()
  local project_dir = vim.fn.getcwd()
  local detected_lang, _ = detect_project_type(project_dir)

  vim.notify("Project: " .. project_dir .. " (" .. detected_lang .. ")", vim.log.levels.INFO)

  vim.ui.select(
    {
      "0.5 CPU / 256m RAM (micro)",
      "1 CPU / 512m RAM (small)",
      "2 CPU / 1g RAM (standard)",
      "4 CPU / 2g RAM (large)",
    },
    { prompt = "Container resources:" },
    function(res_choice)
      if not res_choice then return end

      local res_map = {
        ["0.5 CPU / 256m RAM (micro)"]    = { cpus = "0.5", mem = "256m" },
        ["1 CPU / 512m RAM (small)"]      = { cpus = "1",   mem = "512m" },
        ["2 CPU / 1g RAM (standard)"]     = { cpus = "2",   mem = "1g" },
        ["4 CPU / 2g RAM (large)"]        = { cpus = "4",   mem = "2g" },
      }
      local res = res_map[res_choice]

      vim.ui.input({ prompt = "Start command (e.g. npm run dev): " }, function(start_cmd)
        if not start_cmd or start_cmd == "" then return end
        M._stress_step_port(project_dir, res, start_cmd)
      end)
    end
  )
end

function M._stress_step_port(project_dir, res, start_cmd)
  vim.ui.input({ prompt = "Container port (default 3000): " }, function(port_input)
    local port = (port_input and port_input ~= "") and port_input or "3000"

    vim.ui.input({ prompt = "Route to test (e.g. /api/users): " }, function(route)
      if not route or route == "" then route = "/" end

      vim.ui.select({ "GET", "POST", "PUT", "DELETE", "PATCH" }, { prompt = "HTTP Method:" }, function(method)
        if not method then return end

        vim.ui.input({ prompt = "Total number of requests (default 100): " }, function(count_input)
          local count = (count_input and count_input ~= "") and count_input or "100"

          vim.ui.input({ prompt = "Concurrent requests (default 50): " }, function(conc_input)
            local concurrency = (conc_input and conc_input ~= "") and conc_input or "50"

            vim.ui.input({ prompt = "Timeout per request in seconds (default 10): " }, function(timeout_input)
              local timeout = (timeout_input and timeout_input ~= "") and timeout_input or "10"

              if method == "POST" or method == "PUT" or method == "PATCH" then
                vim.ui.input({ prompt = "JSON Body (or empty): " }, function(body)
                  body = body or ""
                  M._launch_docker_stress(project_dir, res, start_cmd, port, route, method, count, concurrency, timeout, body)
                end)
              else
                M._launch_docker_stress(project_dir, res, start_cmd, port, route, method, count, concurrency, timeout, "")
              end
            end)
          end)
        end)
      end)
    end)
  end)
end

function M._launch_docker_stress(project_dir, res, start_cmd, port, route, method, count, concurrency, timeout, body)
  local script = vim.fn.expand("~/.config/nvim/scripts/markab_docker_stress.sh")
  
  local cmd = string.format(
    "bash %s %s %s %s %s %s %s %s %s %s %s %s",
    vim.fn.shellescape(script),
    vim.fn.shellescape(project_dir),
    vim.fn.shellescape(res.cpus),
    vim.fn.shellescape(res.mem),
    vim.fn.shellescape(start_cmd),
    vim.fn.shellescape(port),
    vim.fn.shellescape(route),
    vim.fn.shellescape(method),
    vim.fn.shellescape(count),
    vim.fn.shellescape(concurrency),
    vim.fn.shellescape(timeout),
    vim.fn.shellescape(body)
  )

  local title = string.format("DOCKER STRESS [%s CPU/%s RAM] %s %s", res.cpus, res.mem, method, route)
  local buf, _ = create_panel(title)

  vim.keymap.set("n", "r", function()
    vim.bo[buf].modifiable = true
    run_async(cmd, buf)
  end, { buffer = buf, silent = true })

  run_async(cmd, buf)
end


-- ══════════════════════════════════════════════════════════════════
-- 3. DATABASE QUICK CONNECT (wraps vim-dadbod)
-- ══════════════════════════════════════════════════════════════════

function M.db_connect()
  local presets = {
    { label = "SQLite (local file)", uri_template = "sqlite:%s" },
    { label = "PostgreSQL", uri_template = "postgresql://%s" },
    { label = "MySQL", uri_template = "mysql://%s" },
    { label = "Custom URI", uri_template = "%s" },
  }

  local labels = {}
  for _, p in ipairs(presets) do
    table.insert(labels, p.label)
  end

  vim.ui.select(labels, { prompt = "Database engine:" }, function(choice, idx)
    if not choice then return end

    local prompt_text = "Connection string: "
    if idx == 1 then
      prompt_text = "Path to .db file (e.g. ~/mydb.sqlite3): "
    elseif idx == 4 then
      prompt_text = "Full URI (e.g. postgresql://user:pass@host/db): "
    else
      prompt_text = "user:pass@host:port/dbname: "
    end

    vim.ui.input({ prompt = prompt_text }, function(input)
      if not input or input == "" then return end

      local uri = string.format(presets[idx].uri_template, input)
      -- Expand ~ for sqlite
      if idx == 1 then
        uri = "sqlite:" .. vim.fn.expand(input)
      end

      vim.g.db = uri
      vim.cmd("DBUI")
      vim.notify("Connected to: " .. uri, vim.log.levels.INFO, { title = "Database" })
    end)
  end)
end

-- Quick SQL query runner without opening full DBUI
function M.db_query()
  if not vim.g.db or vim.g.db == "" then
    vim.notify("No database connected. Use <leader>dc first.", vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = "SQL Query: " }, function(query)
    if not query or query == "" then return end

    local cmd = string.format("echo %s | python3 -c \"import sys; print(sys.stdin.read())\" | db %s", vim.fn.shellescape(query), vim.fn.shellescape(vim.g.db))

    -- Use vim-dadbod's native execution
    vim.cmd("DB " .. vim.fn.shellescape(query))
  end)
end


-- ══════════════════════════════════════════════════════════════════
-- 4. HTTP REQUEST FILE (.http) TEMPLATE GENERATOR
-- ══════════════════════════════════════════════════════════════════

function M.new_http_file()
  local tmpfile = "/tmp/markab_request.http"
  vim.cmd("edit " .. tmpfile)
  vim.bo.filetype = "http"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "# ╔══════════════════════════════════════════╗",
    "# ║  [MARKAB] HTTP REQUEST FILE              ║",
    "# ║  Place cursor on a request and press     ║",
    "# ║  <leader>hr to execute it                ║",
    "# ╚══════════════════════════════════════════╝",
    "",
    "### Health Check",
    "GET http://localhost:3000/health",
    "",
    "### Get All Users",
    "GET http://localhost:3000/api/users",
    "Accept: application/json",
    "",
    "### Create User",
    "POST http://localhost:3000/api/users",
    "Content-Type: application/json",
    "",
    '{',
    '  "name": "Markab",',
    '  "email": "markab@kcore.dev"',
    '}',
    "",
    "### Update User",
    "PUT http://localhost:3000/api/users/1",
    "Content-Type: application/json",
    "",
    '{',
    '  "name": "Markab Updated"',
    '}',
    "",
    "### Delete User",
    "DELETE http://localhost:3000/api/users/1",
  })
  vim.api.nvim_win_set_cursor(0, { 8, 0 })
end


-- ══════════════════════════════════════════════════════════════════
-- 5. HTTP REQUEST RUNNER (parses .http files, runs with curl)
-- ══════════════════════════════════════════════════════════════════

function M.run_http_under_cursor()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]

  -- Find the request block around the cursor
  local req_start, req_end = nil, nil
  for i = cursor_row, 1, -1 do
    if lines[i]:match("^###") or lines[i]:match("^(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS)%s") then
      req_start = i
      break
    end
  end

  if not req_start then
    -- Try current line
    if lines[cursor_row] and lines[cursor_row]:match("^%u+%s+http") then
      req_start = cursor_row
    else
      vim.notify("No HTTP request found under cursor", vim.log.levels.WARN)
      return
    end
  end

  -- If we landed on a ### comment, skip to next line
  if lines[req_start]:match("^###") then
    req_start = req_start + 1
  end

  -- Find end of this request block
  req_end = #lines
  for i = req_start + 1, #lines do
    if lines[i]:match("^###") then
      req_end = i - 1
      break
    end
  end

  -- Parse method and URL from first line
  local method, url = lines[req_start]:match("^(%u+)%s+(.*)")
  if not method or not url then
    vim.notify("Invalid request format: " .. lines[req_start], vim.log.levels.ERROR)
    return
  end

  -- Parse headers and body
  local headers = {}
  local body_lines = {}
  local in_body = false
  for i = req_start + 1, req_end do
    local line = lines[i]
    if line == "" and not in_body then
      in_body = true
    elseif in_body then
      table.insert(body_lines, line)
    elseif line:match("^%S+:%s") then
      table.insert(headers, line)
    end
  end

  -- Build curl command with improved UI
  local tmp_resp = "/tmp/markab_http_resp_" .. os.time() .. ".txt"
  local telemetry = "'╔════ TELEMETRY ════════════════════════════════════╗\\n║ HTTP Code : %{http_code}\\n║ Time Total: %{time_total}s\\n║ Size      : %{size_download} bytes\\n║ DNS       : %{time_namelookup}s\\n║ Connect   : %{time_connect}s\\n║ TTFB      : %{time_starttransfer}s\\n╚═══════════════════════════════════════════════════╝\\n\\n'"

  local curl_parts = { "curl", "-s", "-o", tmp_resp, "-w", telemetry, "-X", method }

  for _, h in ipairs(headers) do
    table.insert(curl_parts, "-H")
    table.insert(curl_parts, vim.fn.shellescape(h))
  end

  if #body_lines > 0 then
    local body = table.concat(body_lines, "\n")
    table.insert(curl_parts, "-d")
    table.insert(curl_parts, vim.fn.shellescape(body))
  end

  table.insert(curl_parts, vim.fn.shellescape(url))
  local raw_curl = table.concat(curl_parts, " ")

  local cmd = string.format("bash -c %s", vim.fn.shellescape(
    raw_curl .. " && echo '╔════ RESPONSE BODY ════════════════════════════════╗' && (jq . " .. tmp_resp .. " 2>/dev/null || python3 -m json.tool " .. tmp_resp .. " 2>/dev/null || cat " .. tmp_resp .. "); echo ''; rm -f " .. tmp_resp
  ))

  local buf, _ = create_panel("HTTP " .. method .. " " .. url)

  vim.keymap.set("n", "r", function()
    vim.bo[buf].modifiable = true
    run_async(cmd, buf)
  end, { buffer = buf, silent = true })

  run_async(cmd, buf)
end


return M
