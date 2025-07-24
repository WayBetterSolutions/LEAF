from PySide6.QtCore import Signal, Slot, Property
from .base_manager import BaseManager


class ConfigManager(BaseManager):
    """Manages application configuration"""
    
    configChanged = Signal()
    
    def __init__(self):
        super().__init__()
        self.config_file = "config/config.json"
        self._config = {}
        self.load_config()
    
    def get_default_config(self):
        """Get default configuration values"""
        return {
            "fontFamily": "Victor Mono",
            "fontSize": 34,
            "cardFontSize": 29,
            "cardTitleFontSize": 22,
            "headerFontSize": 26,
            "cardWidth": 480,
            "cardHeight": 400,
            "windowWidth": 613,
            "windowHeight": 1369,
            "maxUnsavedChanges": 50,
            "autoSaveInterval": 1000,
            "autoSaveEnabled": True,
            "searchDebounceInterval": 300,
            "currentTheme": "githubDark",
            "shortcuts": {
                "newNote": "Ctrl+N",
                "save": "Ctrl+S",
                "back": "Escape", 
                "delete": "Delete",
                "confirmDelete": ["Y", "Return"],
                "cancelDelete": ["N"],
                "quickDelete": "Ctrl+D",
                "search": "Ctrl+F",
                "nextNote": ["Down", "J"],
                "prevNote": ["Up", "K"],
                "nextNoteHorizontal": ["Right", "L"],
                "prevNoteHorizontal": ["Left", "H"],
                "openNote": ["Return", "Space"],
                "firstNote": "Home",
                "lastNote": "End",
                "quit": "Ctrl+Q",
                "help": "F1",
                "toggleFullscreen": "Ctrl+W",
                "optimizeCardWidth": "Ctrl+1", 
                "increaseCardTitleFontSize": "Ctrl+]",
                "decreaseCardTitleFontSize": "Ctrl+[",
                "increaseFontSize": "Ctrl+=",   
                "decreaseFontSize": "Ctrl+-",
                "increaseCardFontSize": "Ctrl+9",
                "decreaseCardFontSize": "Ctrl+0",
                "increaseCardHeight": "Ctrl+Shift+Down",
                "decreaseCardHeight": "Ctrl+Shift+Up",
                "themeCycle": "Ctrl+T",
                "themeCycleBackward": "Ctrl+Shift+T",
                "fontCycle": "Ctrl+Alt+F",
                "fontCycleBackward": "Ctrl+Alt+Shift+F",
                "fontSelection": "Ctrl+Shift+F",
                "newCollection": "Ctrl+Shift+N",
                "nextCollection": "Ctrl+Tab",
                "prevCollection": "Ctrl+Shift+Tab",
                "deleteCollection": "Ctrl+Shift+D",
                "renameCollection": "F2",
                "showStats": "Ctrl+Space",
                "increaseColumns": "Ctrl+Up",
                "decreaseColumns": "Ctrl+Down",
                "toggleAutoSave": "Ctrl+Alt+S"
            }
        }
    
    def load_config(self):
        """Load configuration, creating default if missing"""
        default_config = self.get_default_config()
        
        self.ensure_directory_exists("config")
        
        loaded_config = self.read_json_file(self.config_file, default_config)
        
        if loaded_config == default_config:
            # No config file exists, create it
            self._config = default_config
            self.save_config()
        else:
            # Deep merge to preserve new defaults
            for key, value in default_config.items():
                if key not in loaded_config:
                    loaded_config[key] = value
                elif key == "shortcuts" and isinstance(value, dict):
                    # Merge shortcuts, preserving user customizations
                    merged_shortcuts = value.copy()
                    merged_shortcuts.update(loaded_config[key])
                    loaded_config[key] = merged_shortcuts
            
            # Validate configuration
            self._config = self.validate_config(loaded_config, default_config)
    
    def validate_config(self, config, defaults):
        """Validate and sanitize configuration values"""
        validated = config.copy()

        # Validate font sizes
        size_keys = ['fontSize', 'cardTitleFontSize', 'headerFontSize', 'cardFontSize']
        for key in size_keys:
            if key in validated:
                try:
                    size = int(validated[key])
                    validated[key] = max(8, min(72, size))
                except (ValueError, TypeError):
                    validated[key] = defaults[key]

        # Validate card dimensions
        card_keys = ['cardWidth', 'cardHeight']
        for key in card_keys:
            if key in validated:
                try:
                    size = int(validated[key])
                    if key == 'cardWidth':
                        validated[key] = max(150, min(500, size))
                    else:  # cardHeight
                        validated[key] = max(120, min(400, size))
                except (ValueError, TypeError):
                    validated[key] = defaults[key]

        # Validate numeric values
        numeric_keys = ['maxUnsavedChanges', 'autoSaveInterval', 'searchDebounceInterval', 'windowWidth', 'windowHeight']
        for key in numeric_keys:
            if key in validated:
                try:
                    val = int(validated[key])
                    validated[key] = max(50, val) if key == 'maxUnsavedChanges' else max(100, val)
                except (ValueError, TypeError):
                    validated[key] = defaults.get(key, 1000)

        # Validate boolean values
        boolean_keys = ['autoSaveEnabled']
        for key in boolean_keys:
            if key in validated:
                if isinstance(validated[key], bool):
                    pass  # Already a boolean, keep as is
                elif isinstance(validated[key], str):
                    validated[key] = validated[key].lower() in ('true', '1', 'yes', 'on')
                else:
                    validated[key] = bool(validated[key])

        return validated
    
    def save_config(self):
        """Save configuration"""
        if self.atomic_write_json(self._config, self.config_file):
            return True
        return False
    
    # Properties
    @Property('QVariant', notify=configChanged)
    def config(self):
        return self._config
    
    # Font size controls
    @Slot()
    def increaseFontSize(self):
        old_size = self._config["fontSize"]
        self._config["fontSize"] = min(100, self._config["fontSize"] + 1)
        if self._config["fontSize"] != old_size:
            self.save_config()
            self.configChanged.emit()

    @Slot()
    def decreaseFontSize(self):
        old_size = self._config["fontSize"]
        self._config["fontSize"] = max(1, self._config["fontSize"] - 1)
        if self._config["fontSize"] != old_size:
            self.save_config()
            self.configChanged.emit()

    @Slot()
    def increaseCardFontSize(self):
        old_size = self._config["cardFontSize"]
        self._config["cardFontSize"] = min(100, self._config["cardFontSize"] + 1)
        if self._config["cardFontSize"] != old_size:
            self.save_config()
            self.configChanged.emit()

    @Slot()
    def decreaseCardFontSize(self):
        old_size = self._config["cardFontSize"]
        self._config["cardFontSize"] = max(1, self._config["cardFontSize"] - 1)
        if self._config["cardFontSize"] != old_size:
            self.save_config()
            self.configChanged.emit()

    @Slot()
    def increaseCardTitleFontSize(self):
        old_size = self._config["cardTitleFontSize"]
        self._config["cardTitleFontSize"] = min(32, self._config["cardTitleFontSize"] + 1)
        if self._config["cardTitleFontSize"] != old_size:
            self.save_config()
            self.configChanged.emit()
    
    @Slot()
    def decreaseCardTitleFontSize(self):
        old_size = self._config["cardTitleFontSize"]
        self._config["cardTitleFontSize"] = max(1, self._config["cardTitleFontSize"] - 1)
        if self._config["cardTitleFontSize"] != old_size:
            self.save_config()
            self.configChanged.emit()
    
    @Slot(int, int)
    def setWindowSize(self, width, height):
        if (width >= 600 and height >= 400 and 
            (self._config["windowWidth"] != width or self._config["windowHeight"] != height)):
            
            self._config["windowWidth"] = width
            self._config["windowHeight"] = height
            self.save_config()
    
    @Slot(bool)
    def setAutoSaveEnabled(self, enabled):
        """Update the autoSaveEnabled configuration setting"""
        if self._config["autoSaveEnabled"] != enabled:
            self._config["autoSaveEnabled"] = enabled
            self.save_config()
            self.configChanged.emit()
    
    def get_value(self, key, default=None):
        """Get a config value"""
        return self._config.get(key, default)
    
    def set_value(self, key, value):
        """Set a config value"""
        if self._config.get(key) != value:
            self._config[key] = value
            self.save_config()
            self.configChanged.emit()
            return True
        return False