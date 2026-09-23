-- ~/.config/nvim/lua/configs/lspconfig.lua

local nvlsp = require "nvchad.configs.lspconfig"

nvlsp.defaults()

-- Language servers to enable
local servers = { "html", "cssls", "pyright", "ts_ls", "yamlls", "jsonls", "volar", "emmet_ls", "clangd", "sqlls", "prismals" }

for _, lsp in ipairs(servers) do
  -- Get the default configuration provided by nvim-lspconfig
  local default_config = vim.lsp.config[lsp] or {}

  -- Merge NvChad's handlers into the default configuration
  local opts = vim.tbl_deep_extend("force", default_config, {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  })

  -- Enable CSS server to read <style> tags inside Vue SFCs
  if lsp == "cssls" then
    opts.filetypes = { "css", "scss", "less", "vue" }
    opts.settings = opts.settings or {}
    opts.settings.css = vim.tbl_deep_extend("force", opts.settings.css or {}, { validate = true, lint = { unknownAtRules = "ignore" } })
    opts.settings.scss = vim.tbl_deep_extend("force", opts.settings.scss or {}, { validate = true, lint = { unknownAtRules = "ignore" } })
    opts.settings.less = vim.tbl_deep_extend("force", opts.settings.less or {}, { validate = true, lint = { unknownAtRules = "ignore" } })
  end
  
  -- Enable HTML server to read <template> tags inside Vue SFCs
  if lsp == "html" then
    opts.filetypes = { "html", "vue" }
    opts.settings = opts.settings or {}
    opts.settings.css = vim.tbl_deep_extend("force", opts.settings.css or {}, { validate = true, lint = { unknownAtRules = "ignore" } })
    opts.settings.html = vim.tbl_deep_extend("force", opts.settings.html or {}, { format = { enable = true } })
  end

  -- Safely assign the merged configuration back
  vim.lsp.config[lsp] = opts
end

vim.lsp.enable(servers)
