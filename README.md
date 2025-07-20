<div align="center">
  <img src="assets/LEAFico.ico" width="128" height="128" alt="LEAF Icon">
</div>

# <img src="assets/LEAFico.ico" width="32" height="32" alt="LEAF Icon"> LEAF

**Literature Environment & Archival Framework**

test A novel and userfreindly keyboard-driven note-taking application designed for writers-- especially those wanting a simple distraction free space. Built with Python and Qt, L.E.A.F. integrates seamlessly with writer deck workflows, producing lightning-fast note capture, flexible organization and extensive customization.

**Key Features:**
- **Keyboard-First Design** - Navigate, edit, and organize with shortcuts
- **Collection-Based Organization** - Separate projects into distinct notebooks
- **Literary Analytics** - Word counts, reading time, dialogue detection, and vocabulary analysis
- **Advanced Theming** - 13 built-in themes plus visual theme editor
- **Dual View System** - Card/grid browsing and distraction-free editing modes
- **Real-time Search** - Instant filtering with regex support
- **Cross-Platform** - Works on Windows, macOS, and Linux

## Installation

### Linux/Mac
```bash
git clone https://github.com/RobDeGeorge/LEAF.git && cd LEAF
python3 -m venv venv && source venv/bin/activate
pip install PySide6 && python main.py
```

### Windows
```bash
git clone https://github.com/RobDeGeorge/LEAF.git
cd LEAF
python3 -m venv venv
venv\Scripts\activate
pip install PySide6
python main.py
```

## Configuration

On first run, LEAF automatically creates:
- `config/config.json` - Main application settings
- `data/collections.json` - Collection metadata
- `data/user_themes.json` - Theme definitions (13 built-in themes)
- `data/font_cache.json` - Font system cache


## Keyboard Shortcuts

### Core Actions
- `Ctrl+N` - New note
- `Ctrl+S` - Save
- `Ctrl+Alt+S` - Toggle auto-save
- `Ctrl+F` - Search
- `Ctrl+Q` - Quit
- `F1` - Help
- `Escape` - Back/Cancel
- `Ctrl+Space` - Show statistics

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
- `Ctrl+1` - Auto-optimize layout
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

LEAF includes **13 carefully crafted themes** including Night Owl, Dracula, Monokai, GitHub Dark, Catppuccin, Tokyo Night, Nord Dark, Gruvbox Dark, One Dark, Material Dark, Ayu Dark, Forest, and Solarized Light. Each theme provides a complete color palette optimized for long writing sessions.

Use the built-in **visual theme editor** (`Ctrl+Shift+E`) to create and customize your own themes, or cycle through existing themes with `Ctrl+T`.