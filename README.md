<h1 align="left">
  <img src="https://github.com/user-attachments/assets/546ee0e5-30fd-4e37-b219-e390be8b1c6e"
       alt="LuxVim Logo"
       style="width: 40px; height: 40px; position: relative; top: 6px; margin-right: 10px;" />
  whisk.nvim
</h1>

A comprehensive **Neovim smooth motion plugin**, providing **fluid animations for all motion commands**.
Combines smooth **cursor movement**, **word navigation**, **text objects**, and **viewport scrolling** into one seamless experience.

---

## ✨ Features

- **Smooth Animations**
  - 60fps fluid animations for **all Vim motion commands**
  - Unified smooth **cursor movement** and **viewport scrolling**
  - Works in **Normal** and **Visual** modes with **count prefixes**

- **Extensive Movement Coverage**
  - **Basic**: `h`, `j`, `k`, `l`, `0`, `$`
  - **Word Navigation**: `w`, `b`, `e`, `W`, `B`, `E`
  - **Find/Till**: `f`, `F`, `t`, `T` (supports counts)
  - **Text Objects**: `{`, `}`, `(`, `)`, `%`
  - **Line Jumps**: `gg`, `G`, `|`
  - **Search Navigation**: `n`, `N`
  - **Screen Lines**: `gj`, `gk`
  - **Viewport Scrolling**: `<C-d>`, `<C-u>`, `<C-f>`, `<C-b>`, `zz`, `zt`, `zb`

- **Performance & Optimization**
  - Object pooling and **frame reuse** to reduce garbage collection
  - **API call caching** (50ms window) for efficient redraws
  - Optimized for **smooth 60fps animations**
  - **Performance Mode** for faster but less smooth rendering:
    - Reduces animation duration and easing complexity
    - Optional syntax highlighting toggle for large files

- **Flexible Configuration**
  - Separate settings for **cursor** and **scroll** animations:
    - Duration (ms)
    - Easing function (`linear`, `ease-in`, `ease-out`, `ease-in-out`)
    - Enable/disable individually
  - **Keymap control**:
    - Enable/disable default mappings
    - Define **custom mappings** for any motion
  - Easily toggle **performance mode** at runtime

- **Comprehensive Command & API Support**
  - Commands:
    - `:WhiskEnable` / `:WhiskDisable` / `:WhiskToggle`
    - `:WhiskPerformanceEnable` / `Disable` / `Toggle`
  - Lua API:
    - Enable/disable cursor and scroll animations
    - Toggle performance mode
    - Trigger **manual smooth motions** for custom keymaps

- **Customization & Extensibility**
  - Different speeds and easing curves for cursor vs scrolling
  - Integrate with **custom motions** or other keymaps
  - Visual mode motions supported **out-of-the-box**

- **Compatibility**
  - Neovim **≥ 0.7**
  - Designed to **coexist with other scroll/motion plugins** (disable keymaps if needed)

---

## Documentation

- [Usage](docs/USAGE.md)
- [Architecture](docs/ARCHITECTURE.md)

---

## 📦 Installation

### **Using lazy.nvim**
```lua
{
  "josstei/whisk.nvim",
  config = function()
    require("whisk").setup({
      cursor = {
        duration = 150,
        easing = "ease-out",
        enabled = true,
      },
      scroll = {
        duration = 240,
        easing = "ease-in-out",
        enabled = true,
      },
      performance = { enabled = false },
      keymaps = {
        cursor = true,
        scroll = true,
      },
    })
  end,
}
```

### **Using packer.nvim**
```lua
use {
  "josstei/whisk.nvim",
  config = function()
    require("whisk").setup()
  end
}
```

### **Using vim-plug**
```vim
Plug 'josstei/whisk.nvim'
```

Then in your `init.lua` or `init.vim`:
```lua
lua << EOF
require("whisk").setup()
EOF
```

---

## 🛠️ Configuration

```lua
require("whisk").setup({
  cursor = {
    duration = 150,       -- Cursor animation duration (ms)
    easing = "ease-out",  -- Cursor easing function
    enabled = true,
  },
  scroll = {
    duration = 240,       -- Scroll animation duration (ms)
    easing = "ease-in-out",  -- Scroll easing function
    enabled = true,
  },
  performance = {
    enabled = false,      -- Enable performance mode
  },
  keymaps = {
    cursor = true,        -- Enable cursor motion keymaps
    scroll = true,        -- Enable scroll motion keymaps
  },
})
```

---

## 🎮 Commands

### **Global Controls**
- `:WhiskEnable` – Enable all animations
- `:WhiskDisable` – Disable all animations
- `:WhiskToggle` – Toggle all animations

### **Individual Controls**
- `:WhiskEnableCursor` / `:WhiskDisableCursor`
- `:WhiskEnableScroll` / `:WhiskDisableScroll`

### **Performance Mode**
- `:WhiskPerformanceEnable`
- `:WhiskPerformanceDisable`
- `:WhiskPerformanceToggle`

---

## 🔧 Lua API

```lua
local whisk = require("whisk")

-- Global control
whisk.enable()
whisk.disable()
whisk.toggle()

-- Individual controls
whisk.enable_cursor()
whisk.disable_cursor()
whisk.enable_scroll()
whisk.disable_scroll()

-- Performance mode
local performance = require("whisk.performance")
performance.enable()
performance.disable()
performance.toggle()
performance.is_active()

-- Manual motion execution (for custom keymaps)
local orchestrator = require("whisk.engine.orchestrator")
orchestrator.execute("basic_j", { count = 5, direction = "j" })
orchestrator.execute("word_w", { count = 3, direction = "w" })
orchestrator.execute("find_f", { char = "x", count = 2, direction = "f" })
orchestrator.execute("text_object_}", { count = 1, direction = "}" })
```

### Available Motion IDs

| Category | Motion IDs |
|----------|------------|
| Basic | `basic_h`, `basic_j`, `basic_k`, `basic_l`, `basic_0`, `basic_$` |
| Word | `word_w`, `word_b`, `word_e`, `word_W`, `word_B`, `word_E` |
| Find | `find_f`, `find_F`, `find_t`, `find_T` |
| Text Object | `text_object_{`, `text_object_}`, `text_object_(`, `text_object_)`, `text_object_%` |
| Line | `line_gg`, `line_G`, `line_\|` |
| Search | `search_n`, `search_N`, `screen_gj`, `screen_gk` |
| Scroll | `scroll_ctrl_d`, `scroll_ctrl_u`, `scroll_ctrl_f`, `scroll_ctrl_b`, `position_zz`, `position_zt`, `position_zb` |

---

## 🎨 Customization Examples

### **Disable Default Keymaps**
```lua
require("whisk").setup({
  keymaps = {
    cursor = false,
    scroll = false,
  },
})

-- Define your own
local orchestrator = require("whisk.engine.orchestrator")
vim.keymap.set("n", "j", function()
  orchestrator.execute("basic_j", { count = vim.v.count1, direction = "j" })
end)
```

### **Different Speeds for Cursor vs Scroll**
```lua
require("whisk").setup({
  cursor = {
    duration = 100,
    easing = "linear",
  },
  scroll = {
    duration = 500,
    easing = "ease-out",
  },
})
```

### **Performance-Oriented Setup**
```lua
require("whisk").setup({
  cursor = {
    duration = 150,
    easing = "linear",
  },
  performance = { enabled = true },
})
```

---

## 📈 Comparison

| Feature                  | whisk | neoscroll.nvim | vim-smoothie |
|--------------------------|----------|----------------|--------------|
| Cursor Movement          | ✅       | ❌              | ❌           |
| Scroll Movement          | ✅       | ✅              | ✅           |
| Word Navigation          | ✅       | ❌              | ❌           |
| Find/Till Support        | ✅       | ❌              | ❌           |
| Text Objects             | ✅       | ❌              | ❌           |
| Search Navigation        | ✅       | ❌              | ❌           |
| Visual Mode              | ✅       | ✅ (scroll)     | ✅ (scroll)  |
| Count Prefixes           | ✅       | ✅ (scroll)     | ✅ (scroll)  |

---

## 🐛 Troubleshooting

- **Performance Issues**
  - Enable performance mode: `:WhiskPerformanceEnable`
  - Reduce animation duration: `cursor = { duration = 100 }`
  - Use `linear` easing for fastest performance
- **Conflicts**
  - Disable default keymaps: `keymaps = { cursor = false }`
  - Set your own mappings manually
- **Animations Not Smooth**
  - Ensure terminal supports **true colors**
  - Use Neovim **≥ 0.7**
  - Lower `scrolloff` for large jumps

---

## 🙏 Acknowledgments

Inspired by [vim-smoothie](https://github.com/psliwka/vim-smoothie) and  [neoscroll.nvim](https://github.com/karb94/neoscroll.nvim).

---

## 📄 License

MIT License – see [LICENSE](LICENSE) for details.
