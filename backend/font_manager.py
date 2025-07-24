from PySide6.QtCore import Signal, Slot, QThread
from PySide6.QtGui import QFontDatabase
from .base_manager import BaseManager
import json
from datetime import datetime, timedelta


class FontLoader(QThread):
    """Background thread for loading fonts without blocking UI - OPTIMIZED"""
    fontsLoaded = Signal(list)
    
    def run(self):
        """Load all fonts without filtering patterns"""
        try:
            font_db = QFontDatabase()
            families = font_db.families()
            
            all_fonts = []
            
            for family in families:
                family_lower = family.lower()
                
                # Only skip clearly problematic system fonts
                if family_lower.startswith('@') or family_lower.startswith('.'):
                    continue
                
                all_fonts.append(family)
            
            # Sort alphabetically
            all_fonts = sorted(all_fonts)
            
            self.fontsLoaded.emit(all_fonts)
            
        except Exception as e:
            # Emit empty list on error
            self.fontsLoaded.emit([])


class FontManager(BaseManager):
    """Manages fonts and font loading"""
    
    fontsUpdated = Signal()  # Signal for when fonts finish loading
    
    def __init__(self, config_manager):
        super().__init__()
        self.config_manager = config_manager
        
        # Font cache with disk persistence
        self._font_cache = None
        self._font_loading = False
        self._font_loader = None
        self._font_cache_file = "data/font_cache.json"
        
        # Initialize
        self.ensure_directory_exists("data")
        self._load_font_cache_from_disk()
    
    def _load_font_cache_from_disk(self):
        """Load font cache from disk if available"""
        try:
            cached_data = self.read_json_file(self._font_cache_file)
            if cached_data:
                # Check if cache is recent (within 30 days - longer cache)
                cache_time = datetime.fromisoformat(cached_data.get('timestamp', ''))
                if datetime.now() - cache_time < timedelta(days=30):
                    self._font_cache = cached_data.get('fonts', [])
                    return True
        except Exception:
            pass
        return False
    
    def _save_font_cache_to_disk(self, fonts):
        """Save font cache to disk"""
        try:
            cache_data = {
                'timestamp': datetime.now().isoformat(),
                'fonts': fonts
            }
            self.atomic_write_json(cache_data, self._font_cache_file)
        except Exception:
            pass  # Ignore disk cache errors
    
    def _on_fonts_loaded(self, fonts):
        """Handle fonts loaded from background thread"""
        self._font_cache = fonts
        self._font_loading = False
        self._save_font_cache_to_disk(fonts)
        # Clean up thread
        if self._font_loader:
            self._font_loader.deleteLater()
            self._font_loader = None
        # Notify QML that fonts are updated
        self.fontsUpdated.emit()

    # Font management methods with optimized caching
    @Slot(result=list)
    def getAvailableFonts(self):
        """Get available system fonts with instant fallback"""
        # If we have cached fonts, return them immediately
        if self._font_cache is not None:
            return self._font_cache
            
        # Return immediate basic fonts while loading in background
        basic_fonts = [
            "Victor Mono", "Fira Code", "JetBrains Mono", "Iosevka", "Iosevka NFM",
            "DejaVu Sans Mono", "Ubuntu Mono", "Consolas", "Courier New", "Monaco",
            "Arial", "Helvetica", "Times New Roman", "Georgia", "Trebuchet MS"
        ]
        
        # Start background loading if not already started
        if not self._font_loading and self._font_loader is None:
            self._font_loading = True
            self._font_loader = FontLoader()
            self._font_loader.fontsLoaded.connect(self._on_fonts_loaded)
            self._font_loader.start()
            
        return basic_fonts  # Return basic fonts immediately
    
    @Slot(result=str)
    def getCurrentFont(self):
        """Get current font family"""
        return self.config_manager.get_value("fontFamily", "Victor Mono")
    
    @Slot(str)
    def setFont(self, font_family):
        """Set the font family"""
        if font_family and font_family.strip():
            self.config_manager.set_value("fontFamily", font_family.strip())
    
    @Slot()
    def cycleFontForward(self):
        """Cycle to the next font in the list"""
        available_fonts = self.getAvailableFonts()
        if not available_fonts:
            return
            
        current_font = self.getCurrentFont()
        try:
            current_index = available_fonts.index(current_font)
            next_index = (current_index + 1) % len(available_fonts)
        except ValueError:
            # Current font not in list, start from beginning
            next_index = 0
            
        next_font = available_fonts[next_index]
        self.setFont(next_font)
    
    @Slot()
    def cycleFontBackward(self):
        """Cycle to the previous font in the list"""
        available_fonts = self.getAvailableFonts()
        if not available_fonts:
            return
            
        current_font = self.getCurrentFont()
        try:
            current_index = available_fonts.index(current_font)
            prev_index = (current_index - 1) % len(available_fonts)
        except ValueError:
            # Current font not in list, start from end
            prev_index = len(available_fonts) - 1
            
        prev_font = available_fonts[prev_index]
        self.setFont(prev_font)
    
    @Slot()
    def preloadFonts(self):
        """Preload fonts in background to improve UI responsiveness"""
        if self._font_cache is None and not self._font_loading:
            # Start threaded loading
            self.getAvailableFonts()
    
    @Slot(result=bool)
    def fontsLoading(self):
        """Check if fonts are currently being loaded"""
        return self._font_loading
    
    @Slot(result=int)
    def getFontCount(self):
        """Get number of available fonts (for progress indication)"""
        if self._font_cache:
            return len(self._font_cache)
        return 0