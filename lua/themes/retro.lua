-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  [MARKAB] TELEMETRY — NEOVIM BRUTALIST LIGHT THEME             ║
-- ║  STRICT GEOMETRY / NO TRANSPARENCY / 1PX BORDERS               ║
-- ╚══════════════════════════════════════════════════════════════════╝

local M = {}

M.base_30 = {
  white = "#111111",
  darker_black = "#e8e8e8",
  black = "#f4f4f4",         -- Main background
  black2 = "#ebebeb",        -- Statusline bg
  one_bg = "#e0e0e0",        -- Selection bg
  one_bg2 = "#d5d5d5",
  one_bg3 = "#c8c8c8",

  grey = "#888888",           -- Line numbers
  grey_fg = "#777777",
  grey_fg2 = "#666666",
  light_grey = "#555555",

  red = "#cc0000",
  baby_pink = "#d44950",
  pink = "#c93040",
  line = "#d5d5d5",           -- Indent guides
  green = "#007744",
  vibrant_green = "#00aa55",
  nord_blue = "#003399",
  blue = "#0055ff",           -- Accent blue
  yellow = "#aa6600",
  sun = "#bb7700",
  purple = "#6633aa",
  dark_purple = "#552299",
  teal = "#007766",
  orange = "#cc5500",
  cyan = "#006688",

  statusline_bg = "#ebebeb",
  lightbg = "#e0e0e0",
  pmenu_bg = "#0055ff",       -- Popup menu selected
  folder_bg = "#0055ff",      -- NvimTree folder icon
}

M.base_16 = {
  base00 = "#f4f4f4",  -- Default Background
  base01 = "#ebebeb",  -- Lighter Background (statusline)
  base02 = "#e0e0e0",  -- Selection Background
  base03 = "#888888",  -- Comments
  base04 = "#666666",  -- Dark Foreground (secondary)
  base05 = "#111111",  -- Default Foreground
  base06 = "#222222",  -- Light Foreground
  base07 = "#000000",  -- Brightest Foreground

  -- Syntax
  base08 = "#cc0000",  -- Variables (red)
  base09 = "#cc5500",  -- Numbers (orange)
  base0A = "#aa6600",  -- Classes (yellow-brown)
  base0B = "#007744",  -- Strings (green)
  base0C = "#006688",  -- Regex/Support (cyan)
  base0D = "#0055ff",  -- Functions (blue accent)
  base0E = "#6633aa",  -- Keywords (purple)
  base0F = "#cc0000",  -- Special chars (red)
}

M.type = "light"

return M
