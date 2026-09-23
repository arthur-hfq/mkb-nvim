-- Markdown Preview Plugin (Real-Time Terminal Render)
-- This plugin requires 'glow' to be installed on your system.

local M = {}

-- Store the state of the preview
M.state = {
    preview_win = nil,
    preview_buf = nil,
    job_id = nil,
    tmp_file = nil,
    timer = nil,
}

-- Check if the preview window is currently open and valid
local function is_preview_open()
    return M.state.preview_win and vim.api.nvim_win_is_valid(M.state.preview_win)
end

-- Close the preview and clean up resources
function M.close_preview()
    if is_preview_open() then
        vim.api.nvim_win_close(M.state.preview_win, true)
    end
    if M.state.preview_buf and vim.api.nvim_buf_is_valid(M.state.preview_buf) then
        vim.api.nvim_buf_delete(M.state.preview_buf, { force = true })
    end
    if M.state.tmp_file then
        os.remove(M.state.tmp_file)
    end
    if M.state.timer then
        vim.fn.timer_stop(M.state.timer)
    end
    
    M.state.preview_win = nil
    M.state.preview_buf = nil
    M.state.job_id = nil
    M.state.tmp_file = nil
    M.state.timer = nil
end

-- Update the preview terminal with the latest markdown content
function M.update_preview(bufnr)
    if not is_preview_open() then return end

    -- Debounce the update to avoid flickering while typing fast
    if M.state.timer then
        vim.fn.timer_stop(M.state.timer)
    end

    M.state.timer = vim.fn.timer_start(300, function()
        if not is_preview_open() then return end

        -- Read all lines from the current markdown buffer
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local content = table.concat(lines, "\n")
        
        -- Write current unsaved content to a temporary file
        local f = io.open(M.state.tmp_file, "w")
        if f then
            f:write(content)
            f:close()
        end

        -- Send command to terminal to clear screen and render the new markdown content
        if M.state.job_id then
            local cmd = string.format("clear && glow -s dark %s\n", vim.fn.shellescape(M.state.tmp_file))
            vim.api.nvim_chan_send(M.state.job_id, cmd)
        end
    end)
end

-- Toggle the markdown preview terminal
function M.toggle_preview()
    local current_buf = vim.api.nvim_get_current_buf()
    
    -- If it's already open, close it
    if is_preview_open() then
        M.close_preview()
        return
    end

    -- Check if 'glow' is installed, as it is required for rendering
    if vim.fn.executable("glow") == 0 then
        vim.notify("Error: 'glow' is not installed! Please install it (e.g., 'sudo pacman -S glow') to render markdown.", vim.log.levels.ERROR)
        return
    end

    -- Create a temporary file to store the real-time buffer content
    M.state.tmp_file = vim.fn.tempname() .. ".md"

    -- Open a vertical split on the right side
    vim.cmd("botright vsplit")
    M.state.preview_win = vim.api.nvim_get_current_win()
    
    -- Create a new scratch buffer for the terminal
    M.state.preview_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(M.state.preview_win, M.state.preview_buf)
    
    -- Open a bash terminal in this buffer
    vim.fn.termopen("bash")
    M.state.job_id = vim.b.terminal_job_id
    
    -- Set window options to hide line numbers in the terminal
    vim.wo[M.state.preview_win].number = false
    vim.wo[M.state.preview_win].relativenumber = false
    
    -- Move focus back to the original markdown window
    vim.cmd("wincmd p")

    -- Set up autocommands to update the preview on any text change
    local group = vim.api.nvim_create_augroup("MarkdownPreviewRealtime", { clear = true })
    
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufEnter" }, {
        group = group,
        buffer = current_buf,
        callback = function()
            M.update_preview(current_buf)
        end,
    })

    -- Clean up the preview window if the original buffer is closed
    vim.api.nvim_create_autocmd("BufWipeout", {
        group = group,
        buffer = current_buf,
        callback = function()
            M.close_preview()
        end,
    })

    -- Trigger the first update immediately
    M.update_preview(current_buf)
end

-- Initialize the plugin and set up keybindings
function M.setup()
    -- Create a command that can be executed from the Neovim command line
    vim.api.nvim_create_user_command("MdPreviewToggle", M.toggle_preview, {})
    
    -- Set up the keymap ONLY for markdown files
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
            -- Map <leader>mp to toggle the preview
            vim.keymap.set("n", "<leader>mp", M.toggle_preview, { 
                buffer = true, 
                desc = "Toggle Real-Time Markdown Preview (Glow)" 
            })
        end,
    })
end

return M
