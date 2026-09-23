-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  [MARKAB] BRUTALIST FUI THEME — TACTICAL TELEMETRY             ║
-- ║  LIGHT BACKGROUND / SHARP BORDERS / MONOCHROME + DATA ACCENTS  ║
-- ╚══════════════════════════════════════════════════════════════════╝

local M = {}

M.base_30 = {
  -- ── CHROME (UI elements — brutalist monochrome) ────────────────
  white = "#111111",           -- Primary text (inverted for light theme)
  darker_black = "#e8e8e8",    -- Deepest bg tone
  black = "#f4f4f4",           -- Main background
  black2 = "#ebebeb",          -- Statusline background
  one_bg = "#e0e0e0",          -- Lighter bg (selection)
  one_bg2 = "#d5d5d5",         -- Float borders
  one_bg3 = "#c8c8c8",         -- Scrollbar

  grey = "#888888",            -- Line numbers / muted elements
  grey_fg = "#777777",         -- Inactive text
  grey_fg2 = "#666666",        -- Dimmer text
  light_grey = "#555555",      -- Secondary text
  line = "#cccccc",            -- Indent guides / separators

  -- ── SYNTAX (Strict Brutalist Palette) ─────────────────────────
  -- Brutalism avoids the "rainbow" effect. Colors are reserved for data types.
  red = "#CC0000",             -- Alerts / Raw Numbers / Booleans
  baby_pink = "#CC0000",       
  pink = "#CC0000",            

  green = "#008800",           -- Strings / Valid Data
  vibrant_green = "#008800",   

  blue = "#0044CC",            -- Functions / Callables
  nord_blue = "#0044CC",       

  yellow = "#111111",          -- Types / Structs (Monochrome)
  sun = "#111111",             

  purple = "#000000",          -- Keywords / Control Flow (Pitch Black)
  dark_purple = "#000000",     

  teal = "#444444",            -- Support / Regex
  orange = "#CC0000",          -- Constants
  cyan = "#0044CC",            -- Built-ins

  -- ── UI ACCENTS ────────────────────────────────────────────────
  statusline_bg = "#ebebeb",   
  lightbg = "#e0e0e0",         
  pmenu_bg = "#0044CC",        -- Popup selection (Telemetry Blue)
  folder_bg = "#0044CC",       -- NvimTree folder accent
}

M.base_16 = {
  -- ── BACKGROUND SCALE ──────────────────────────────────────────
  base00 = "#f4f4f4",  -- Default Background
  base01 = "#ebebeb",  -- Lighter Background (statusline)
  base02 = "#e0e0e0",  -- Selection Background
  base03 = "#888888",  -- Comments (muted grey to fade into background)
  base04 = "#666666",  -- Dark Foreground (secondary content)
  base05 = "#111111",  -- Default Foreground (variables, properties)
  base06 = "#1a1a1a",  -- Light Foreground
  base07 = "#000000",  -- Brightest Foreground

  -- ── SYNTAX PALETTE (Reduced to Telemetry Essentials) ──────────
  base08 = "#111111",  -- Variables, XML tags (Monochrome)
  base09 = "#CC0000",  -- Integers, booleans, constants (Red = raw data)
  base0A = "#111111",  -- Classes, types (Monochrome)
  base0B = "#008800",  -- Strings (Green)
  base0C = "#444444",  -- Support, escape chars (Dark Grey)
  base0D = "#0044CC",  -- Functions, methods (Blue)
  base0E = "#000000",  -- Keywords, control flow (Pitch Black)
  base0F = "#CC0000",  -- Deprecated, special chars (Red)
}

M.type = "light"

-- ── TREESITTER POLISH (FUI-specific overrides) ──────────────────
M.polish_hl = {
  treesitter = {
    -- Operators and punctuation fade slightly to let code structure pop
    ["@operator"] = { fg = "#444444" },
    ["@punctuation.bracket"] = { fg = "#444444" },
    ["@punctuation.delimiter"] = { fg = "#444444" },
    
    -- Strict telemetry mapping
    ["@tag.delimiter"] = { fg = "#444444" },
    ["@tag.attribute"] = { fg = "#111111" },
    ["@constructor"] = { fg = "#0044CC", bold = true },
    ["@type.builtin"] = { fg = "#111111", bold = true },
    ["@function.builtin"] = { fg = "#0044CC" },
    
    -- Pitch black bold for core structural keywords
    ["@keyword"] = { fg = "#000000", bold = true },
    ["@keyword.import"] = { fg = "#000000", bold = true },
    ["@keyword.function"] = { fg = "#000000", bold = true },
    ["@keyword.return"] = { fg = "#CC0000", bold = true }, -- Red return to trace data flow
  },
}

return M
