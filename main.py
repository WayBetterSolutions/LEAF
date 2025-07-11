import sys
import json
import os
import re
import colorsys
from pathlib import Path
from datetime import datetime, timedelta
from PySide6.QtGui import QGuiApplication, QFont
from PySide6.QtQml import QmlElement, qmlRegisterType
from PySide6.QtCore import (
    QAbstractListModel, QModelIndex,
    Qt, Signal, Slot, Property, QUrl, QTimer, QByteArray
)
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle 
from PySide6.QtWidgets import QApplication

QML_IMPORT_NAME = "NotesApp"
QML_IMPORT_MAJOR_VERSION = 1

@QmlElement
class NotesManager(QAbstractListModel):
    notesChanged = Signal()
    configChanged = Signal()
    filteredNotesChanged = Signal()
    collectionsChanged = Signal()
    currentCollectionChanged = Signal()
    saveError = Signal(str)
    loadError = Signal(str)
    saveSuccess = Signal()
    
    # Role constants
    IdRole       = Qt.UserRole + 1
    TitleRole    = Qt.UserRole + 2
    ContentRole  = Qt.UserRole + 3
    CreatedRole  = Qt.UserRole + 4
    ModifiedRole = Qt.UserRole + 5

    def roleNames(self):
        return {
            self.IdRole:       b"id",
            self.TitleRole:    b"title",
            self.ContentRole:  b"content",
            self.CreatedRole:  b"created",
            self.ModifiedRole: b"modified",
        }

    def rowCount(self, parent=QModelIndex()):
        return len(self._filtered_notes)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or index.row() >= len(self._filtered_notes):
            return None
        
        note = self._filtered_notes[index.row()]
        
        if role == self.IdRole:
            return note.get("id", -1)
        elif role == self.TitleRole:
            return note.get("title", "")
        elif role == self.ContentRole:
            return note.get("content", "")
        elif role == self.CreatedRole:
            return note.get("created", "")
        elif role == self.ModifiedRole:
            return note.get("modified", "")
        
        return None
    
    def __init__(self):
        super().__init__()

        # File paths
        self.config_file = "config.json"
        self.collections_dir = "collections"
        self.collections_file = "collections.json"
        
        # Collections state
        self._collections = []
        self._current_collection = ""
        
        # Notes state (per collection)
        self._notes = []
        self._filtered_notes = []
        self._next_id = 0
        self._search_text = ""
        self._search_regex = None
        
        # Config state
        self._config = {}
        
        print("=== Notes Manager Initialization ===")
        
        # Initialize everything in the right order
        self._ensure_directories_exist()
        self.load_config()
        self._migrate_old_files()  # Clean up any legacy files
        self.load_collections()

        # Handle first-time setup or load existing collections
        if self._needs_first_collection_setup():
            print("📝 No collections found - will prompt user for first collection")
            # Don't create any files yet - wait for user input
        else:
            self._ensure_all_collection_files_exist()
            self.load_notes()
        
        print("=== Initialization Complete ===")

    def _ensure_directories_exist(self):
        """Ensure all necessary directories exist"""
        try:
            if not os.path.exists(self.collections_dir):
                os.makedirs(self.collections_dir)
                print(f"✓ Created collections directory: {self.collections_dir}")
            else:
                print(f"✓ Collections directory already exists: {self.collections_dir}")
        except Exception as e:
            print(f"✗ Error creating collections directory: {e}")
            self.loadError.emit(f"Cannot create collections directory: {e}")

    def _migrate_old_files(self):
        """Clean up any legacy files from older versions"""
        legacy_files = ["notes.json", "test.json"]
        
        for legacy_file in legacy_files:
            if os.path.exists(legacy_file):
                try:
                    print(f"📦 Found legacy file: {legacy_file}")
                    
                    # Read old notes
                    with open(legacy_file, 'r', encoding='utf-8') as f:
                        content = f.read().strip()
                        if not content:
                            old_notes = []
                        else:
                            old_notes = json.loads(content)
                    
                    # Skip if empty
                    if not old_notes:
                        print(f"📝 Legacy file {legacy_file} is empty, removing...")
                        os.remove(legacy_file)
                        continue
                    
                    # Determine collection name
                    if legacy_file == "notes.json":
                        collection_name = "General"
                    else:
                        # Use filename without extension as collection name
                        collection_name = os.path.splitext(legacy_file)[0].title()
                    
                    print(f"📦 Migrating {legacy_file} to collection '{collection_name}'...")
                    
                    # Ensure collections directory exists
                    self._ensure_directories_exist()
                    
                    # Create collection file with migrated notes
                    collection_file = self.get_collection_file_path(collection_name)
                    with open(collection_file, 'w', encoding='utf-8') as f:
                        json.dump(old_notes, f, indent=2, ensure_ascii=False)
                    
                    # Add to collections list if not already there
                    if collection_name not in self._collections:
                        self._collections.append(collection_name)
                    
                    # Set as current collection if we don't have one
                    if not self._current_collection:
                        self._current_collection = collection_name
                    
                    # Create backup and remove legacy file
                    backup_file = f"{legacy_file}.backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                    os.rename(legacy_file, backup_file)
                    
                    print(f"✓ Migrated {legacy_file} to collection '{collection_name}'")
                    print(f"✓ Backup created: {backup_file}")
                    
                except Exception as e:
                    print(f"✗ Error migrating {legacy_file}: {e}")

    def get_collection_file_path(self, collection_name):
        """Get the file path for a collection with proper sanitization"""
        # Remove invalid filename characters and limit length
        safe_name = re.sub(r'[<>:"/\\|?*]', '_', collection_name)
        safe_name = safe_name.strip()[:50]  # Limit filename length
        if not safe_name:
            safe_name = "Unnamed"
        
        file_path = os.path.join(self.collections_dir, f"{safe_name}.json")
        return file_path

    def _create_collection_file(self, collection_name):
        """Create a collection file with proper error handling"""
        collection_file = self.get_collection_file_path(collection_name)
        
        try:
            # Ensure the directory exists
            os.makedirs(os.path.dirname(collection_file), exist_ok=True)
            
            # Create the file with empty array
            with open(collection_file, 'w', encoding='utf-8') as f:
                json.dump([], f, indent=2, ensure_ascii=False)
            
            print(f"✓ Created collection file: {collection_file}")
            return True
            
        except PermissionError:
            error_msg = f"Permission denied creating collection file: {collection_file}"
            print(f"✗ {error_msg}")
            self.loadError.emit(error_msg)
            return False
        except Exception as e:
            error_msg = f"Error creating collection file '{collection_file}': {e}"
            print(f"✗ {error_msg}")
            self.loadError.emit(error_msg)
            return False

    def _ensure_all_collection_files_exist(self):
        """Ensure all collections have corresponding JSON files"""
        print(f"🔍 Checking collection files for {len(self._collections)} collections...")
        
        for collection_name in self._collections:
            collection_file = self.get_collection_file_path(collection_name)
            
            if not os.path.exists(collection_file):
                print(f"📝 Creating missing collection file for: {collection_name}")
                self._create_collection_file(collection_name)
            else:
                print(f"✓ Collection file exists: {collection_file}")

    def _needs_first_collection_setup(self):
        """Check if we need to prompt user for first collection"""
        return len(self._collections) == 0 or self._current_collection == ""

    @Slot(result=bool)
    def needsFirstCollectionSetup(self):
        """QML-accessible method to check if first collection setup is needed"""
        return self._needs_first_collection_setup()

    @Slot(str, result=bool)
    def setupFirstCollection(self, name):
        """Set up the very first collection"""
        if not name.strip():
            return False
            
        clean_name = name.strip()
        
        # Initialize collections system
        self._collections = [clean_name]
        self._current_collection = clean_name
        
        # Create the collection file
        if self._create_collection_file(clean_name):
            if self.save_collections():
                self.collectionsChanged.emit()
                self.currentCollectionChanged.emit()
                # Initialize empty notes for this collection
                self._notes = []
                self._filtered_notes = []
                self._next_id = 0
                self.notesChanged.emit()
                self.filteredNotesChanged.emit()
                print(f"✓ Set up first collection: {clean_name}")
                return True
        
        return False

    def load_config(self):
        """Load configuration, creating default if missing"""
        default_config = {
            "backgroundColor": "#2b2b2b",
            "cardColor": "#3c3c3c", 
            "textColor": "#ffffff",
            "accentColor": "#4a9eff",
            "secondaryTextColor": "#b0b0b0",
            "hoverColor": "#4c4c4c",
            "selectedCardColor": "#5c5c5c",
            "borderColor": "#505050",
            "placeholderColor": "#808080",
            "deleteButtonColor": "#e74c3c",
            "successColor": "#27ae60",
            "warningColor": "#f39c12",
            "searchBarColor": "#ffffff",
            "searchBarTextColor": "#2b2b2b",
            "buttonTextColor": "#c0caf5",
            "buttonBorderColor": "#414868", 
            "notificationTextColor": "#c0caf5",
            "modalOverlayColor": "#16161e",
            "modalOverlayOpacity": 0.8,
            "focusBorderColor": "#7aa2f7",
            "transparentColor": "transparent",
            "selectedCardTextColor": "#c0caf5",
            "selectedCardSecondaryTextColor": "#bb9af7",
            "helpDialogBackgroundColor": "#24283b",
            "helpDialogBorderColor": "#7aa2f7", 
            "helpDialogTextColor": "#c0caf5",
            "confirmationDialogBackgroundColor": "#24283b",
            "confirmationDialogBorderColor": "#7aa2f7",
            "editorBackgroundColor": "#24283b",
            "editorFocusBorderColor": "#7aa2f7",
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
            "searchDebounceInterval": 300,
            "currentTheme": "githubDark",
            "shortcuts": {
                "newNote": "Ctrl+N",
                "save": "Ctrl+S",
                "back": "Escape", 
                "delete": "Delete",
                "confirmDelete": ["Y", "Return"],
                "cancelDelete": ["N", "Escape"],
                "quickDelete": "Ctrl+D",
                "search": "Ctrl+F",
                "searchNext": "F3",
                "searchPrev": "Shift+F3",
                "toggleView": "Tab",
                "nextNote": ["Down", "J"],
                "prevNote": ["Up", "K"],
                "nextNoteHorizontal": ["Right", "L"],
                "prevNoteHorizontal": ["Left", "H"],
                "openNote": ["Return", "Space"],
                "firstNote": "Home",
                "lastNote": "End",
                "pageUp": "Page_Up",
                "pageDown": "Page_Down",
                "selectAll": "Ctrl+A",
                "copy": "Ctrl+C",
                "cut": "Ctrl+X",
                "paste": "Ctrl+V",
                "undo": "Ctrl+Z",
                "redo": "Ctrl+Y",
                "find": "Ctrl+F",
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
                "increaseCardWidth": "Ctrl+Shift+Right",
                "decreaseCardWidth": "Ctrl+Shift+Left",
                "increaseCardHeight": "Ctrl+Shift+Down",
                "decreaseCardHeight": "Ctrl+Shift+Up",
                "themeCycle": "Ctrl+T",
                "themeCycleBackward": "Ctrl+Shift+T",
                "newCollection": "Ctrl+Shift+N",
                "nextCollection": "Ctrl+Tab",
                "prevCollection": "Ctrl+Shift+Tab",
                "deleteCollection": "Ctrl+Shift+D",
                "renameCollection": "F2",
                "showStats": "Ctrl+Space"
            }
        }

        try:
            if os.path.exists(self.config_file):
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    loaded_config = json.load(f)
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
                    print("✓ Loaded existing config.json")
            else:
                # No config file exists, create it
                self._config = default_config
                self.save_config()
                print("✓ Created new config.json with defaults")
                
        except json.JSONDecodeError:
            self.loadError.emit("Configuration file is corrupted. Using defaults.")
            self._config = default_config
            self._backup_file(self.config_file)
            self.save_config()
        except Exception as e:
            self.loadError.emit(f"Error loading config: {str(e)}")
            self._config = default_config
            self.save_config()

    def load_collections(self):
        """Load collections metadata, creating defaults if missing"""
        try:
            if os.path.exists(self.collections_file):
                with open(self.collections_file, 'r', encoding='utf-8') as f:
                    collections_data = json.load(f)
                    self._collections = collections_data.get("collections", [])
                    self._current_collection = collections_data.get("currentCollection", "")
                print(f"✓ Loaded existing collections.json with {len(self._collections)} collections")
            else:
                # No collections file exists - will prompt user for first collection
                self._collections = []
                self._current_collection = ""
                print("📝 No collections.json found - starting fresh")
                
            # Ensure current collection exists in the list (if we have collections)
            if self._collections and self._current_collection not in self._collections:
                self._current_collection = self._collections[0] if self._collections else ""
                    
            print(f"📂 Collections: {self._collections}")
            print(f"📍 Current collection: {self._current_collection}")
                    
        except json.JSONDecodeError:
            self.loadError.emit("Collections file is corrupted. Starting fresh.")
            self._backup_file(self.collections_file)
            self._collections = []
            self._current_collection = ""
        except Exception as e:
            print(f"✗ Error loading collections: {e}")
            self.loadError.emit(f"Error loading collections: {str(e)}")
            self._collections = []
            self._current_collection = ""

    def save_collections(self):
        """Save collections metadata"""
        try:
            collections_data = {
                "collections": self._collections,
                "currentCollection": self._current_collection
            }
            
            # Use temporary file for atomic write
            temp_file = self.collections_file + '.tmp'
            with open(temp_file, 'w', encoding='utf-8') as f:
                json.dump(collections_data, f, indent=2, ensure_ascii=False)
            
            # Atomic rename
            os.replace(temp_file, self.collections_file)
            print(f"✓ Saved collections.json")
            return True
        except Exception as e:
            print(f"✗ Error saving collections: {e}")
            return False

    def load_notes(self):
        """Load notes for current collection"""
        if not self._current_collection:
            print("⚠️ No current collection set, skipping note loading")
            self._notes = []
            self._filtered_notes = []
            self._next_id = 0
            self.beginResetModel()
            self.endResetModel()
            self.notesChanged.emit()
            self.filteredNotesChanged.emit()
            return

        notes_file = self.get_collection_file_path(self._current_collection)
        print(f"📖 Loading notes from: {notes_file}")
        
        try:
            if os.path.exists(notes_file):
                with open(notes_file, 'r', encoding='utf-8') as f:
                    data = f.read()
                    if not data.strip():
                        self._notes = []
                        self._filtered_notes = []
                        self._next_id = 0
                        print(f"📝 Empty notes file for collection '{self._current_collection}'")
                    else:
                        self._notes = json.loads(data)
                        
                        # Validate note structure and find highest ID
                        max_id = -1
                        valid_notes = []
                        for note in self._notes:
                            if isinstance(note, dict) and all(key in note for key in ['id', 'title', 'content']):
                                # Add missing timestamps
                                if 'created' not in note:
                                    note['created'] = datetime.now().isoformat()
                                if 'modified' not in note:
                                    note['modified'] = note['created']
                                valid_notes.append(note)
                                max_id = max(max_id, note['id'])
                            else:
                                print(f"⚠️ Skipping invalid note: {note}")
                        
                        self._notes = valid_notes
                        self._next_id = max_id + 1
                        self._filtered_notes = self._notes.copy()
                        
                print(f"✓ Loaded {len(self._notes)} notes for collection '{self._current_collection}'")
            else:
                # Collection file doesn't exist, create it
                print(f"📝 Notes file doesn't exist, creating: {notes_file}")
                if self._create_collection_file(self._current_collection):
                    self._notes = []
                    self._filtered_notes = []
                    self._next_id = 0
                    print(f"✓ Created new notes file for collection '{self._current_collection}'")
                else:
                    print(f"✗ Failed to create notes file for collection '{self._current_collection}'")
                
        except json.JSONDecodeError:
            self.loadError.emit(f"Notes file for '{self._current_collection}' is corrupted. Creating backup...")
            self._backup_file(notes_file)
            self._notes = []
            self._filtered_notes = []
            self._next_id = 0
            # Create new empty file
            self._create_collection_file(self._current_collection)
        except Exception as e:
            print(f"✗ Error loading notes for '{self._current_collection}': {e}")
            self.loadError.emit(f"Error loading notes for '{self._current_collection}': {str(e)}")
            self._notes = []
            self._filtered_notes = []
            self._next_id = 0
        finally:
            # Reset the model to reflect the loaded notes
            self.beginResetModel()
            self.endResetModel()
            self.notesChanged.emit()
            self.filteredNotesChanged.emit()

    def save_notes(self):
        """Save notes for current collection"""
        if not self._current_collection:
            print("⚠️ No current collection set, cannot save notes")
            return False

        notes_file = self.get_collection_file_path(self._current_collection)
        
        try:
            # Ensure directory exists
            os.makedirs(os.path.dirname(notes_file), exist_ok=True)
            
            tmp_path = f"{notes_file}.tmp"
            
            with open(tmp_path, "w", encoding="utf-8") as f:
                json.dump(self._notes, f, indent=2, ensure_ascii=False)

            os.replace(tmp_path, notes_file)
            print(f"✓ Saved {len(self._notes)} notes to {notes_file}")
            self.saveSuccess.emit()
            return True

        except PermissionError:
            msg = f"Cannot save notes for '{self._current_collection}' – file is locked or you lack permission."
            print(f"✗ {msg}")
            self.saveError.emit(msg)
            return False
        except Exception as e:
            msg = f"Error saving notes for '{self._current_collection}': {e}"
            print(f"✗ {msg}")
            self.saveError.emit(msg)
            return False

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

        # Validate colors
        color_pattern = re.compile(r'^#[0-9A-Fa-f]{6}$')
        for key, value in validated.items():
            if 'Color' in key and not color_pattern.match(str(value)):
                validated[key] = defaults.get(key, "#ffffff")

        # Validate numeric values
        numeric_keys = ['maxUnsavedChanges', 'autoSaveInterval', 'searchDebounceInterval', 'windowWidth', 'windowHeight']
        for key in numeric_keys:
            if key in validated:
                try:
                    val = int(validated[key])
                    validated[key] = max(50, val) if key == 'maxUnsavedChanges' else max(100, val)
                except (ValueError, TypeError):
                    validated[key] = defaults.get(key, 1000)

        return validated

    def save_config(self):
        """Save configuration"""
        try:
            # Write to temporary file first for atomic operation
            temp_file = self.config_file + '.tmp'
            with open(temp_file, 'w', encoding='utf-8') as f:
                json.dump(self._config, f, indent=2, ensure_ascii=False)
            
            # Atomic rename
            os.replace(temp_file, self.config_file)
            return True
        except Exception as e:
            print(f"✗ Error saving config: {e}")
            return False

    def _backup_file(self, filepath):
        """Create a backup of the file with timestamp"""
        try:
            if os.path.exists(filepath):
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                backup_path = f"{filepath}.backup_{timestamp}"
                os.rename(filepath, backup_path)
                print(f"✓ Backup created: {backup_path}")
        except Exception as e:
            print(f"✗ Failed to create backup: {e}")

    def generate_title(self, content):
        """Generate a title from the first line of content"""
        if not content.strip():
            return "Untitled Note"
        
        # Get first line, remove extra whitespace
        first_line = content.split('\n')[0].strip()
        
        # Remove any markdown headers
        first_line = re.sub(r'^#+\s*', '', first_line)
        
        # Limit to reasonable title length
        if len(first_line) > 50:
            first_line = first_line[:47] + "..."
        
        return first_line if first_line else "Untitled Note"

    # Collection management slots
    @Slot(str, result=bool)
    def createCollection(self, name):
        """Create a new collection with proper file management"""
        if not name.strip():
            return False
            
        clean_name = name.strip()
        if clean_name in self._collections:
            return False  # Collection already exists
            
        print(f"🆕 Creating new collection: {clean_name}")
        
        # IMPORTANT: Save current notes before creating new collection
        if self._current_collection:
            print(f"💾 Saving current notes before creating new collection")
            self.save_notes()
        
        # Add to collections list
        self._collections.append(clean_name)
        
        # Create the JSON file for this collection
        if self._create_collection_file(clean_name):
            # Save collections metadata
            if self.save_collections():
                self.collectionsChanged.emit()
                print(f"✓ Successfully created collection: {clean_name}")
                return True
            else:
                # Cleanup if save failed
                self._collections.remove(clean_name)
                return False
        else:
            # Remove from collections list if file creation failed
            self._collections.remove(clean_name)
            return False

    @Slot(str)
    def switchCollection(self, name):
        """Switch to a different collection"""
        if name not in self._collections:
            print(f"⚠️ Cannot switch to non-existent collection: {name}")
            return

        if self._current_collection != name:
            print(f"🔄 Switching from '{self._current_collection}' to '{name}'")

            # IMPORTANT: Save current notes before switching
            if self._current_collection:
                print(f"💾 Saving notes for current collection: {self._current_collection}")
                self.save_notes()

            # Store current search state
            current_search = self._search_text

            old_collection = self._current_collection
            self._current_collection = name

            # Ensure target collection file exists
            collection_file = self.get_collection_file_path(name)
            if not os.path.exists(collection_file):
                print(f"📝 Target collection file missing, creating: {collection_file}")
                if not self._create_collection_file(name):
                    # Revert to old collection if file creation failed
                    self._current_collection = old_collection
                    return

            # Save collections metadata and reload notes for new collection
            self.save_collections()
            self.load_notes()  # This loads notes for the NEW collection

            # Reapply search if there was one active
            if current_search.strip():
                print(f"🔍 Reapplying search '{current_search}' to collection '{name}'")
                self._search_text = current_search
                self.updateFilteredNotes()

            self.currentCollectionChanged.emit()
            print(f"✓ Successfully switched to collection: {name}")

    # Add a new slot to preserve search state
    @Slot(str, str)
    def switchCollectionWithSearch(self, name, search_text):
        """Switch collection while preserving search state"""
        # Set the search text first
        self._search_text = search_text
        # Then switch collection (which will reapply the search)
        self.switchCollection(name)

    @Slot(str, result=bool)
    def deleteCollection(self, name):
        """Delete a collection and its file"""
        if len(self._collections) <= 1:
            print("⚠️ Cannot delete the last collection")
            return False  # Don't delete the last collection
            
        if name not in self._collections:
            print(f"⚠️ Cannot delete non-existent collection: {name}")
            return False
            
        print(f"🗑️ Deleting collection: {name}")
        
        # IMPORTANT: Save current notes before deleting if it's the current collection
        if self._current_collection == name:
            print(f"💾 Saving notes before deleting current collection")
            self.save_notes()
        
        # Remove from collections list
        self._collections.remove(name)
        
        # Delete the file (with backup)
        try:
            collection_file = self.get_collection_file_path(name)
            if os.path.exists(collection_file):
                # Create backup before deletion
                backup_file = f"{collection_file}.deleted_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                os.rename(collection_file, backup_file)
                print(f"✓ Collection file backed up to: {backup_file}")
        except Exception as e:
            print(f"⚠️ Error deleting collection file: {e}")
        
        # If we deleted the current collection, switch to the first available
        if self._current_collection == name:
            self._current_collection = self._collections[0]
            print(f"🔄 Switched to collection: {self._current_collection}")
            self.load_notes()
            self.currentCollectionChanged.emit()
            
        self.save_collections()
        self.collectionsChanged.emit()
        print(f"✓ Successfully deleted collection: {name}")
        return True

    @Slot(str, str, result=bool)
    def renameCollection(self, old_name, new_name):
        """Rename a collection and its file"""
        if old_name not in self._collections or new_name.strip() == "":
            return False
            
        clean_new_name = new_name.strip()
        if clean_new_name in self._collections:
            return False  # New name already exists
            
        print(f"✏️ Renaming collection from '{old_name}' to '{clean_new_name}'")
        
        # IMPORTANT: Save current notes before renaming
        if self._current_collection == old_name:
            print(f"💾 Saving notes before renaming current collection")
            self.save_notes()
        
        # Update collections list
        index = self._collections.index(old_name)
        self._collections[index] = clean_new_name
        
        # Rename the file
        try:
            old_file = self.get_collection_file_path(old_name)
            new_file = self.get_collection_file_path(clean_new_name)
            
            if os.path.exists(old_file):
                os.rename(old_file, new_file)
                print(f"✓ Renamed collection file: {old_file} -> {new_file}")
            else:
                # Create new file if old one doesn't exist
                self._create_collection_file(clean_new_name)
                print(f"✓ Created new collection file: {new_file}")
                
        except Exception as e:
            print(f"✗ Error renaming collection file: {e}")
            # Revert collections list change
            self._collections[index] = old_name
            return False
        
        # Update current collection if it was the renamed one
        if self._current_collection == old_name:
            self._current_collection = clean_new_name
            self.currentCollectionChanged.emit()
            
        self.save_collections()
        self.collectionsChanged.emit()
        print(f"✓ Successfully renamed collection to: {clean_new_name}")
        return True

    # Properties
    @Property(list, notify=collectionsChanged)
    def collections(self):
        return self._collections

    @Property(str, notify=currentCollectionChanged)
    def currentCollection(self):
        return self._current_collection

    @Property(list, notify=notesChanged)
    def notes(self):
        return self._notes
    
    @Property(list, notify=filteredNotesChanged)
    def filteredNotes(self):
        return self._filtered_notes
    
    @Property('QVariant', notify=configChanged)
    def config(self):
        return self._config
    
    @Property(str, notify=filteredNotesChanged)
    def searchText(self):
        return self._search_text
    
    @searchText.setter
    def searchText(self, value):
        if self._search_text != value:
            self._search_text = value
            self.updateFilteredNotes()
    
    @Slot(str)
    def setSearchText(self, text):
        self.searchText = text
    
    @Slot()
    def updateFilteredNotes(self):
        """Update filtered notes and properly notify the model"""
        self.beginResetModel()
        
        if self._search_text.strip():
            search_pattern = re.compile(re.escape(self._search_text), re.IGNORECASE)
            self._filtered_notes = [
                note for note in self._notes
                if (search_pattern.search(note.get("title", "")) or 
                    search_pattern.search(note.get("content", "")))
            ]
        else:
            self._filtered_notes = list(self._notes)
        
        self.endResetModel()
        self.filteredNotesChanged.emit()
    
    @Slot(str, result=int)
    def createNote(self, content):
        """Create a note in the current collection"""
        if not self._current_collection:
            print("⚠️ Cannot create note: no current collection")
            return -1
            
        note_id = self._next_id
        self._next_id += 1
        
        now = datetime.now().isoformat()
        title = self.generate_title(content)
        
        new_note = {
            "id": note_id,
            "title": title,
            "content": content,
            "created": now,
            "modified": now
        }
        
        # Add to notes list
        self._notes.insert(0, new_note)
        
        # Update filtered notes
        if self._search_text.strip():
            search_pattern = re.compile(re.escape(self._search_text), re.IGNORECASE)
            if (search_pattern.search(title) or search_pattern.search(content)):
                self.beginInsertRows(QModelIndex(), 0, 0)
                self._filtered_notes.insert(0, new_note)
                self.endInsertRows()
        else:
            self.beginInsertRows(QModelIndex(), 0, 0)
            self._filtered_notes.insert(0, new_note)
            self.endInsertRows()
        
        # Save to current collection
        self.save_notes()
        self.notesChanged.emit()
        print(f"✓ Created note with ID {note_id} in collection '{self._current_collection}'")
        return note_id
    
    @Slot(int, str)
    def updateNote(self, note_id, content):
        """Update note content in the current collection"""
        if not self._current_collection:
            print("⚠️ Cannot update note: no current collection")
            return
            
        for i, note in enumerate(self._notes):
            if note["id"] == note_id:
                if note["content"] != content:
                    note["content"] = content
                    note["title"] = self.generate_title(content)
                    note["modified"] = datetime.now().isoformat()
                    
                    # Find in filtered notes
                    for j, filtered_note in enumerate(self._filtered_notes):
                        if filtered_note["id"] == note_id:
                            self._filtered_notes[j] = note
                            # Notify model of change
                            idx = self.index(j)
                            self.dataChanged.emit(idx, idx, [
                                self.TitleRole, 
                                self.ContentRole, 
                                self.ModifiedRole
                            ])
                            break
                    
                    # Save to current collection
                    self.save_notes()
                    print(f"✓ Updated note with ID {note_id} in collection '{self._current_collection}'")
                break
    
    @Slot(int)
    def deleteNote(self, note_id):
        """Delete note from current collection"""
        if not self._current_collection:
            print("⚠️ Cannot delete note: no current collection")
            return
            
        # Find and remove from main list
        for i, note in enumerate(self._notes):
            if note["id"] == note_id:
                self._notes.pop(i)
                break
        
        # Find and remove from filtered list
        for i, note in enumerate(self._filtered_notes):
            if note["id"] == note_id:
                self.beginRemoveRows(QModelIndex(), i, i)
                self._filtered_notes.pop(i)
                self.endRemoveRows()
                break
        
        # Save to current collection
        self.save_notes()
        self.notesChanged.emit()
        print(f"✓ Deleted note with ID {note_id} from collection '{self._current_collection}'")
    
    @Slot(int, result='QVariant')
    def getNote(self, note_id):
        for note in self._notes:
            if note["id"] == note_id:
                return note
        return {}
    
    @Slot(int, result='QVariant')
    def getNoteById(self, note_id):
        """Get note by ID from filtered notes"""
        for note in self._filtered_notes:
            if note.get("id") == note_id:
                return note
        return None

    @Slot(int, result='QVariant')
    def getNoteByIndex(self, index):
        """Get note by index from filtered notes"""
        if 0 <= index < len(self._filtered_notes):
            return self._filtered_notes[index]
        return None

    @Slot(result='QVariant')
    def getCollectionInfo(self):
        """Get information about all collections"""
        info = []
        for collection_name in self._collections:
            collection_file = self.get_collection_file_path(collection_name)
            note_count = 0
            file_size = 0
            
            try:
                if os.path.exists(collection_file):
                    file_size = os.path.getsize(collection_file)
                    with open(collection_file, 'r', encoding='utf-8') as f:
                        notes = json.load(f)
                        note_count = len(notes) if isinstance(notes, list) else 0
            except Exception as e:
                print(f"✗ Error reading collection {collection_name}: {e}")
            
            info.append({
                "name": collection_name,
                "noteCount": note_count,
                "fileSize": file_size,
                "isCurrent": collection_name == self._current_collection
            })
        
        return info

    # Font and layout controls
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

    @Slot()
    def increaseCardWidth(self):
        old_width = self._config["cardWidth"]
        self._config["cardWidth"] = min(5000, self._config["cardWidth"] + 10)
        if self._config["cardWidth"] != old_width:
            self.save_config()
            self.configChanged.emit()
    
    @Slot()
    def decreaseCardWidth(self):
        old_width = self._config["cardWidth"]
        self._config["cardWidth"] = max(1, self._config["cardWidth"] - 10)
        if self._config["cardWidth"] != old_width:
            self.save_config()
            self.configChanged.emit()
    
    @Slot()
    def increaseCardHeight(self):
        old_height = self._config["cardHeight"]
        self._config["cardHeight"] = min(5000, self._config["cardHeight"] + 10)
        if self._config["cardHeight"] != old_height:
            self.save_config()
            self.configChanged.emit()
    
    @Slot()
    def decreaseCardHeight(self):
        old_height = self._config["cardHeight"]
        self._config["cardHeight"] = max(1, self._config["cardHeight"] - 10)
        if self._config["cardHeight"] != old_height:
            self.save_config()
            self.configChanged.emit()

    @Slot(int)
    def setCardWidth(self, width):
        self._config["cardWidth"] = max(150, min(400, width))
        self.save_config()
        self.configChanged.emit()
    
    @Slot(int)
    def setCardHeight(self, height):
        self._config["cardHeight"] = max(120, min(300, height))
        self.save_config()
        self.configChanged.emit()
        
    @Slot(int, int)
    def setWindowSize(self, width, height):
        if (width >= 600 and height >= 400 and 
            (self._config["windowWidth"] != width or self._config["windowHeight"] != height)):
            self._config["windowWidth"] = width
            self._config["windowHeight"] = height
            self.save_config()
        
    @Slot(int, int)
    def optimizeCardWidth(self, gridWidth, leftMargin):
        """Calculate and set card width to perfectly fill the grid width"""
        try:
            rightMargin = 10
            scrollBarSpace = 10
            availableWidth = gridWidth - leftMargin - rightMargin - scrollBarSpace
            spacing = 20
            currentCardWidth = self._config["cardWidth"]
            
            bestWidth = currentCardWidth
            bestColumns = 1
            bestFit = float('inf')
            
            for cols in range(1, 11):
                if cols == 1:
                    candidateWidth = min(500, availableWidth)
                else:
                    candidateWidth = (availableWidth - (cols - 1) * spacing) / cols
                
                candidateWidth = int(candidateWidth)
                
                if candidateWidth < 250:
                    continue
                if candidateWidth > 500:
                    candidateWidth = 500
                
                totalUsed = cols * candidateWidth + (cols - 1) * spacing
                
                if totalUsed <= availableWidth:
                    unusedSpace = availableWidth - totalUsed
                    if unusedSpace < bestFit and unusedSpace >= 0:
                        bestWidth = candidateWidth
                        bestColumns = cols
                        bestFit = unusedSpace
            
            bestWidth = max(150, min(500, bestWidth))
            
            if self._config["cardWidth"] != bestWidth:
                self._config["cardWidth"] = int(bestWidth)
                self.save_config()
                self.configChanged.emit()
                print(f"✓ Optimized to {bestColumns} columns with width {bestWidth}px")
                
        except Exception as e:
            print(f"✗ Error optimizing card width: {e}")

    # Add this property after the existing properties
    @Property(int, notify=filteredNotesChanged)
    def noteCount(self):
        return len(self._filtered_notes)
    
    @Property(int, notify=notesChanged)
    def totalNotesInCollection(self):
        """Total number of notes in the current collection (not filtered)"""
        return len(self._notes)
    
    @Slot(str)
    def setTheme(self, theme_name):
        self._config["currentTheme"] = theme_name
        self.save_config()
        self.configChanged.emit()

    @Slot(result=str)
    def getCurrentTheme(self):
        return self._config.get("currentTheme", "githubDark")

    @Slot(result=list)
    def getAvailableThemes(self):
        return ["nightOwl", "dracula", "monokai", "githubDark", "solarizedLight", "catppuccin", "tokyoNight", "nordDark", "gruvboxDark", "oneDark", "materialDark", "ayuDark", "forest"]
    
    @Slot(result='QVariant')
    def getOverallStats(self):
        """Get overall statistics across all collections"""
        total_notes = 0
        total_words = 0
        total_chars = 0
        total_sentences = 0
        total_paragraphs = 0
        notes_this_week = 0
        notes_this_month = 0
        collection_stats = []
        
        # Calculate date thresholds
        now = datetime.now()
        week_ago = now - timedelta(days=7)
        month_ago = now - timedelta(days=30)
        
        for collection_name in self._collections:
            collection_file = self.get_collection_file_path(collection_name)
            notes_count = 0
            words_count = 0
            chars_count = 0
            
            try:
                if os.path.exists(collection_file):
                    with open(collection_file, 'r', encoding='utf-8') as f:
                        notes = json.load(f)
                        if isinstance(notes, list):
                            notes_count = len(notes)
                            for note in notes:
                                if isinstance(note, dict) and 'content' in note:
                                    content = note['content']
                                    chars_count += len(content)
                                    words_in_note = len(content.split()) if content.strip() else 0
                                    words_count += words_in_note
                                    
                                    # Count sentences and paragraphs
                                    total_sentences += len([s for s in re.split(r'[.!?]+', content) if s.strip()])
                                    total_paragraphs += len([p for p in content.split('\n\n') if p.strip()])
                                    
                                    # Check creation date for recent notes
                                    if 'created' in note:
                                        try:
                                            created_date = datetime.fromisoformat(note['created'])
                                            if created_date >= week_ago:
                                                notes_this_week += 1
                                            if created_date >= month_ago:
                                                notes_this_month += 1
                                        except:
                                            pass
                                            
            except Exception as e:
                print(f"Error reading collection {collection_name}: {e}")
            
            collection_stats.append({
                "name": collection_name,
                "notes": notes_count,
                "words": words_count,
                "chars": chars_count,
                "isCurrent": collection_name == self._current_collection
            })
            
            total_notes += notes_count
            total_words += words_count
            total_chars += chars_count
        
        
        return {
            "totalNotes": total_notes,
            "totalWords": total_words,
            "totalChars": total_chars,
            "totalSentences": total_sentences,
            "totalParagraphs": total_paragraphs,
            "notesThisWeek": notes_this_week,
            "notesThisMonth": notes_this_month,
            "collections": collection_stats,
            "collectionsCount": len(self._collections)
        }
    
    @Slot(int, result='QVariant')
    def getNoteStats(self, note_id):
        """Get statistics for a specific note with literary-focused metrics"""
        note = self.getNote(note_id)
        if not note:
            return {}
        
        content = note.get('content', '')
        title = note.get('title', '')
        
        # Basic stats
        char_count = len(content)
        char_count_no_spaces = len(content.replace(' ', ''))
        word_count = len(content.split()) if content.strip() else 0
        line_count = content.count('\n') + 1 if content else 0
        paragraph_count = len([p for p in content.split('\n\n') if p.strip()]) if content.strip() else 0
        
        # Literary-focused stats
        sentence_count = len([s for s in re.split(r'[.!?]+', content) if s.strip()])
        
        # Average word length (helpful for readability)
        words = content.split()
        avg_word_length = sum(len(word.strip('.,!?;:"()[]{}')) for word in words) / len(words) if words else 0
        
        # Average sentence length
        avg_sentence_length = word_count / sentence_count if sentence_count > 0 else 0
        
        # Dialogue detection (rough estimate)
        dialogue_lines = len([line for line in content.split('\n') if line.strip().startswith('"') or line.strip().startswith("'")])
        
        # Unique words count (vocabulary richness)
        unique_words = len(set(word.lower().strip('.,!?;:"()[]{}') for word in words if word.strip('.,!?;:"()[]{}')))
        lexical_diversity = unique_words / word_count if word_count > 0 else 0
        
        # Most common words (excluding common articles/prepositions)
        stop_words = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'is', 'are', 'was', 'were', 'be', 'been', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'this', 'that', 'these', 'those'}
        content_words = [word.lower().strip('.,!?;:"()[]{}') for word in words if word.lower().strip('.,!?;:"()[]{}') not in stop_words and len(word.strip('.,!?;:"()[]{}')) > 2]
        
        word_freq = {}
        for word in content_words:
            word_freq[word] = word_freq.get(word, 0) + 1
        
        # Get top 3 most frequent words - convert tuples to lists for QML compatibility
        most_common = [[word, count] for word, count in sorted(word_freq.items(), key=lambda x: x[1], reverse=True)[:3]]
        
        # Reading time estimates
        reading_time_minutes = word_count / 200 if word_count > 0 else 0  # Silent reading
        speaking_time_minutes = word_count / 150 if word_count > 0 else 0  # Speaking pace
        
        # Writing time estimate (rough - varies greatly by person and content type)
        # Assume 20-30 words per minute for thoughtful writing
        estimated_writing_time = word_count / 25 if word_count > 0 else 0
        
        return {
            "title": title,
            "chars": char_count,
            "charsNoSpaces": char_count_no_spaces,
            "words": word_count,
            "uniqueWords": unique_words,
            "lines": line_count,
            "paragraphs": paragraph_count,
            "sentences": sentence_count,
            "dialogueLines": dialogue_lines,
            "averageWordLength": round(avg_word_length, 1),
            "averageSentenceLength": round(avg_sentence_length, 1),
            "lexicalDiversity": round(lexical_diversity, 3),
            "readingTimeMinutes": reading_time_minutes,
            "speakingTimeMinutes": speaking_time_minutes,
            "estimatedWritingTimeMinutes": estimated_writing_time,
            "mostCommonWords": most_common,
            "created": note.get('created', ''),
            "modified": note.get('modified', '')
        }
    
def main():
    app = QGuiApplication(sys.argv)
    QQuickStyle.setStyle("Basic")
    
    engine = QQmlApplicationEngine()
    notes_manager = NotesManager()
    
    engine.rootContext().setContextProperty("notesManager", notes_manager)
    engine.load(QUrl.fromLocalFile("main.qml"))
    
    if not engine.rootObjects():
        return -1
    
    return app.exec()

if __name__ == "__main__":
    sys.exit(main())