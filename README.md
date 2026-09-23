# Markab Brutalist Neovim IDE

> **Minimalist, High-Contrast Brutalist Neovim Configuration with Integrated Developer Tooling**

```
╔══════════════════════════════════════════════════════════════╗
║  [MARKAB] TELEMETRY DEVELOPMENT ENVIRONMENT                  ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  • UI: Absolute Brutalism (1px borders, #f4f4f4 / #111111)   ║
║  • Engine: Neovim 0.10+ / NvChad Core v2.5 / Lazy.nvim       ║
║  • Tooling: Built-in Code Runner, Docker Stress Engine,      ║
║             HTTP Client, Database UI, AGY AI, Project TODOs  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

This repository contains my personal, battle-tested Neovim configuration built around a strict **Brutalist Telemetry** aesthetic. It rejects rounded corners, animations, and pastel bloat in favor of sharp 1-pixel borders, instantaneous response times (`timeoutlen = 250`), high-contrast ink-on-paper readability, and deep integration with local Docker infrastructure and system tools.

---

## ⚡ Core Highlights & Custom Modules

### 1. Markab Tools (`lua/markab_tools.lua`)
- **Asynchronous Code Runner**:
  - `<leader>rr`: Runs the current file asynchronously inside a brutalist floating buffer.
  - `<leader>rs`: Runs visual selection.
  - `<leader>rn`: Opens an instant scratch pad runner.
- **Docker-Isolated API Stress Engine**:
  - `<leader>st`: Spawns a dedicated Docker container with custom CPU and RAM limits, boots your backend server, generates concurrent traffic, and live-streams response codes, latency percentiles, and normalized CPU load.
- **Built-in HTTP Client**:
  - `<leader>hn`: Opens or creates a `.http` request file.
  - `<leader>hr`: Executes the HTTP request under the cursor via `curl` and formats the JSON response with `jq`.
- **Database Query Hub**:
  - `<leader>du`: Toggles Dadbod UI.
  - `<leader>dc`: Quick-connects to local/Docker database instances.
  - `<leader>dq`: Runs one-shot SQL queries with instant results.

### 2. Markab Todo (`lua/markab_todo.lua`)
- Floating project task manager (`<leader>tt`).
- Persists tasks to a local project JSON file.
- Toggle task status, add new tasks, and navigate back to code with a single keystroke.

### 3. AGY AI Integration (`lua/agy_integration.lua`)
- Native Neovim bindings for Antigravity AI:
  - `<leader>ai`: Generate code at cursor based on contextual prompt.
  - `<leader>as`: Refactor / improve selected code block.
  - `<leader>au`: Generate isolated unit tests for current function.
  - `<leader>cg`: Pro file generator.

### 4. Markdown Preview (`lua/md_preview.lua`)
- Instant in-terminal and browser previewing for Markdown documentation and RFCs.

### 5. Quality of Life (`lua/qol.lua`)
- Automatic project root detection.
- Subtle yank highlight feedback.
- Brutalist statusline and tabufline overrides.

---

## ⌨️ Keybinding Reference

Leader key is mapped to `<Space>`.

### General & Navigation
| Keybinding | Action |
| :--- | :--- |
| `<leader>w` | Save current file |
| `<leader>q` | Quit current window |
| `<leader>e` | Toggle NvimTree file explorer |
| `<leader>sv` | Split window vertically |
| `<leader>sh` | Split window horizontally |
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | Navigate between split windows |
| `<Tab>` / `<S-Tab>` | Cycle next / previous buffer |
| `<C-d>` / `<C-u>` | Half-page jump with cursor centering |
| `v` + `J` / `K` | Move selected lines down / up |

### Markab Developer Tools
| Keybinding | Action |
| :--- | :--- |
| `<leader>rr` | Run current file asynchronously |
| `<leader>rs` | Run visual selection |
| `<leader>rn` | Open scratch pad code runner |
| `<leader>st` | Docker API Load & Stress test engine |
| `<leader>hn` | New HTTP request scratch buffer |
| `<leader>hr` | Execute HTTP request under cursor |
| `<leader>du` | Toggle Database UI (`vim-dadbod-ui`) |
| `<leader>dc` | Database Quick Connect |
| `<leader>dq` | Database Quick Query |
| `<leader>tt` | Toggle Project TODO Manager |

### Testing & Quality (`neotest`)
| Keybinding | Action |
| :--- | :--- |
| `<leader>tf` | Run tests in current file |
| `<leader>tn` | Run nearest test |
| `<leader>to` | Show test output panel |
| `<leader>ts` | Toggle test summary tree |

### AI Assistant (Antigravity AGY)
| Keybinding | Action |
| :--- | :--- |
| `<leader>ai` | Generate code at cursor |
| `<leader>as` | Suggest improvements on selection |
| `<leader>au` | Generate isolated unit tests |
| `<leader>cg` | Generate complete file |

---

## 📦 Requirements

- **Neovim** >= 0.10.0
- **Nerd Font**: JetBrains Mono Nerd Font or Monaspace Krypton Nerd Font
- **ripgrep** (`rg`) & **fd** (for Telescope fuzzy search)
- **curl** & **jq** (for HTTP client and API stress runner)
- **Docker** (for `<leader>st` isolated container benchmarks)
- **Tree-sitter CLI** & standard build tools (`gcc`, `make`)

---

## 🚀 Installation

```bash
# 1. Back up existing configuration (if any)
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak

# 2. Clone this repository
git clone https://github.com/<your-username>/nvim.git ~/.config/nvim

# 3. Open Neovim (plugins and tree-sitter parsers will install automatically)
nvim
```

Run `:checkhealth` inside Neovim to verify LSP servers, formatters, and clipboard integrations.

---

## 🎨 Theme & Typography

- **Theme**: `markab` (Bespoke high-contrast light theme with `#f4f4f4` base, `#111111` text, `#0044cc` electric blue accents, and sharp borders).
- Alternate retro themes available in `lua/themes/`.
- Switch themes anytime with `:NvChadUpdate` or by editing `lua/chadrc.lua`.

---

## 📄 License

This configuration is open source under the [MIT License](LICENSE).
