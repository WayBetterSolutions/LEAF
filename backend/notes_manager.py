from PySide6.QtCore import (
    QAbstractListModel, QModelIndex, Qt, Signal, Slot, Property
)
import re
import json
import os
from datetime import datetime


class NotesManager(QAbstractListModel):
    """Manages individual notes within collections"""
    
    notesChanged = Signal()
    filteredNotesChanged = Signal()
    saveError = Signal(str)
    loadError = Signal(str)
    saveSuccess = Signal()
    cardBoundsNeedUpdate = Signal()
    
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
    
    def __init__(self, collection_manager, stats_manager):
        super().__init__()
        
        self.collection_manager = collection_manager
        self.stats_manager = stats_manager
        
        # Notes state (per collection)
        self._notes = []
        self._filtered_notes = []
        self._next_id = 0
        self._search_text = ""
        self._search_regex = None
        
        # Connect to collection changes
        self.collection_manager.currentCollectionChanged.connect(self.load_notes)
        
        # Load notes for current collection if it exists
        if self.collection_manager.currentCollection:
            self.load_notes()
    
    def read_json_file(self, filepath, default_value=None):
        """Read JSON file with error handling"""
        try:
            if os.path.exists(filepath):
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read().strip()
                    if not content:
                        return default_value
                    return json.loads(content)
            return default_value
        except json.JSONDecodeError:
            self.loadError.emit(f"File {filepath} is corrupted. Creating backup...")
            return default_value
        except Exception as e:
            self.loadError.emit(f"Error reading file {filepath}: {e}")
            return default_value
    
    def atomic_write_json(self, data, filepath):
        """Write JSON data atomically using temporary file"""
        try:
            # Ensure directory exists
            os.makedirs(os.path.dirname(filepath), exist_ok=True)
            
            # Use temporary file for atomic write
            temp_file = f"{filepath}.tmp"
            with open(temp_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            
            # Atomic rename
            os.replace(temp_file, filepath)
            return True
        except Exception as e:
            self.saveError.emit(f"Error writing file {filepath}: {e}")
            return False
    
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
    
    def load_notes(self):
        """Load notes for current collection"""
        current_collection = self.collection_manager.currentCollection
        
        if not current_collection:
            self._notes = []
            self._filtered_notes = []
            self._next_id = 0
            self.beginResetModel()
            self.endResetModel()
            self.notesChanged.emit()
            self.filteredNotesChanged.emit()
            return

        notes_file = self.collection_manager.get_collection_file_path(current_collection)
        
        try:
            notes_data = self.read_json_file(notes_file, [])
            
            if not notes_data:
                self._notes = []
                self._filtered_notes = []
                self._next_id = 0
            else:
                # Validate note structure and find highest ID
                max_id = -1
                valid_notes = []
                for note in notes_data:
                    if isinstance(note, dict) and all(key in note for key in ['id', 'title', 'content']):
                        # Add missing timestamps
                        if 'created' not in note:
                            note['created'] = datetime.now().isoformat()
                        if 'modified' not in note:
                            note['modified'] = note['created']
                        valid_notes.append(note)
                        max_id = max(max_id, note['id'])
                
                self._notes = valid_notes
                self._next_id = max_id + 1
                self._filtered_notes = self._notes.copy()
                
        except Exception as e:
            self.loadError.emit(f"Error loading notes for '{current_collection}': {str(e)}")
            self._notes = []
            self._filtered_notes = []
            self._next_id = 0
        finally:
            # Reset the model to reflect the loaded notes
            self.beginResetModel()
            self.endResetModel()
            self.notesChanged.emit()
            self.filteredNotesChanged.emit()
            
            # Trigger card bounds update when notes are loaded
            self.cardBoundsNeedUpdate.emit()

    def save_notes(self):
        """Save notes for current collection"""
        current_collection = self.collection_manager.currentCollection
        
        if not current_collection:
            return False

        notes_file = self.collection_manager.get_collection_file_path(current_collection)
        
        try:
            if self.atomic_write_json(self._notes, notes_file):
                self.saveSuccess.emit()
                return True
            else:
                return False

        except PermissionError:
            msg = f"Cannot save notes for '{current_collection}' – file is locked or you lack permission."
            self.saveError.emit(msg)
            return False
        except Exception as e:
            msg = f"Error saving notes for '{current_collection}': {e}"
            self.saveError.emit(msg)
            return False
    
    # Properties
    @Property(list, notify=notesChanged)
    def notes(self):
        return self._notes
    
    @Property(list, notify=filteredNotesChanged)
    def filteredNotes(self):
        return self._filtered_notes
    
    @Property(str, notify=filteredNotesChanged)
    def searchText(self):
        return self._search_text
    
    @searchText.setter
    def searchText(self, value):
        if self._search_text != value:
            self._search_text = value
            self.updateFilteredNotes()
    
    @Property(int, notify=filteredNotesChanged)
    def noteCount(self):
        return len(self._filtered_notes)
    
    @Property(int, notify=notesChanged)
    def totalNotesInCollection(self):
        """Total number of notes in the current collection (not filtered)"""
        return len(self._notes)
    
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
        
        # Trigger card bounds recalculation when filter changes number of visible notes
        self.cardBoundsNeedUpdate.emit()
    
    @Slot(str, result=int)
    def createNote(self, content):
        """Create a note in the current collection"""
        current_collection = self.collection_manager.currentCollection
        
        if not current_collection:
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
        
        # Trigger card bounds recalculation for new note
        self.cardBoundsNeedUpdate.emit()
        return note_id
    
    @Slot(int, str)
    def updateNote(self, note_id, content):
        """Update note content in the current collection"""
        current_collection = self.collection_manager.currentCollection
        
        if not current_collection:
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
                break
    
    @Slot(int)
    def deleteNote(self, note_id):
        """Delete note from current collection"""
        current_collection = self.collection_manager.currentCollection
        
        if not current_collection:
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
        
        # Trigger card bounds recalculation after deletion
        self.cardBoundsNeedUpdate.emit()
    
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
    
    @Slot(int, result='QVariant')
    def getNoteStats(self, note_id):
        """Get statistics for a specific note"""
        note = self.getNote(note_id)
        return self.stats_manager.calculate_note_stats(note)