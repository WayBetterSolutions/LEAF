# LEAF Notes
## Literature Environment & Archival Framework

A clean, fast, and customizable note-taking application built with Python and Qt. LEAF provides a comprehensive environment for writing, organizing, and archiving your literary works and notes with multiple collections, powerful theming, and intuitive keyboard navigation.

## Features

- **Multiple Collections**: Organize your notes into separate collections
- **Beautiful Themes**: 13+ built-in themes including Tokyo Night, Dracula, GitHub Dark, and more
- **Theme Cycling**: Quickly switch between themes with `Ctrl+T`
- **Powerful Search**: Real-time search across all notes with regex support
- **Keyboard Navigation**: Full keyboard control with vim-inspired shortcuts
- **Auto-save**: Never lose your work with automatic saving
- **Grid and List Views**: Choose your preferred viewing mode
- **Font Customization**: Adjust fonts and sizes to your preference
- **Statistics**: Detailed writing statistics and metrics
- **Clean Interface**: Distraction-free writing environment

## Installation

### Prerequisites
- Python 3.8 or higher
- pip (Python package installer)

### Setup

1. **Clone or download this repository**
   ```bash
   git clone https://github.com/RobDeGeorge/LEAF.git
   cd LEAF
   ```

2. **Create a virtual environment**
   ```bash
   python -m venv venv
   ```

3. **Activate the virtual environment**
   
   On Linux/Mac:
   ```bash
   source venv/bin/activate
   ```
   
   On Windows:
   ```bash
   venv\Scripts\activate
   ```

4. **Install dependencies**
   ```bash
   pip install PySide6
   ```

5. **Run the application**
   ```bash
   python main.py
   ```

## Quick Start

1. **First Launch**: You'll be prompted to create your first collection
2. **Create Notes**: Press `Ctrl+N` to create a new note
3. **Navigate**: Use arrow keys or vim keys (`h`, `j`, `k`, `l`) to navigate
4. **Search**: Press `Ctrl+F` to search your notes
5. **Switch Themes**: Press `Ctrl+T` to cycle through themes

## Keyboard Shortcuts

### Basic Actions
- `Ctrl+N` - Create new note
- `Ctrl+S` - Save current note
- `Ctrl+F` - Search notes
- `Escape` - Back/Cancel
- `F1` - Show help dialog
- `Ctrl+Q` - Quit application

### Navigation
- `Arrow Keys` or `H/J/K/L` - Navigate between notes (vim-style)
- `Enter` or `Space` - Open selected note
- `Home` / `End` - Jump to first/last note
- `Page Up` / `Page Down` - Navigate by pages
- `Tab` - Toggle between grid and list view

### Note Management
- `Delete` - Delete selected note (with confirmation)
  - `Y` or `Enter` - Confirm delete
  - `N` or `Escape` - Cancel delete
- `Ctrl+D` - Quick delete (no confirmation)

### Search
- `Ctrl+F` - Open search mode
- `F3` - Find next match
- `Shift+F3` - Find previous match
- `Escape` - Exit search mode

### Collections
- `Ctrl+Shift+N` - Create new collection
- `Ctrl+Tab` - Next collection
- `Ctrl+Shift+Tab` - Previous collection
- `F2` - Rename current collection
- `Ctrl+Shift+D` - Delete current collection

### Theming
- `Ctrl+T` - Cycle themes forward
- `Ctrl+Shift+T` - Cycle themes backward

### Display & Layout
- `Ctrl+W` - Toggle fullscreen
- `Ctrl+1` - Auto-optimize card width
- `Ctrl+Up` - More columns (narrower cards)
- `Ctrl+Down` - Fewer columns (wider cards)
- `Ctrl+Shift+Right` - Increase card width
- `Ctrl+Shift+Left` - Decrease card width
- `Ctrl+Shift+Up` - Decrease card height
- `Ctrl+Shift+Down` - Increase card height

### Font Sizes
- `Ctrl+=` / `Ctrl+-` - Adjust editor font size
- `Ctrl+9` / `Ctrl+0` - Adjust card font size
- `Ctrl+]` / `Ctrl+[` - Adjust card title font size

### Editor Actions (in note editing mode)
- `Ctrl+A` - Select all
- `Ctrl+C` - Copy
- `Ctrl+X` - Cut
- `Ctrl+V` - Paste
- `Ctrl+Z` - Undo
- `Ctrl+Y` - Redo

### Statistics
- `Ctrl+Space` - Show writing statistics

> **Note**: Press `F1` anytime to see a complete help dialog with all shortcuts!

## Themes

LEAF comes with 13 beautiful themes:
- Night Owl
- Dracula
- Monokai
- GitHub Dark
- Solarized Light
- Catppuccin
- Tokyo Night
- Nord Dark
- Gruvbox Dark
- One Dark
- Material Dark
- Ayu Dark
- Forest

Switch between them instantly with `Ctrl+T` or `Ctrl+Shift+T`.

## File Structure

- `collections/` - Contains your note collections as JSON files
- `config.json` - Application settings and preferences
- `collections.json` - Collection metadata

## Configuration

LEAF stores all settings in `config.json` and collection data in `collections.json`. These files are automatically created and can be customized.

### config.json Settings

The main configuration file contains:

#### **Appearance**
- `currentTheme` - Active theme name (e.g., "ayuDark", "tokyoNight")
- `fontFamily` - Font for the application (e.g., "Victor Mono", "JetBrains Mono")
- `fontSize` - Editor font size (default: 45)
- `cardFontSize` - Font size for note cards (default: 17)
- `cardTitleFontSize` - Font size for card titles (default: 17)
- `headerFontSize` - Font size for headers (default: 26)

#### **Layout**
- `windowWidth` / `windowHeight` - Application window size
- `cardWidth` / `cardHeight` - Default card dimensions
- Each collection can override these in `collections.json`

#### **Behavior**
- `maxUnsavedChanges` - Auto-save threshold (default: 50)
- `autoSaveInterval` - Auto-save frequency in ms (default: 1000)
- `searchDebounceInterval` - Search delay in ms (default: 300)

#### **Keyboard Shortcuts**
All shortcuts are customizable in the `shortcuts` section:
```json
"shortcuts": {
  "newNote": "Ctrl+N",
  "save": "Ctrl+S",
  "search": "Ctrl+F",
  "help": "F1",
  "quit": "Ctrl+Q"
  // ... and many more
}
```

#### **Colors**
Extensive color customization for themes:
- `backgroundColor`, `cardColor`, `textColor`
- `accentColor`, `hoverColor`, `borderColor`
- `helpDialogBackgroundColor`, `helpDialogTextColor`
- And many more theme-specific colors

### collections.json Structure

Collection metadata and per-collection settings:
```json
{
  "collections": ["Notes", "Work", "Personal"],
  "currentCollection": "Notes",
  "collectionSettings": {
    "Notes": {
      "cardWidth": 782,
      "cardHeight": 700
    }
  }
}
```

### Customization Tips

1. **Change Shortcuts**: Edit the `shortcuts` section in `config.json`
2. **Adjust Layout**: Modify `cardWidth`, `cardHeight` for default sizes
3. **Set Fonts**: Change `fontFamily` to any installed system font
4. **Theme Colors**: Customize any color value in the theme section
5. **Auto-save**: Adjust `autoSaveInterval` (lower = more frequent saves)

> **Backup**: LEAF automatically creates backups when modifying config files

## Contributing

Feel free to submit issues, feature requests, or pull requests to improve LEAF Notes.

## License

This project is open source. Feel free to use, modify, and distribute as needed.

---

**Happy note-taking with LEAF! 🍃**