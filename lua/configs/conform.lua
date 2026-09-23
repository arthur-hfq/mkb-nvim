-- ~/.config/nvim/lua/configs/conform.lua

local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    
    -- Web/Frontend
    vue = { "prettier" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
    json = { "prettier" },
    yaml = { "prettier" },
    
    -- Backend / Compiled / Scripts (Zero-Config ready)
    python = { "black", "isort" },
    go = { "gofmt", "goimports" },
    rust = { "rustfmt" },
    cs = { "csharpier" }, -- C# 
    php = { "php-cs-fixer" },
    ruby = { "rubocop" },
    sh = { "shfmt" },
    bash = { "shfmt" },
  },

  -- Automatically format code when saving the file (<leader>w or :w)
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

require("conform").setup(options)

return options
