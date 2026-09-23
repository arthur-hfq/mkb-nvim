-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  [MARKAB] AGY INTEGRATION — AI TELEMETRY                     ║
-- ╚══════════════════════════════════════════════════════════════════╝
local M = {}

local function create_floating_window(title)
  local buf = vim.api.nvim_create_buf(false, true)
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
  vim.bo[buf].modifiable = true
  
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, { buffer = buf, silent = true })

  vim.keymap.set("n", "<Esc>", function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, { buffer = buf, silent = true })

  return buf, win
end

local function run_agy_prompt(prompt, buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Waiting for AGY response..."})
  local cmd = string.format("agy --print %s", vim.fn.shellescape(prompt))
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, data)
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 1 then
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
      end
    end,
  })
end

function M.generate_code()
  vim.ui.input({ prompt = "AGY Generate: " }, function(input)
    if not input or input == "" then return end
    local prompt = "Generate code for: " .. input .. ". Provide ONLY the code without markdown formatting or ticks."
    
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local buf = vim.api.nvim_get_current_buf()
    
    vim.api.nvim_buf_set_lines(buf, row, row, false, {"-- Generating..."})
    
    local cmd = string.format("agy --print %s", vim.fn.shellescape(prompt))
    vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data then
          vim.api.nvim_buf_set_lines(buf, row, row + 1, false, data)
        end
      end,
    })
  end)
end

function M.suggest_code()
  -- Get visual selection
  local _, srow, scol, _ = unpack(vim.fn.getpos("'<"))
  local _, erow, ecol, _ = unpack(vim.fn.getpos("'>"))
  local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
  local code = table.concat(lines, "\n")
  
  local prompt = "Suggest improvements for the following code:\n\n" .. code
  local buf, _ = create_floating_window("AGY Code Suggestion")
  run_agy_prompt(prompt, buf)
end

function M.stress_test_api()
  vim.ui.input({ prompt = "API URL to Stress Test: " }, function(url)
    if not url or url == "" then return end
    local prompt = "Write a quick bash script using curl or ab to stress test this API and run it. Show me the results: " .. url
    local buf, _ = create_floating_window("AGY API Stress Test")
    run_agy_prompt(prompt, buf)
  end)
end

function M.generate_unit_test()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local code = table.concat(lines, "\n")
  
  local lang = vim.bo.filetype
  local current_file = vim.fn.expand("%:t")
  if current_file == "" then current_file = "unknown" end

  local prompt = string.format([[
You are an expert developer. The user wants to generate a unit test for the specific code entity located at LINE %d in the provided %s file (original file: %s).

CRITICAL INSTRUCTIONS:
1. DO NOT write tests for the entire file. Identify the specific function/class at LINE %d.
2. Analyze its local dependencies (e.g., if function X calls Y in the same file, include Y in your understanding or mock it).
3. Use the standard test framework for this language (e.g. jest for JS/TS, pytest for Python, testing for Go).
4. Output EXACTLY a raw JSON object with two keys:
   - "filename": The ideal path for this test file according to standard conventions (e.g., "tests/%s.test.js" or "test_main.py").
   - "code": The full test code. Include proper imports/requires and mock any external dependencies if necessary.
DO NOT wrap the JSON in markdown blocks (no ```json). Output raw JSON only.

Code context (entire file provided for dependency resolution, focus ONLY on the entity at line %d):
%s
]], row, lang, current_file, row, current_file:gsub("%..+$", ""), row, code)

  local res_buf, win = create_floating_window("AGY UNIT TEST [" .. string.upper(lang) .. "]")
  vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, {"Generating isolated unit test via AGY...", "Waiting for JSON response..."})
  
  local cmd = { "agy", "--print", prompt }
  
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local response = table.concat(data, "\n")
        
        -- Strip markdown if AI still outputs it
        local json_block = response:match("```json\n(.-)```") or response:match("```\n(.-)```")
        if json_block then response = json_block end
        
        local ok, parsed = pcall(vim.json.decode, response)
        if not ok or not parsed.code then
          -- Fallback if not proper JSON
          vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, {"Failed to parse JSON. Raw output:", "", response})
          return
        end
        
        -- Write the code to the buffer
        vim.bo[res_buf].filetype = lang
        local out_lines = vim.split(parsed.code, "\n")
        
        -- Add instructions at the top (using the correct comment syntax based on filetype)
        local comment_char = (lang == "javascript" or lang == "typescript" or lang == "c" or lang == "cpp" or lang == "go" or lang == "rust") and "//" or "#"
        if lang == "lua" then comment_char = "--" end
        
        table.insert(out_lines, 1, comment_char .. " ═════════════════════════════════════════════════════════════")
        table.insert(out_lines, 2, comment_char .. " AI UNIT TEST GENERATED")
        table.insert(out_lines, 3, comment_char .. " [ <leader>rr ] to Run this test in a temporary container")
        table.insert(out_lines, 4, comment_char .. " [ <leader>ss ] to Save it permanently to: " .. parsed.filename)
        table.insert(out_lines, 5, comment_char .. " ═════════════════════════════════════════════════════════════")
        table.insert(out_lines, 6, "")
        
        vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, out_lines)
        
        -- Set up the save keybind
        vim.keymap.set("n", "<leader>ss", function()
          local target_path = parsed.filename
          local dir = vim.fn.fnamemodify(target_path, ":h")
          if dir ~= "." and vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir, "p")
          end
          
          -- Extract just the code, skipping our 6 lines of comments
          local final_lines = vim.api.nvim_buf_get_lines(res_buf, 6, -1, false)
          vim.fn.writefile(final_lines, target_path)
          
          vim.notify("Saved test to " .. target_path, vim.log.levels.INFO)
          vim.api.nvim_win_close(win, true)
          vim.cmd("edit " .. vim.fn.fnameescape(target_path))
        end, { buffer = res_buf, silent = true, desc = "Save AI Test" })
      end
    end,
  })
end

function M.generate_file()
  vim.ui.input({ prompt = "Describe what this file should do (AGY PRO): " }, function(desc)
    if not desc or desc == "" then return end
    
    local buf = vim.api.nvim_get_current_buf()
    local current_file = vim.fn.expand("%:p")
    local relative_file = vim.fn.expand("%:.")
    if current_file == "" then
      vim.notify("Please save the file or give it a name first.", vim.log.levels.WARN)
      return
    end

    local lang = vim.bo.filetype
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local existing_code = table.concat(lines, "\n")
    
    local prompt = string.format([[
You are an expert developer. The user wants you to generate the COMPLETE contents for the file: %s
Filetype/Language: %s

User instructions for this file:
"%s"

Existing contents (if any):
%s

CRITICAL INSTRUCTIONS:
1. Write the COMPLETE file contents. Do not output anything else.
2. DO NOT use markdown blocks (```) around the code. Output ONLY the raw file content.
3. If the file has existing code, incorporate the user's instructions to rewrite/complete it.
]], relative_file, lang, desc, existing_code)

    local res_buf, win = create_floating_window("AGY FILE GENERATOR (PRO)")
    vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, {"Generating full file contents...", "Using Gemini PRO (This might take a few seconds)..."})
    
    local cmd = { "agy", "--model", "pro", "--print", prompt }
    
    vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data and #data > 0 then
          local response = table.concat(data, "\n")
          
          -- Strip markdown if AI still outputs it
          local code_block = response:match("^```%w*\n(.-)```$") or response:match("```\n(.-)```")
          if code_block then response = code_block end
          
          local out_lines = vim.split(response, "\n")
          
          vim.bo[res_buf].filetype = lang
          vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, out_lines)
          
          -- Bind a key to Apply the changes to the real buffer
          vim.keymap.set("n", "<leader>aa", function()
            local final_lines = vim.api.nvim_buf_get_lines(res_buf, 0, -1, false)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, final_lines)
            vim.notify("Code applied to " .. relative_file .. "!", vim.log.levels.INFO)
            vim.api.nvim_win_close(win, true)
          end, { buffer = res_buf, silent = true, desc = "Apply Code to Buffer" })
          
          vim.notify("Generation complete! Press <leader>aa in the window to apply.", vim.log.levels.INFO)
        end
      end,
    })
  end)
end

return M
