from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt, Signal, Slot, Property
from PySide6.QtQml import QmlElement

from .config_manager import ConfigManager
from .collection_manager import CollectionManager
from .theme_manager import ThemeManager
from .font_manager import FontManager
from .stats_manager import StatsManager
from .notes_manager import NotesManager

QML_IMPORT_NAME = "NotesApp"
QML_IMPORT_MAJOR_VERSION = 1


@QmlElement
class MainManager(QAbstractListModel):
    """Main manager that coordinates all backend managers"""
    
    # Forward all signals from sub-managers
    notesChanged = Signal()
    configChanged = Signal()
    filteredNotesChanged = Signal()
    collectionsChanged = Signal()
    currentCollectionChanged = Signal()
    saveError = Signal(str)
    loadError = Signal(str)
    saveSuccess = Signal()
    cardBoundsNeedUpdate = Signal()
    fontsUpdated = Signal()
    
    def __init__(self):
        super().__init__()
        
        # Initialize the model interface delegate
        self._model_delegate = None
        
        # Initialize managers in order of dependencies
        self.config_manager = ConfigManager()
        self.collection_manager = CollectionManager(self.config_manager)
        self.theme_manager = ThemeManager(self.config_manager)
        self.font_manager = FontManager(self.config_manager)
        self.stats_manager = StatsManager(self.collection_manager)
        self.notes_manager = NotesManager(self.collection_manager, self.stats_manager)
        
        # Connect signals to forward them
        self._connect_signals()
        
        # Set the model delegate to the notes manager for QML model interface
        self._model_delegate = self.notes_manager
        
        # Handle first-time setup or load existing collections
        if self.collection_manager.needs_first_collection_setup():
            # No collections found - will prompt user for first collection
            pass
        else:
            self.collection_manager.ensure_all_collection_files_exist()
    
    def _connect_signals(self):
        """Connect all sub-manager signals to forward them"""
        # Config signals
        self.config_manager.configChanged.connect(self.configChanged)
        self.config_manager.error.connect(self.loadError)
        
        # Collection signals
        self.collection_manager.collectionsChanged.connect(self.collectionsChanged)
        self.collection_manager.currentCollectionChanged.connect(self.currentCollectionChanged)
        self.collection_manager.error.connect(self.loadError)
        
        # Notes signals
        self.notes_manager.notesChanged.connect(self.notesChanged)
        self.notes_manager.filteredNotesChanged.connect(self.filteredNotesChanged)
        self.notes_manager.saveError.connect(self.saveError)
        self.notes_manager.loadError.connect(self.loadError)
        self.notes_manager.saveSuccess.connect(self.saveSuccess)
        self.notes_manager.cardBoundsNeedUpdate.connect(self.cardBoundsNeedUpdate)
        
        # Forward model signals
        self.notes_manager.dataChanged.connect(self.dataChanged)
        self.notes_manager.rowsInserted.connect(self._handle_rows_inserted)
        self.notes_manager.rowsRemoved.connect(self._handle_rows_removed)
        self.notes_manager.modelReset.connect(self._handle_model_reset)
        
        # Font signals
        self.font_manager.fontsUpdated.connect(self.fontsUpdated)
        self.font_manager.error.connect(self.loadError)
        
        # Theme signals
        self.theme_manager.error.connect(self.loadError)
        
        # Stats signals
        self.stats_manager.error.connect(self.loadError)
    
    def _handle_model_reset(self):
        """Handle model reset from notes manager"""
        # Trigger a full model reset in MainManager to update QML
        self.beginResetModel()
        self.endResetModel()
    
    def _handle_rows_inserted(self, parent, first, last):
        """Handle rows inserted from notes manager"""
        self.rowsInserted.emit(parent, first, last)
    
    def _handle_rows_removed(self, parent, first, last):
        """Handle rows removed from notes manager"""
        self.rowsRemoved.emit(parent, first, last)
    
    # Properties - forward from sub-managers
    @Property('QVariant', notify=configChanged)
    def config(self):
        return self.config_manager.config
    
    @Property(list, notify=collectionsChanged)
    def collections(self):
        return self.collection_manager.collections

    @Property(str, notify=currentCollectionChanged)
    def currentCollection(self):
        return self.collection_manager.currentCollection
    
    @Property(list, notify=notesChanged)
    def notes(self):
        return self.notes_manager.notes
    
    @Property(list, notify=filteredNotesChanged)
    def filteredNotes(self):
        return self.notes_manager.filteredNotes
    
    @Property(str, notify=filteredNotesChanged)
    def searchText(self):
        return self.notes_manager.searchText
    
    @searchText.setter
    def searchText(self, value):
        self.notes_manager.searchText = value
    
    @Property(int, notify=filteredNotesChanged)
    def noteCount(self):
        return self.notes_manager.noteCount
    
    @Property(int, notify=notesChanged)
    def totalNotesInCollection(self):
        return self.notes_manager.totalNotesInCollection
    
    # Forward all public methods from sub-managers
    # Config methods
    @Slot()
    def increaseFontSize(self):
        self.config_manager.increaseFontSize()

    @Slot()
    def decreaseFontSize(self):
        self.config_manager.decreaseFontSize()

    @Slot()
    def increaseCardFontSize(self):
        self.config_manager.increaseCardFontSize()

    @Slot()
    def decreaseCardFontSize(self):
        self.config_manager.decreaseCardFontSize()

    @Slot()
    def increaseCardTitleFontSize(self):
        self.config_manager.increaseCardTitleFontSize()

    @Slot()
    def decreaseCardTitleFontSize(self):
        self.config_manager.decreaseCardTitleFontSize()

    @Slot(int, int)
    def setWindowSize(self, width, height):
        self.config_manager.setWindowSize(width, height)

    @Slot(bool)
    def setAutoSaveEnabled(self, enabled):
        self.config_manager.setAutoSaveEnabled(enabled)
    
    # Collection methods
    @Slot(result=bool)
    def needsFirstCollectionSetup(self):
        return self.collection_manager.needsFirstCollectionSetup()

    @Slot(str, result=bool)
    def setupFirstCollection(self, name):
        return self.collection_manager.setupFirstCollection(name)

    @Slot(str, result=bool)
    def createCollection(self, name):
        # Save current notes before creating new collection
        if self.collection_manager.currentCollection:
            self.notes_manager.save_notes()
        return self.collection_manager.createCollection(name)

    @Slot(str)
    def switchCollection(self, name):
        # Save current notes before switching
        if self.collection_manager.currentCollection:
            self.notes_manager.save_notes()
        self.collection_manager.switchCollection(name)

    @Slot(str, str)
    def switchCollectionWithSearch(self, name, search_text):
        # Save current notes before switching
        if self.collection_manager.currentCollection:
            self.notes_manager.save_notes()
        # Set search text first, then switch
        self.notes_manager.searchText = search_text
        self.collection_manager.switchCollection(name)

    @Slot(str, result=bool)
    def deleteCollection(self, name):
        # Save current notes before deleting (if it's a different collection)
        if self.collection_manager.currentCollection and self.collection_manager.currentCollection != name:
            self.notes_manager.save_notes()
        return self.collection_manager.deleteCollection(name)

    @Slot(str, str, result=bool)
    def renameCollection(self, old_name, new_name):
        # Save current notes before renaming
        if self.collection_manager.currentCollection == old_name:
            self.notes_manager.save_notes()
        return self.collection_manager.renameCollection(old_name, new_name)

    @Slot(result='QVariant')
    def getCollectionInfo(self):
        return self.collection_manager.getCollectionInfo()
    
    # Theme methods
    @Slot(str)
    def setTheme(self, theme_name):
        self.theme_manager.setTheme(theme_name)

    @Slot(result=str)
    def getCurrentTheme(self):
        return self.theme_manager.getCurrentTheme()

    @Slot(result=list)
    def getAvailableThemes(self):
        return self.theme_manager.getAvailableThemes()

    @Slot(result='QVariant')
    def getAllThemes(self):
        return self.theme_manager.getAllThemes()

    @Slot(str, result='QVariant')
    def getTheme(self, theme_key):
        return self.theme_manager.getTheme(theme_key)

    @Slot(str, str, str, str, str, str, str, str, str, str, result=bool)
    def createTheme(self, key, name, background, surface, primary, primaryText, secondaryText, success, warning, error):
        return self.theme_manager.createTheme(key, name, background, surface, primary, primaryText, secondaryText, success, warning, error)

    @Slot(str, str, str, str, str, str, str, str, str, str, result=bool)
    def updateTheme(self, key, name, background, surface, primary, primaryText, secondaryText, success, warning, error):
        return self.theme_manager.updateTheme(key, name, background, surface, primary, primaryText, secondaryText, success, warning, error)

    @Slot(str, result=bool)
    def deleteTheme(self, key):
        return self.theme_manager.deleteTheme(key)

    @Slot(str, str, result=bool)
    def renameTheme(self, key, new_name):
        return self.theme_manager.renameTheme(key, new_name)
    
    # Font methods
    @Slot(result=list)
    def getAvailableFonts(self):
        return self.font_manager.getAvailableFonts()

    @Slot(result=str)
    def getCurrentFont(self):
        return self.font_manager.getCurrentFont()

    @Slot(str)
    def setFont(self, font_family):
        self.font_manager.setFont(font_family)

    @Slot()
    def cycleFontForward(self):
        self.font_manager.cycleFontForward()

    @Slot()
    def cycleFontBackward(self):
        self.font_manager.cycleFontBackward()

    @Slot()
    def preloadFonts(self):
        self.font_manager.preloadFonts()

    @Slot(result=bool)
    def fontsLoading(self):
        return self.font_manager.fontsLoading()

    @Slot(result=int)
    def getFontCount(self):
        return self.font_manager.getFontCount()
    
    # Notes methods
    @Slot(str)
    def setSearchText(self, text):
        self.notes_manager.setSearchText(text)

    @Slot()
    def updateFilteredNotes(self):
        self.notes_manager.updateFilteredNotes()

    @Slot(str, result=int)
    def createNote(self, content):
        return self.notes_manager.createNote(content)

    @Slot(int, str)
    def updateNote(self, note_id, content):
        self.notes_manager.updateNote(note_id, content)

    @Slot(int)
    def deleteNote(self, note_id):
        self.notes_manager.deleteNote(note_id)

    @Slot(int, result='QVariant')
    def getNote(self, note_id):
        return self.notes_manager.getNote(note_id)

    @Slot(int, result='QVariant')
    def getNoteById(self, note_id):
        return self.notes_manager.getNoteById(note_id)

    @Slot(int, result='QVariant')
    def getNoteByIndex(self, index):
        return self.notes_manager.getNoteByIndex(index)

    @Slot(int, result='QVariant')
    def getNoteStats(self, note_id):
        return self.notes_manager.getNoteStats(note_id)
    
    # Stats methods
    @Slot(result='QVariant')
    def getOverallStats(self):
        return self.stats_manager.getOverallStats()
    
    # QAbstractListModel interface - delegate to notes_manager
    def rowCount(self, parent=QModelIndex()):
        """Delegate rowCount to notes_manager"""
        if self._model_delegate:
            return self._model_delegate.rowCount(parent)
        return 0
    
    def data(self, index, role=Qt.DisplayRole):
        """Delegate data to notes_manager"""
        if self._model_delegate:
            return self._model_delegate.data(index, role)
        return None
    
    def roleNames(self):
        """Delegate roleNames to notes_manager"""
        if self._model_delegate:
            return self._model_delegate.roleNames()
        return {}
    
    # Layout/Card management methods (forward to collection manager with some logic)
    @Slot()
    def increaseCardHeight(self):
        old_height = self.collection_manager.get_current_collection_card_height()
        new_height = min(5000, old_height + 10)
        if new_height != old_height:
            self.collection_manager.set_current_collection_card_height(new_height)
    
    @Slot()
    def decreaseCardHeight(self):
        old_height = self.collection_manager.get_current_collection_card_height()
        new_height = max(1, old_height - 10)
        if new_height != old_height:
            self.collection_manager.set_current_collection_card_height(new_height)

    @Slot(int)
    def setCardHeight(self, height):
        new_height = max(120, min(300, height))
        self.collection_manager.set_current_collection_card_height(new_height)
    
    @Slot(int, int)
    def optimizeCardWidth(self, gridWidth, leftMargin):
        """Find optimal column count and set cards to fill available width"""
        try:
            # Get the number of notes to determine optimal layout
            totalNotes = len(self.notes_manager.filteredNotes)
            if totalNotes == 0:
                return
            
            # Simple optimization: find best column count for readability
            if totalNotes == 1:
                # Single note gets full width
                optimalColumns = 1
            elif totalNotes == 2:
                # Two notes: prefer 2 columns if each would be reasonably wide
                rightMargin = 10
                scrollBarSpace = 10
                availableWidth = gridWidth - leftMargin - rightMargin - scrollBarSpace
                spacing = 20
                twoColWidth = (availableWidth - spacing) / 2
                optimalColumns = 2 if twoColWidth >= 200 else 1
            else:
                # Multiple notes: find optimal balance between columns and readability
                rightMargin = 10
                scrollBarSpace = 10
                availableWidth = gridWidth - leftMargin - rightMargin - scrollBarSpace
                spacing = 20
                
                # Try different column counts and pick the one with best card width
                optimalColumns = 1
                bestCardWidth = availableWidth
                
                for cols in range(1, min(totalNotes + 1, 6)):  # Try up to 5 columns max
                    if cols == 1:
                        cardWidth = availableWidth
                    else:
                        cardWidth = (availableWidth - (cols - 1) * spacing) / cols
                    
                    # Prefer column counts that give reasonable card widths (150-400px)
                    if 150 <= cardWidth <= 400:
                        optimalColumns = cols
                        bestCardWidth = cardWidth
                    elif cardWidth > 400 and cols > optimalColumns:
                        # If card is too wide, more columns might be better
                        optimalColumns = cols
                        bestCardWidth = cardWidth
            
            # Use setColumnCount to apply the optimal column count (ensures edge-to-edge fill)
            self.setColumnCount(gridWidth, leftMargin, optimalColumns)
            
            # CATCH-ALL: Force cards to fill bounds after optimization
            self.forceCardFillBounds(gridWidth, leftMargin)
                
        except Exception as e:
            print(f"✗ Error optimizing card width: {e}")

    @Slot(int, int)
    def forceCardFillBounds(self, gridWidth, leftMargin):
        """Public method to force cards to fill available bounds"""
        try:
            current_collection = self.collection_manager.currentCollection
            if not current_collection:
                return False
            
            # Calculate exact available width
            rightMargin = 10
            scrollBarSpace = 10
            availableWidth = gridWidth - leftMargin - rightMargin - scrollBarSpace
            spacing = 20
            
            # Get preferred columns
            preferredColumns = self.collection_manager.get_current_collection_preferred_columns()
            
            # Calculate exact width to fill bounds
            if preferredColumns == 1:
                exactWidth = availableWidth
            else:
                exactWidth = (availableWidth - (preferredColumns - 1) * spacing) / preferredColumns
            
            exactWidth = int(exactWidth)
            
            # Force this width regardless of what's currently set
            current_width = self.collection_manager.get_current_collection_card_width()
            if exactWidth != current_width:
                self.collection_manager.set_current_collection_card_width(exactWidth)
                return True
            return False
            
        except Exception as e:
            # Don't let errors break the UI
            return False

    @Slot(int, int, int)
    def setColumnCount(self, gridWidth, leftMargin, targetColumns):
        """Set card width to achieve a specific number of columns"""
        try:
            rightMargin = 10
            scrollBarSpace = 10
            availableWidth = gridWidth - leftMargin - rightMargin - scrollBarSpace
            spacing = 20
            
            # Calculate width needed for target columns
            if targetColumns == 1:
                # Single column fills entire available width
                newWidth = availableWidth
            else:
                newWidth = (availableWidth - (targetColumns - 1) * spacing) / targetColumns
            
            # Pure math - no artificial limits when user explicitly sets columns
            # Cards should always stretch to fill available space exactly
            newWidth = int(newWidth)
            
            # Always allow the column count change (no width validation)
            current_width = self.collection_manager.get_current_collection_card_width()
            if current_width != newWidth:
                self.collection_manager.set_current_collection_card_width(newWidth)
                # Save the preferred column count
                self.collection_manager.set_current_collection_preferred_columns(targetColumns)
            
            # CATCH-ALL: Force cards to fill bounds regardless
            self.forceCardFillBounds(gridWidth, leftMargin)
            return True
                
        except Exception as e:
            print(f"✗ Error setting column count: {e}")
            return False

    @Slot(int, int)
    def increaseColumns(self, gridWidth, leftMargin):
        """Increase the number of columns by decreasing card width"""
        try:
            # Calculate current columns
            rightMargin = 10
            scrollBarSpace = 10
            availableWidth = gridWidth - leftMargin - rightMargin - scrollBarSpace
            spacing = 20
            currentWidth = self.collection_manager.get_current_collection_card_width()
            
            # Calculate current approximate columns
            if currentWidth >= availableWidth * 0.9:  # Allow some tolerance
                # Single column mode
                currentColumns = 1
            else:
                currentColumns = max(1, int((availableWidth + spacing) / (currentWidth + spacing)))
            
            # Only limit: can't have more columns than notes (empty columns are useless)
            totalNotes = len(self.notes_manager.filteredNotes)
            if totalNotes == 0:
                return False  # No notes, can't increase columns
            
            if currentColumns >= totalNotes:
                return False  # Already at one column per note
            
            targetColumns = currentColumns + 1
            return self.setColumnCount(gridWidth, leftMargin, targetColumns)
            
        except Exception as e:
            print(f"✗ Error increasing columns: {e}")
            return False

    @Slot(int, int)
    def decreaseColumns(self, gridWidth, leftMargin):
        """Decrease the number of columns by increasing card width"""
        try:
            # Calculate current columns
            rightMargin = 10
            scrollBarSpace = 10
            availableWidth = gridWidth - leftMargin - rightMargin - scrollBarSpace
            spacing = 20
            currentWidth = self.collection_manager.get_current_collection_card_width()
            
            # Calculate current approximate columns
            if currentWidth >= availableWidth * 0.9:  # Allow some tolerance
                # Already at single column mode (full width)
                currentColumns = 1
            else:
                currentColumns = max(1, int((availableWidth + spacing) / (currentWidth + spacing)))
            
            # If we're already at 1 column but not full width, expand to full width
            if currentColumns == 1 and currentWidth < availableWidth * 0.9:
                # Force single column to full width
                targetColumns = 1
                return self.setColumnCount(gridWidth, leftMargin, targetColumns)
            
            # Don't allow going below 1 column if already at full width
            if currentColumns <= 1 and currentWidth >= availableWidth * 0.9:
                return False
            
            targetColumns = currentColumns - 1
            return self.setColumnCount(gridWidth, leftMargin, targetColumns)
            
        except Exception as e:
            print(f"✗ Error decreasing columns: {e}")
            return False