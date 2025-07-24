from PySide6.QtCore import QObject, Signal
import json
import os
from datetime import datetime
from pathlib import Path


class BaseManager(QObject):
    """Base class for all managers with common functionality"""
    
    # Common signals
    error = Signal(str)
    success = Signal(str)
    
    def __init__(self):
        super().__init__()
    
    def ensure_directory_exists(self, directory_path):
        """Ensure a directory exists, create if it doesn't"""
        try:
            if not os.path.exists(directory_path):
                os.makedirs(directory_path)
                return True
            return True
        except Exception as e:
            self.error.emit(f"Cannot create directory {directory_path}: {e}")
            return False
    
    def backup_file(self, filepath):
        """Create a backup of the file with timestamp"""
        try:
            if os.path.exists(filepath):
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                backup_path = f"{filepath}.backup_{timestamp}"
                os.rename(filepath, backup_path)
                return backup_path
        except Exception as e:
            self.error.emit(f"Failed to create backup: {e}")
            return None
    
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
            self.error.emit(f"Error writing file {filepath}: {e}")
            return False
    
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
            self.error.emit(f"File {filepath} is corrupted. Creating backup...")
            self.backup_file(filepath)
            return default_value
        except Exception as e:
            self.error.emit(f"Error reading file {filepath}: {e}")
            return default_value