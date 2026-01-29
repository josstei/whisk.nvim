<h1 align="left">
  <img src="https://github.com/user-attachments/assets/546ee0e5-30fd-4e37-b219-e390be8b1c6e"
       alt="LuxVim Logo"
       style="width: 40px; height: 40px; position: relative; top: 6px; margin-right: 10px;" />
  nvim-luxmotion
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
    - Easing function (`linear`, `ease-out`, `ease-out-quad`)
    - Enable/disable individually
  - **Keymap control**:
    - Enable/disable default mappings
    - Define **custom mappings** for any motion
  - Easily toggle **performance mode** at runtime

- **Comprehensive Command & API Support**
  - Commands:
    - `:LuxMotionEnable` / `:LuxMotionDisable` / `:LuxMotionToggle`
    - `:LuxMotionPerformanceEnable` / `Disable` / `Toggle`
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

## 📦 Installation

### **Using lazy.nvim**
```lua
{
  "LuxVim/nvim-luxmotion",
  config = function()
    require("luxmotion").setup({
      cursor = {
        duration = 250,
        easing = "ease-out",
        enabled = true,
      },
      scroll = {
        duration = 400,
        easing = "ease-out",
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
  "LuxVim/nvim-luxmotion",
  config = function()
    require("luxmotion").setup()
  end
}
```

### **Using vim-plug**
```vim
Plug 'LuxVim/nvim-luxmotion'
```

Then in your `init.lua` or `init.vim`:
```lua
lua << EOF
require("luxmotion").setup()
EOF
```

---

## 🛠️ Configuration

```lua
require("luxmotion").setup({
  cursor = {
    duration = 250,       -- Cursor animation duration (ms)
    easing = "ease-out",  -- Cursor easing function
    enabled = true,
  },
  scroll = {
    duration = 400,       -- Scroll animation duration (ms)
    easing = "ease-out",  -- Scroll easing function
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
- `:LuxMotionEnable` – Enable all animations
- `:LuxMotionDisable` – Disable all animations
- `:LuxMotionToggle` – Toggle all animations

### **Individual Controls**
- `:LuxMotionEnableCursor` / `:LuxMotionDisableCursor`
- `:LuxMotionEnableScroll` / `:LuxMotionDisableScroll`

### **Performance Mode**
- `:LuxMotionPerformanceEnable`
- `:LuxMotionPerformanceDisable`
- `:LuxMotionPerformanceToggle`

---

## 🔧 Lua API

```lua
local luxmotion = require("luxmotion")

-- Global control
luxmotion.enable()
luxmotion.disable()
luxmotion.toggle()

-- Individual controls
luxmotion.enable_cursor()
luxmotion.disable_cursor()
luxmotion.enable_scroll()
luxmotion.disable_scroll()

-- Performance mode
local performance = require("luxmotion.performance")
performance.enable()
performance.disable()
performance.toggle()
performance.is_active()

-- Manual motion execution (for custom keymaps)
local orchestrator = require("luxmotion.engine.orchestrator")
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
require("luxmotion").setup({
  keymaps = {
    cursor = false,
    scroll = false,
  },
})

-- Define your own
local orchestrator = require("luxmotion.engine.orchestrator")
vim.keymap.set("n", "j", function()
  orchestrator.execute("basic_j", { count = vim.v.count1, direction = "j" })
end)
```

### **Different Speeds for Cursor vs Scroll**
```lua
require("luxmotion").setup({
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
require("luxmotion").setup({
  cursor = {
    duration = 150,
    easing = "linear",
  },
  performance = { enabled = true },
})
```

---

## 📈 Comparison

| Feature                  | luxmotion | neoscroll.nvim | vim-smoothie |
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
  - Enable performance mode: `:LuxMotionPerformanceEnable`
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
