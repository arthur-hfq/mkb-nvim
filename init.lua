vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme (self-healing: rebuild cache if deleted)
local base46_ok = pcall(dofile, vim.g.base46_cache .. "defaults")
if base46_ok then
  pcall(dofile, vim.g.base46_cache .. "statusline")
else
  vim.schedule(function()
    local ok, base46 = pcall(require, "base46")
    if ok and base46.load_all_highlights then
      base46.load_all_highlights()
    elseif ok and base46.compile then
      base46.compile()
      pcall(dofile, vim.g.base46_cache .. "defaults")
      pcall(dofile, vim.g.base46_cache .. "statusline")
    end
  end)
end

require "options"
require "autocmds"

vim.schedule(function()
  require "mappings"
  require "qol"
end)
require("md_preview").setup()
require("markab_todo").setup()
