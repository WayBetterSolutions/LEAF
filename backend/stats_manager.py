from PySide6.QtCore import Signal, Slot
from .base_manager import BaseManager
import json
import os
import re
from datetime import datetime, timedelta


class StatsManager(BaseManager):
    """Manages statistics and analytics for notes"""
    
    def __init__(self, collection_manager):
        super().__init__()
        self.collection_manager = collection_manager
    
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
        
        for collection_name in self.collection_manager.collections:
            collection_file = self.collection_manager.get_collection_file_path(collection_name)
            notes_count = 0
            words_count = 0
            chars_count = 0
            
            try:
                if os.path.exists(collection_file):
                    notes = self.read_json_file(collection_file, [])
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
                pass  # Error reading collection
            
            collection_stats.append({
                "name": collection_name,
                "notes": notes_count,
                "words": words_count,
                "chars": chars_count,
                "isCurrent": collection_name == self.collection_manager.currentCollection
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
            "collectionsCount": len(self.collection_manager.collections)
        }
    
    @Slot(int, result='QVariant')
    def getNoteStats(self, note_id):
        """Get statistics for a specific note with literary-focused metrics"""
        # This method will need access to the actual note data
        # For now, return empty dict - will be implemented when notes manager is ready
        return {}
    
    def calculate_note_stats(self, note):
        """Calculate statistics for a given note"""
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