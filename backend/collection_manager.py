from PySide6.QtCore import Signal, Slot, Property
from .base_manager import BaseManager
import os
import re
from datetime import datetime


class CollectionManager(BaseManager):
    """Manages collections (notebooks) of notes"""
    
    collectionsChanged = Signal()
    currentCollectionChanged = Signal()
    
    def __init__(self, config_manager):
        super().__init__()
        self.config_manager = config_manager
        self.collections_dir = "data/collections"
        self.collections_file = "data/collections.json"
        
        # Collections state
        self._collections = []
        self._current_collection = ""
        self._collection_settings = {}  # Per-collection layout settings
        
        # Initialize
        self.ensure_directory_exists("data")
        self.ensure_directory_exists(self.collections_dir)
        self.load_collections()
    
    def get_collection_file_path(self, collection_name):
        """Get the file path for a collection with proper sanitization"""
        # Remove invalid filename characters and limit length
        safe_name = re.sub(r'[<>:"/\\|?*]', '_', collection_name)
        safe_name = safe_name.strip()[:50]  # Limit filename length
        if not safe_name:
            safe_name = "Unnamed"
        
        file_path = os.path.join(self.collections_dir, f"{safe_name}.json")
        return file_path
    
    def create_collection_file(self, collection_name):
        """Create a collection file with proper error handling"""
        collection_file = self.get_collection_file_path(collection_name)
        
        try:
            # Ensure the directory exists
            os.makedirs(os.path.dirname(collection_file), exist_ok=True)
            
            # Create the file with empty array
            if self.atomic_write_json([], collection_file):
                return True
            return False
            
        except PermissionError:
            error_msg = f"Permission denied creating collection file: {collection_file}"
            self.error.emit(error_msg)
            return False
        except Exception as e:
            error_msg = f"Error creating collection file '{collection_file}': {e}"
            self.error.emit(error_msg)
            return False
    
    def ensure_all_collection_files_exist(self):
        """Ensure all collections have corresponding JSON files"""
        for collection_name in self._collections:
            collection_file = self.get_collection_file_path(collection_name)
            
            if not os.path.exists(collection_file):
                self.create_collection_file(collection_name)
    
    def needs_first_collection_setup(self):
        """Check if we need to prompt user for first collection"""
        return len(self._collections) == 0 or self._current_collection == ""
    
    def load_collections(self):
        """Load collections metadata, creating defaults if missing"""
        collections_data = self.read_json_file(self.collections_file, {
            "collections": [],
            "currentCollection": "",
            "collectionSettings": {}
        })
        
        self._collections = collections_data.get("collections", [])
        self._current_collection = collections_data.get("currentCollection", "")
        self._collection_settings = collections_data.get("collectionSettings", {})
                
        # Ensure current collection exists in the list (if we have collections)
        if self._collections and self._current_collection not in self._collections:
            self._current_collection = self._collections[0] if self._collections else ""
        
        # Initialize collection settings for existing collections that don't have them
        for collection_name in self._collections:
            if collection_name not in self._collection_settings:
                self._collection_settings[collection_name] = {
                    "cardWidth": self.config_manager.get_value("cardWidth", 381),
                    "cardHeight": self.config_manager.get_value("cardHeight", 120),
                    "preferredColumns": 1  # Default to 1 column
                }
            else:
                # Ensure existing collections have all required settings
                settings = self._collection_settings[collection_name]
                if "cardHeight" not in settings:
                    settings["cardHeight"] = self.config_manager.get_value("cardHeight", 120)
                if "preferredColumns" not in settings:
                    settings["preferredColumns"] = 1
                    
        # Apply the current collection's layout settings to global config
        if self._current_collection and self._current_collection in self._collection_settings:
            collection_settings = self._collection_settings[self._current_collection]
            if "cardWidth" in collection_settings:
                self.config_manager.set_value("cardWidth", collection_settings["cardWidth"])
            if "cardHeight" in collection_settings:
                self.config_manager.set_value("cardHeight", collection_settings["cardHeight"])
    
    def save_collections(self):
        """Save collections metadata"""
        collections_data = {
            "collections": self._collections,
            "currentCollection": self._current_collection,
            "collectionSettings": self._collection_settings
        }
        
        return self.atomic_write_json(collections_data, self.collections_file)
    
    def get_current_collection_card_width(self):
        """Get the card width for the current collection"""
        if not self._current_collection:
            return self.config_manager.get_value("cardWidth", 381)
        
        if self._current_collection not in self._collection_settings:
            # Initialize settings for this collection
            self._collection_settings[self._current_collection] = {
                "cardWidth": self.config_manager.get_value("cardWidth", 381),
                "cardHeight": self.config_manager.get_value("cardHeight", 120),
                "preferredColumns": 1  # Default to 1 column
            }
        
        return self._collection_settings[self._current_collection].get("cardWidth", 381)

    def get_current_collection_card_height(self):
        """Get the card height for the current collection"""
        if not self._current_collection:
            return self.config_manager.get_value("cardHeight", 120)
        
        if self._current_collection not in self._collection_settings:
            # Initialize settings for this collection
            self._collection_settings[self._current_collection] = {
                "cardWidth": self.config_manager.get_value("cardWidth", 381),
                "cardHeight": self.config_manager.get_value("cardHeight", 120),
                "preferredColumns": 1  # Default to 1 column
            }
        
        return self._collection_settings[self._current_collection].get("cardHeight", 120)

    def get_current_collection_preferred_columns(self):
        """Get the preferred column count for the current collection"""
        if not self._current_collection:
            return 1
        
        if self._current_collection not in self._collection_settings:
            # Initialize settings for this collection
            self._collection_settings[self._current_collection] = {
                "cardWidth": self.config_manager.get_value("cardWidth", 381),
                "cardHeight": self.config_manager.get_value("cardHeight", 120),
                "preferredColumns": 1  # Default to 1 column
            }
        
        return self._collection_settings[self._current_collection].get("preferredColumns", 1)

    def set_current_collection_preferred_columns(self, columns):
        """Set the preferred column count for the current collection"""
        if not self._current_collection:
            return
        
        if self._current_collection not in self._collection_settings:
            self._collection_settings[self._current_collection] = {
                "cardWidth": self.config_manager.get_value("cardWidth", 381),
                "cardHeight": self.config_manager.get_value("cardHeight", 120),
                "preferredColumns": 1
            }
        
        self._collection_settings[self._current_collection]["preferredColumns"] = columns
        self.save_collections()

    def set_current_collection_card_width(self, width):
        """Set the card width for the current collection"""
        if not self._current_collection:
            return
        
        if self._current_collection not in self._collection_settings:
            self._collection_settings[self._current_collection] = {
                "cardHeight": self.config_manager.get_value("cardHeight", 120)
            }
        
        self._collection_settings[self._current_collection]["cardWidth"] = width
        
        # Also update the global config for immediate UI update
        self.config_manager.set_value("cardWidth", width)
        
        # Save collections
        self.save_collections()

    def set_current_collection_card_height(self, height):
        """Set the card height for the current collection"""
        if not self._current_collection:
            return
        
        if self._current_collection not in self._collection_settings:
            self._collection_settings[self._current_collection] = {
                "cardWidth": self.config_manager.get_value("cardWidth", 381),
                "cardHeight": self.config_manager.get_value("cardHeight", 120),
                "preferredColumns": 1  # Default to 1 column
            }
        
        self._collection_settings[self._current_collection]["cardHeight"] = height
        
        # Also update the global config for immediate UI update
        self.config_manager.set_value("cardHeight", height)
        
        # Save collections
        self.save_collections()
    
    # QML-accessible methods
    @Slot(result=bool)
    def needsFirstCollectionSetup(self):
        """QML-accessible method to check if first collection setup is needed"""
        return self.needs_first_collection_setup()

    @Slot(str, result=bool)
    def setupFirstCollection(self, name):
        """Set up the very first collection"""
        if not name.strip():
            return False
            
        clean_name = name.strip()
        
        # Initialize collections system
        self._collections = [clean_name]
        self._current_collection = clean_name
        
        # Initialize collection settings
        self._collection_settings[clean_name] = {
            "cardWidth": self.config_manager.get_value("cardWidth", 381),
            "cardHeight": self.config_manager.get_value("cardHeight", 120),
            "preferredColumns": 1  # Default to 1 column
        }
        
        # Create the collection file
        if self.create_collection_file(clean_name):
            if self.save_collections():
                self.collectionsChanged.emit()
                self.currentCollectionChanged.emit()
                return True
        
        return False

    @Slot(str, result=bool)
    def createCollection(self, name):
        """Create a new collection with proper file management"""
        if not name.strip():
            return False
            
        clean_name = name.strip()
        if clean_name in self._collections:
            return False  # Collection already exists
        
        # Add to collections list
        self._collections.append(clean_name)
        
        # Initialize collection settings with current card dimensions
        self._collection_settings[clean_name] = {
            "cardWidth": self.config_manager.get_value("cardWidth", 381),
            "cardHeight": self.config_manager.get_value("cardHeight", 120),
            "preferredColumns": 1  # Default to 1 column
        }
        
        # Create the JSON file for this collection
        if self.create_collection_file(clean_name):
            # Save collections metadata
            if self.save_collections():
                self.collectionsChanged.emit()
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
            return

        if self._current_collection != name:
            old_collection = self._current_collection
            self._current_collection = name

            # Restore layout preferences for the new collection
            new_card_width = self.get_current_collection_card_width()
            new_card_height = self.get_current_collection_card_height()
            
            layout_changed = False
            if self.config_manager.get_value("cardWidth") != new_card_width:
                self.config_manager.set_value("cardWidth", new_card_width)
                layout_changed = True
                
            if self.config_manager.get_value("cardHeight") != new_card_height:
                self.config_manager.set_value("cardHeight", new_card_height)
                layout_changed = True

            # Ensure target collection file exists
            collection_file = self.get_collection_file_path(name)
            if not os.path.exists(collection_file):
                if not self.create_collection_file(name):
                    # Revert to old collection if file creation failed
                    self._current_collection = old_collection
                    return

            # Save collections metadata
            self.save_collections()
            self.currentCollectionChanged.emit()

    @Slot(str, str)
    def switchCollectionWithSearch(self, name, search_text):
        """Switch collection while preserving search state"""
        # Note: Search text handling will be in NotesManager
        self.switchCollection(name)

    @Slot(str, result=bool)
    def deleteCollection(self, name):
        """Delete a collection and its file"""
        if len(self._collections) <= 1:
            return False  # Don't delete the last collection
            
        if name not in self._collections:
            return False
        
        # Remove from collections list
        self._collections.remove(name)
        
        # Delete the file (with backup)
        try:
            collection_file = self.get_collection_file_path(name)
            if os.path.exists(collection_file):
                # Create backup before deletion
                backup_file = f"{collection_file}.deleted_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                os.rename(collection_file, backup_file)
        except Exception as e:
            self.error.emit(f"Error deleting collection file: {e}")
        
        # If we deleted the current collection, switch to the first available
        if self._current_collection == name:
            self._current_collection = self._collections[0]
            self.currentCollectionChanged.emit()
            
        self.save_collections()
        self.collectionsChanged.emit()
        return True

    @Slot(str, str, result=bool)
    def renameCollection(self, old_name, new_name):
        """Rename a collection and its file"""
        if old_name not in self._collections or new_name.strip() == "":
            return False
            
        clean_new_name = new_name.strip()
        if clean_new_name in self._collections:
            return False  # New name already exists
        
        # Update collections list
        index = self._collections.index(old_name)
        self._collections[index] = clean_new_name
        
        # Rename the file
        try:
            old_file = self.get_collection_file_path(old_name)
            new_file = self.get_collection_file_path(clean_new_name)
            
            if os.path.exists(old_file):
                os.rename(old_file, new_file)
            else:
                # Create new file if old one doesn't exist
                self.create_collection_file(clean_new_name)
                
        except Exception as e:
            self.error.emit(f"Error renaming collection file: {e}")
            # Revert collections list change
            self._collections[index] = old_name
            return False
        
        # Update current collection if it was the renamed one
        if self._current_collection == old_name:
            self._current_collection = clean_new_name
            self.currentCollectionChanged.emit()
            
        self.save_collections()
        self.collectionsChanged.emit()
        return True

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
                    notes = self.read_json_file(collection_file, [])
                    note_count = len(notes) if isinstance(notes, list) else 0
            except Exception:
                pass  # Error reading collection
            
            info.append({
                "name": collection_name,
                "noteCount": note_count,
                "fileSize": file_size,
                "isCurrent": collection_name == self._current_collection
            })
        
        return info
    
    # Properties
    @Property(list, notify=collectionsChanged)
    def collections(self):
        return self._collections

    @Property(str, notify=currentCollectionChanged)
    def currentCollection(self):
        return self._current_collection