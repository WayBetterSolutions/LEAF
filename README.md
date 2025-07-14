# LEAF

**Literature Environment & Archival Framework**

A fast note-taking application built with Python and Qt. Works with writers deck. Supports multiple collections, custom themes, and keyboard navigation.

## Installation

### Linux/Mac
```bash
git clone https://github.com/RobDeGeorge/LEAF.git && cd LEAF
python3 -m venv venv && source venv/bin/activate
pip install PySide6 && python main.py
```

### Windows
```bash
git clone https://github.com/RobDeGeorge/LEAF.git && cd LEAF
python3 -m venv venv && venv\Scripts\activate
pip install PySide6 && python main.py
```

## Keyboard Shortcuts

### Core Actions
- `Ctrl+N` - New note
- `Ctrl+S` - Save
- `Ctrl+F` - Search
- `Ctrl+Q` - Quit
- `F1` - Help
- `Escape` - Back/Cancel

### Navigation
- `Arrow Keys` or `H/J/K/L` - Navigate notes (vim-style)
- `Enter` or `Space` - Open note
- `Home/End` - First/last note
- `Page Up/Down` - Navigate pages
- `Tab` - Toggle grid/list view

### Note Management
- `Delete` - Delete note (with confirmation)
- `Y/Enter` - Confirm delete
- `N/Escape` - Cancel delete
- `Ctrl+D` - Quick delete

### Search
- `F3` - Find next
- `Shift+F3` - Find previous

### Collections
- `Ctrl+Shift+N` - New collection
- `Ctrl+Tab` - Next collection
- `Ctrl+Shift+Tab` - Previous collection
- `F2` - Rename collection
- `Ctrl+Shift+D` - Delete collection

### Themes & Fonts
- `Ctrl+T` - Cycle themes
- `Ctrl+Shift+T` - Theme dialog
- `Ctrl+Shift+E` - Theme editor
- `Ctrl+Alt+F` - Cycle fonts forward
- `Ctrl+Alt+Shift+F` - Cycle fonts backward
- `Ctrl+Shift+F` - Font dialog

### Display
- `Ctrl+W` - Fullscreen
- `Ctrl+1` - Optimize card width
- `Ctrl+Up/Down` - More/fewer columns
- `Ctrl+Shift+Up/Down` - Card height

### Font Sizes
- `Ctrl+=/-` - Editor font size
- `Ctrl+9/0` - Card font size
- `Ctrl+]/[` - Card title font size

### Editor
- `Ctrl+A/C/X/V/Z/Y` - Standard editing
- `Ctrl+Space` - Show statistics

## Themes

**13 Built-in Themes:**

### Night Owl
- Background: `#011627`
- Surface: `#1d3b53`
- Primary: `#c792ea`
- Text: `#d6deeb`
- Accent: `#7fdbca`

### Dracula
- Background: `#282a36`
- Surface: `#44475a`
- Primary: `#bd93f9`
- Text: `#f8f8f2`
- Accent: `#6272a4`

### Monokai
- Background: `#272822`
- Surface: `#3e3d32`
- Primary: `#f92672`
- Text: `#f8f8f2`
- Accent: `#75715e`

### GitHub Dark
- Background: `#0d1117`
- Surface: `#21262d`
- Primary: `#58a6ff`
- Text: `#f0f6fc`
- Accent: `#7d8590`

### Catppuccin
- Background: `#1e1e2e`
- Surface: `#313244`
- Primary: `#cba6f7`
- Text: `#cdd6f4`
- Accent: `#f9e2af`

### Tokyo Night
- Background: `#1a1b26`
- Surface: `#24283b`
- Primary: `#7aa2f7`
- Text: `#c0caf5`
- Accent: `#9ece6a`

### Nord Dark
- Background: `#2e3440`
- Surface: `#3b4252`
- Primary: `#88c0d0`
- Text: `#eceff4`
- Accent: `#d08770`

### Gruvbox Dark
- Background: `#282828`
- Surface: `#3c3836`
- Primary: `#83a598`
- Text: `#ebdbb2`
- Accent: `#fe8019`

### One Dark
- Background: `#1e2127`
- Surface: `#2c323c`
- Primary: `#61afef`
- Text: `#abb2bf`
- Accent: `#e06c75`

### Material Dark
- Background: `#121212`
- Surface: `#1e1e1e`
- Primary: `#bb86fc`
- Text: `#ffffff`
- Accent: `#03dac6`

### Ayu Dark
- Background: `#0a0e14`
- Surface: `#1f2430`
- Primary: `#ffb454`
- Text: `#b3b1ad`
- Accent: `#e6b450`

### Forest
- Background: `#1a2319`
- Surface: `#2d3b2c`
- Primary: `#7ec699`
- Text: `#e8f2e8`
- Accent: `#a8c9a8`

### Solarized Light
- Background: `#fdf6e3`
- Surface: `#eee8d5`
- Primary: `#268bd2`
- Text: `#586e75`
- Accent: `#93a1a1`