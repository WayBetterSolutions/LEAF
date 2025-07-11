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
   git clone <repository-url>
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

### Navigation
- `Arrow Keys` or `HJKL` - Navigate between notes
- `Enter` or `Space` - Open selected note
- `Tab` - Toggle between grid and list view
- `Home` / `End` - Jump to first/last note

### Note Management
- `Ctrl+N` - Create new note
- `Ctrl+S` - Save current note
- `Delete` - Delete selected note (with confirmation)
- `Ctrl+D` - Quick delete (no confirmation)
- `Escape` - Return to main view

### Search
- `Ctrl+F` - Open search
- `F3` - Find next match
- `Shift+F3` - Find previous match
- `Escape` - Clear search

### Collections
- `Ctrl+Shift+N` - Create new collection
- `Ctrl+Tab` - Next collection
- `Ctrl+Shift+Tab` - Previous collection
- `F2` - Rename collection
- `Ctrl+Shift+D` - Delete collection

### Customization
- `Ctrl+T` - Cycle themes forward
- `Ctrl+Shift+T` - Cycle themes backward
- `Ctrl++` / `Ctrl+-` - Adjust editor font size
- `Ctrl+9` / `Ctrl+0` - Adjust card font size
- `Ctrl+]` / `Ctrl+[` - Adjust card title font size
- `Ctrl+1` - Optimize card width for current window

### Other
- `Ctrl+Space` - Show statistics
- `F1` - Show help
- `Ctrl+W` - Toggle fullscreen
- `Ctrl+Q` - Quit application

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

All settings are stored in `config.json` and can be customized:
- Window dimensions
- Font family and sizes
- Keyboard shortcuts
- Auto-save intervals
- Current theme

## Contributing

Feel free to submit issues, feature requests, or pull requests to improve LEAF Notes.

## License

This project is open source. Feel free to use, modify, and distribute as needed.

---

**Happy note-taking with LEAF! 🍃**