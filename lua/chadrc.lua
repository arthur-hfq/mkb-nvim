-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  [MARKAB] CHADRC — BRUTALIST TELEMETRY NEOVIM CONFIG           ║
-- ║  FLAT GEOMETRY / SINGLE-PX BORDERS / NO ROUNDED AESTHETICS     ║
-- ╚══════════════════════════════════════════════════════════════════╝

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "markab",
  transparency = false,

  hl_override = {
    -- ── WINDOW BORDERS ─────────────────────────────────────────
    FloatBorder = { fg = "#111111", bg = "#f4f4f4" },
    NormalFloat = { bg = "#f4f4f4" },
    WinSeparator = { fg = "#a0a0a0", bg = "NONE" },

    -- ── STATUSLINE (flat telemetry bar) ────────────────────────
    StatusLine = { bg = "#ebebeb", fg = "#111111" },
    StatusLineNC = { bg = "#e0e0e0", fg = "#888888" },

    -- ── NVIMTREE (flat data buffer, no bubbly icons) ──────────
    NvimTreeNormal = { bg = "#f4f4f4", fg = "#111111" },
    NvimTreeWinSeparator = { fg = "#a0a0a0", bg = "#f4f4f4" },
    NvimTreeCursorLine = { bg = "#e0e0e0" },
    NvimTreeFolderIcon = { fg = "#0044CC" },
    NvimTreeFolderName = { fg = "#111111" },
    NvimTreeOpenedFolderName = { fg = "#0044CC" },
    NvimTreeRootName = { fg = "#0044CC", bold = true },
    NvimTreeIndentMarker = { fg = "#d5d5d5" },
    NvimTreeGitDirty = { fg = "#CC0000" },
    NvimTreeGitNew = { fg = "#008800" },

    -- ── TELESCOPE (sharp bordered panels) ─────────────────────
    TelescopeBorder = { fg = "#111111", bg = "#f4f4f4" },
    TelescopePromptBorder = { fg = "#111111", bg = "#f4f4f4" },
    TelescopeResultsBorder = { fg = "#111111", bg = "#f4f4f4" },
    TelescopePreviewBorder = { fg = "#111111", bg = "#f4f4f4" },
    TelescopeNormal = { bg = "#f4f4f4" },
    TelescopePromptNormal = { bg = "#f4f4f4" },
    TelescopeResultsNormal = { bg = "#f4f4f4" },
    TelescopePreviewNormal = { bg = "#f4f4f4" },
    TelescopeSelection = { bg = "#e0e0e0", fg = "#111111" },
    TelescopePromptPrefix = { fg = "#0044CC" },
    TelescopeTitle = { fg = "#0044CC", bold = true },

    -- ── BUFFERLINE / TABUFLINE (flat tabs, no rounding) ───────
    TbLineBufOn = { fg = "#111111", bg = "#f4f4f4", bold = true },
    TbLineBufOff = { fg = "#a0a0a0", bg = "#ebebeb" },
    TbLineBufOnModified = { fg = "#CC0000", bg = "#f4f4f4" },
    TbLineBufOffModified = { fg = "#CC0000", bg = "#ebebeb" },
    TbLineBufOnClose = { fg = "#a0a0a0", bg = "#f4f4f4" },
    TbLineBufOffClose = { fg = "#c8c8c8", bg = "#ebebeb" },
    TblineTabNewBtn = { fg = "#0044CC", bg = "#ebebeb" },
    TbLineFill = { bg = "#ebebeb" },
    TblineTabOn = { fg = "#111111", bg = "#f4f4f4", bold = true },
    TblineTabOff = { fg = "#a0a0a0", bg = "#ebebeb" },

    -- ── COMPLETION MENU ───────────────────────────────────────
    Pmenu = { bg = "#f4f4f4", fg = "#111111" },
    PmenuSel = { bg = "#0044CC", fg = "#f4f4f4" },
    PmenuSbar = { bg = "#e0e0e0" },
    PmenuThumb = { bg = "#a0a0a0" },
    CmpBorder = { fg = "#111111" },
    CmpDocBorder = { fg = "#111111" },

    -- ── CURSOR / LINE NUMBERS ────────────────────────────────
    CursorLine = { bg = "#ebebeb" },
    CursorColumn = { bg = "#ebebeb" },
    LineNr = { fg = "#a0a0a0" },
    CursorLineNr = { fg = "#0044CC", bold = true },

    -- ── CORE HIGHLIGHT GROUPS ────────────────────────────────
    Normal = { bg = "#f4f4f4", fg = "#111111" },
    Visual = { bg = "#d0d8ff" },
    Search = { bg = "#ffe066", fg = "#111111" },
    IncSearch = { bg = "#0044CC", fg = "#f4f4f4" },
    VertSplit = { fg = "#a0a0a0" },
    Comment = { fg = "#888888", italic = true },
    ["@comment"] = { fg = "#888888", italic = true },

    -- ── DIAGNOSTICS ──────────────────────────────────────────
    DiagnosticError = { fg = "#CC0000" },
    DiagnosticWarn = { fg = "#111111" },
    DiagnosticInfo = { fg = "#0044CC" },
    DiagnosticHint = { fg = "#008800" },
  },
}

M.ui = {
  telescope = { style = "bordered" },

  statusline = {
    separator_style = "block",
  },

  tabufline = {
    enabled = true,
  },

  cmp = {
    style = "default",
  },
}

-- ── FORCE SQUARE BORDERS (BRUTALIST — NO ROUNDED AESTHETICS) ────
vim.g.border_style = "single"


vim.diagnostic.config({ float = { border = "single" } })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    vim.keymap.set("n", "K", function() vim.lsp.buf.hover({ border = "single" }) end, { buffer = bufnr, desc = "LSP: Hover Info" })
    vim.keymap.set("n", "gK", function() vim.lsp.buf.signature_help({ border = "single" }) end, { buffer = bufnr, desc = "LSP: Signature Help" })
  end,
})

return M
