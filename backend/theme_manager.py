from PySide6.QtCore import Signal, Slot, Property
from .base_manager import BaseManager


class ThemeManager(BaseManager):
    """Manages application themes"""
    
    def __init__(self, config_manager):
        super().__init__()
        self.config_manager = config_manager
        self.user_themes_file = "data/user_themes.json"
        
        # Initialize themes
        self.ensure_directory_exists("data")
        self._ensure_user_themes_exist()
    
    def get_builtin_themes(self):
        """Get the original builtin themes defined in code"""
        return {
            "nightOwl": {
                "name": "Night Owl",
                "background": "#011627",
                "surface": "#1d3b53",
                "primary": "#c792ea",
                "primaryText": "#d6deeb",
                "secondaryText": "#7fdbca",
                "success": "#addb67",
                "warning": "#ffcb6b",
                "error": "#ef5350"
            },
            "dracula": {
                "name": "Dracula",
                "background": "#282a36",
                "surface": "#44475a",
                "primary": "#bd93f9",
                "primaryText": "#f8f8f2",
                "secondaryText": "#6272a4",
                "success": "#50fa7b",
                "warning": "#f1fa8c",
                "error": "#ff5555"
            },
            "monokai": {
                "name": "Monokai",
                "background": "#272822",
                "surface": "#3e3d32",
                "primary": "#f92672",
                "primaryText": "#f8f8f2",
                "secondaryText": "#75715e",
                "success": "#a6e22e",
                "warning": "#e6db74",
                "error": "#f92672"
            },
            "githubDark": {
                "name": "GitHub Dark",
                "background": "#0d1117",
                "surface": "#21262d",
                "primary": "#58a6ff",
                "primaryText": "#f0f6fc",
                "secondaryText": "#7d8590",
                "success": "#238636",
                "warning": "#d29922",
                "error": "#f85149"
            },
            "catppuccin": {
                "name": "Catppuccin",
                "background": "#1e1e2e",
                "surface": "#313244",
                "primary": "#cba6f7",
                "primaryText": "#cdd6f4",
                "secondaryText": "#f9e2af",
                "success": "#a6e3a1",
                "warning": "#fab387",
                "error": "#f38ba8"
            },
            "tokyoNight": {
                "name": "Tokyo Night",
                "background": "#1a1b26",
                "surface": "#24283b",
                "primary": "#7aa2f7",
                "primaryText": "#c0caf5",
                "secondaryText": "#9ece6a",
                "success": "#9ece6a",
                "warning": "#e0af68",
                "error": "#f7768e"
            },
            "nordDark": {
                "name": "Nord Dark",
                "background": "#2e3440",
                "surface": "#3b4252",
                "primary": "#88c0d0",
                "primaryText": "#eceff4",
                "secondaryText": "#d08770",
                "success": "#a3be8c",
                "warning": "#ebcb8b",
                "error": "#bf616a"
            },
            "gruvboxDark": {
                "name": "Gruvbox Dark",
                "background": "#282828",
                "surface": "#3c3836",
                "primary": "#83a598",
                "primaryText": "#ebdbb2",
                "secondaryText": "#fe8019",
                "success": "#b8bb26",
                "warning": "#fabd2f",
                "error": "#fb4934"
            },
            "oneDark": {
                "name": "One Dark",
                "background": "#1e2127",
                "surface": "#2c323c",
                "primary": "#61afef",
                "primaryText": "#abb2bf",
                "secondaryText": "#e06c75",
                "success": "#98c379",
                "warning": "#e5c07b",
                "error": "#e06c75"
            },
            "materialDark": {
                "name": "Material Dark",
                "background": "#121212",
                "surface": "#1e1e1e",
                "primary": "#bb86fc",
                "primaryText": "#ffffff",
                "secondaryText": "#03dac6",
                "success": "#4caf50",
                "warning": "#ff9800",
                "error": "#f44336"
            },
            "ayuDark": {
                "name": "Ayu Dark",
                "background": "#0a0e14",
                "surface": "#1f2430",
                "primary": "#ffb454",
                "primaryText": "#b3b1ad",
                "secondaryText": "#e6b450",
                "success": "#c2d94c",
                "warning": "#ffb454",
                "error": "#f07178"
            },
            "forest": {
                "name": "Forest",
                "background": "#1a2319",
                "surface": "#2d3b2c",
                "primary": "#7ec699",
                "primaryText": "#e8f2e8",
                "secondaryText": "#a8c9a8",
                "success": "#90d4a0",
                "warning": "#d4b85a",
                "error": "#d97a7a"
            },
            "solarizedLight": {
                "name": "Solarized Light",
                "background": "#fdf6e3",
                "surface": "#eee8d5",
                "primary": "#268bd2",
                "primaryText": "#586e75",
                "secondaryText": "#93a1a1",
                "success": "#859900",
                "warning": "#b58900",
                "error": "#dc322f"
            }
        }

    def _ensure_user_themes_exist(self):
        """Ensure user themes file exists, create from builtins if needed"""
        if not self.read_json_file(self.user_themes_file):
            builtin_themes = self.get_builtin_themes()
            self.atomic_write_json(builtin_themes, self.user_themes_file)

    def load_user_themes(self):
        """Load user themes, initializing from builtin themes if needed"""
        themes = self.read_json_file(self.user_themes_file)
        if not themes:
            # If user themes file is corrupted or missing, recreate from builtins
            themes = self.get_builtin_themes()
            self.atomic_write_json(themes, self.user_themes_file)
        return themes

    def save_user_themes(self, themes):
        """Save user themes to file"""
        return self.atomic_write_json(themes, self.user_themes_file)

    # QML-accessible methods
    @Slot(str)
    def setTheme(self, theme_name):
        self.config_manager.set_value("currentTheme", theme_name)

    @Slot(result=str)
    def getCurrentTheme(self):
        return self.config_manager.get_value("currentTheme", "githubDark")

    @Slot(result=list)
    def getAvailableThemes(self):
        """Get list of available theme keys"""
        themes = self.load_user_themes()
        return list(themes.keys())

    @Slot(result='QVariant')
    def getAllThemes(self):
        """Get all themes with their data"""
        return self.load_user_themes()

    @Slot(str, result='QVariant')
    def getTheme(self, theme_key):
        """Get a specific theme by key"""
        themes = self.load_user_themes()
        return themes.get(theme_key, {})

    @Slot(str, str, str, str, str, str, str, str, str, str, result=bool)
    def createTheme(self, key, name, background, surface, primary, primaryText, secondaryText, success, warning, error):
        """Create a new theme"""
        if not key or not name:
            return False
            
        themes = self.load_user_themes()
        themes[key] = {
            "name": name,
            "background": background,
            "surface": surface,
            "primary": primary,
            "primaryText": primaryText,
            "secondaryText": secondaryText,
            "success": success,
            "warning": warning,
            "error": error
        }
        return self.save_user_themes(themes)

    @Slot(str, str, str, str, str, str, str, str, str, str, result=bool)
    def updateTheme(self, key, name, background, surface, primary, primaryText, secondaryText, success, warning, error):
        """Update an existing theme"""
        if not key:
            return False
            
        themes = self.load_user_themes()
        if key not in themes:
            return False
            
        themes[key] = {
            "name": name,
            "background": background,
            "surface": surface,
            "primary": primary,
            "primaryText": primaryText,
            "secondaryText": secondaryText,
            "success": success,
            "warning": warning,
            "error": error
        }
        return self.save_user_themes(themes)

    @Slot(str, result=bool)
    def deleteTheme(self, key):
        """Delete a theme"""
        if not key:
            return False
            
        themes = self.load_user_themes()
        if key not in themes:
            return False
            
        # Don't allow deleting the current theme
        if key == self.getCurrentTheme():
            return False
            
        del themes[key]
        return self.save_user_themes(themes)

    @Slot(str, str, result=bool)
    def renameTheme(self, key, new_name):
        """Rename a theme"""
        if not key or not new_name:
            return False
            
        themes = self.load_user_themes()
        if key not in themes:
            return False
            
        themes[key]["name"] = new_name
        return self.save_user_themes(themes)