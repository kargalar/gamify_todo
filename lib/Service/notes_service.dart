import 'package:hive_flutter/hive_flutter.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Model/note_model.dart';

/// Notlar için Hive işlemleri
class NotesService {
  static final NotesService _instance = NotesService._internal();
  factory NotesService() => _instance;
  NotesService._internal();

  static const String _boxName = 'notes';
  Box<NoteModel>? _notesBox;

  /// Hive box'ını aç
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _notesBox = await Hive.openBox<NoteModel>(_boxName);
        LogService.debug('✅ NotesService: Hive box opened successfully');

        // Migration: Mevcut notlara sortOrder ata
        await _migrateSortOrder();
      } else {
        _notesBox = Hive.box<NoteModel>(_boxName);
        LogService.debug('✅ NotesService: Hive box already open');
      }
    } catch (e) {
      LogService.error('❌ NotesService: Error opening Hive box: $e');
      LogService.debug('🔄 NotesService: Attempting to delete corrupted box and recreate...');

      try {
        // Eğer box açıksa önce kapat
        if (Hive.isBoxOpen(_boxName)) {
          await Hive.box<NoteModel>(_boxName).close();
        }

        // Bozuk box'ı sil
        await Hive.deleteBoxFromDisk(_boxName);
        LogService.debug('🗑️ NotesService: Corrupted box deleted');

        // Yeni box oluştur
        _notesBox = await Hive.openBox<NoteModel>(_boxName);
        LogService.debug('✅ NotesService: New box created successfully');
      } catch (e2) {
        LogService.error('❌ NotesService: Failed to recreate box: $e2');
      }
    }
  }

  /// Mevcut notlara sortOrder değeri ata (migration)
  Future<void> _migrateSortOrder() async {
    try {
      if (_notesBox == null) return;

      final notes = _notesBox!.values.toList();

      if (notes.isEmpty) {
        LogService.debug('✅ NotesService: No notes to migrate');
        return;
      }

      bool needsMigration = false;

      // sortOrder 0 olan notları kontrol et
      for (var note in notes) {
        if (note.sortOrder == 0) {
          needsMigration = true;
          break;
        }
      }

      if (!needsMigration) {
        LogService.debug('✅ NotesService: sortOrder migration not needed');
        return;
      }

      LogService.debug('🔄 NotesService: Starting sortOrder migration for ${notes.length} notes');

      // Notları tarihe göre sırala (yeni -> eski)
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Her nota sıralı sortOrder değeri ata (en yeni not en yüksek değer alacak)
      for (int i = 0; i < notes.length; i++) {
        final note = notes[i];
        final newSortOrder = notes.length - i; // Tersine sıralama
        note.sortOrder = newSortOrder;
        await _notesBox!.put(note.id, note);
        LogService.debug('  📝 Note ${note.id}: sortOrder set to $newSortOrder');
      }

      LogService.debug('✅ NotesService: sortOrder migration completed for ${notes.length} notes');
    } catch (e) {
      LogService.error('❌ NotesService: Error during sortOrder migration: $e');
      // Migration hatası uygulamayı durdurmamalı
    }
  }

  /// Tüm notları getir
  Future<List<NoteModel>> getNotes() async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ NotesService: Notes box is null');
        return [];
      }

      final notes = _notesBox!.values.toList();
      // Sabitlenmiş ve güncellenmiş tarihe göre sırala
      notes.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });

      LogService.debug('✅ NotesService: Loaded ${notes.length} notes');
      return notes;
    } catch (e) {
      LogService.error('❌ NotesService: Error getting notes: $e');
      return [];
    }
  }

  /// Kategoriye göre notları getir
  Future<List<NoteModel>> getNotesByCategory(String? categoryId) async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ NotesService: Notes box is null');
        return [];
      }

      if (categoryId == null) {
        return getNotes(); // Tüm notları döndür
      }

      final notes = _notesBox!.values.where((note) => note.categoryId == categoryId).toList();

      // Sabitlenmiş ve güncellenmiş tarihe göre sırala
      notes.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });

      LogService.debug('✅ NotesService: Loaded ${notes.length} notes for category: $categoryId');
      return notes;
    } catch (e) {
      LogService.error('❌ NotesService: Error getting notes by category: $e');
      return [];
    }
  }

  /// Yeni not ekle
  Future<bool> addNote(NoteModel note) async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ NotesService: Cannot add note - box is null');
        return false;
      }

      // Yeni ID oluştur (eğer ID 0 ise)
      if (note.id == 0) {
        final lastId = _notesBox!.values.isEmpty ? 0 : _notesBox!.values.map((n) => n.id).reduce((a, b) => a > b ? a : b);
        note.id = lastId + 1;
      }

      LogService.debug('➕ NotesService: Adding new note with ID: ${note.id}');

      await _notesBox!.put(note.id, note);

      LogService.debug('✅ NotesService: Note added successfully with ID: ${note.id}');
      return true;
    } catch (e) {
      LogService.error('❌ NotesService: Error adding note: $e');
      return false;
    }
  }

  /// Notu güncelle
  Future<bool> updateNote(NoteModel note) async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ NotesService: Cannot update note - box is null');
        return false;
      }

      LogService.debug('🔄 NotesService: Updating note: ${note.id}');

      // updatedAt'i güncelle
      note.updatedAt = DateTime.now();

      await _notesBox!.put(note.id, note);

      LogService.debug('✅ NotesService: Note updated successfully: ${note.id}');
      return true;
    } catch (e) {
      LogService.error('❌ NotesService: Error updating note: $e');
      return false;
    }
  }

  /// Notu sil
  Future<bool> deleteNote(int noteId) async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ NotesService: Cannot delete note - box is null');
        return false;
      }

      LogService.debug('🗑️ NotesService: Deleting note: $noteId');

      await _notesBox!.delete(noteId);

      LogService.debug('✅ NotesService: Note deleted successfully: $noteId');
      return true;
    } catch (e) {
      LogService.error('❌ NotesService: Error deleting note: $e');
      return false;
    }
  }

  /// Notu sabitle/sabitliği kaldır
  Future<bool> togglePinNote(int noteId, bool isPinned) async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ NotesService: Cannot toggle pin - box is null');
        return false;
      }

      LogService.debug('📌 NotesService: Toggling pin for note: $noteId to $isPinned');

      final note = _notesBox!.get(noteId);
      if (note == null) {
        LogService.debug('❌ NotesService: Note not found: $noteId');
        return false;
      }

      note.isPinned = isPinned;
      note.updatedAt = DateTime.now();
      await note.save();

      LogService.debug('✅ NotesService: Note pin toggled successfully: $noteId');
      return true;
    } catch (e) {
      LogService.error('❌ NotesService: Error toggling pin: $e');
      return false;
    }
  }

  /// Archive/unarchive note
  Future<bool> toggleArchiveNote(int noteId) async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ NotesService: Cannot toggle archive - box is null');
        return false;
      }

      LogService.debug('📦 NotesService: Toggling archive for note: $noteId');

      final note = _notesBox!.get(noteId);
      if (note == null) {
        LogService.debug('❌ NotesService: Note not found: $noteId');
        return false;
      }

      note.isArchived = !note.isArchived;
      note.updatedAt = DateTime.now();
      await note.save();

      LogService.debug('✅ NotesService: Note archive toggled successfully: $noteId - isArchived: ${note.isArchived}');
      return true;
    } catch (e) {
      LogService.error('❌ NotesService: Error toggling archive: $e');
      return false;
    }
  }

  /// Tek bir notu getir
  Future<NoteModel?> getNote(int noteId) async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ NotesService: Cannot get note - box is null');
        return null;
      }

      LogService.debug('📖 NotesService: Getting note: $noteId');

      final note = _notesBox!.get(noteId);

      if (note == null) {
        LogService.debug('⚠️ NotesService: Note not found: $noteId');
        return null;
      }

      LogService.debug('✅ NotesService: Note retrieved successfully: $noteId');
      return note;
    } catch (e) {
      LogService.error('❌ NotesService: Error getting note: $e');
      return null;
    }
  }

  /// Arama yap
  Future<List<NoteModel>> searchNotes(String query) async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ NotesService: Cannot search notes - box is null');
        return [];
      }

      if (query.isEmpty) {
        LogService.debug('⚠️ NotesService: Empty search query');
        return [];
      }

      LogService.debug('🔍 NotesService: Searching notes with query: $query');

      final queryLower = query.toLowerCase();
      final notes = _notesBox!.values.where((note) {
        return note.title.toLowerCase().contains(queryLower) || note.content.toLowerCase().contains(queryLower);
      }).toList();

      // Sırala
      notes.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });

      LogService.debug('✅ NotesService: Found ${notes.length} notes matching query');
      return notes;
    } catch (e) {
      LogService.error('❌ NotesService: Error searching notes: $e');
      return [];
    }
  }

  /// Box'ı kapat
  Future<void> close() async {
    try {
      if (_notesBox != null && _notesBox!.isOpen) {
        await _notesBox!.close();
        LogService.debug('✅ NotesService: Hive box closed');
      }
    } catch (e) {
      LogService.error('❌ NotesService: Error closing Hive box: $e');
    }
  }

  /// Tüm notları sil
  Future<void> clearAllNotes() async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ NotesService: Cannot clear notes - box is null');
        return;
      }
      await _notesBox!.clear();
      LogService.debug('✅ NotesService: All notes cleared');
    } catch (e) {
      LogService.error('❌ NotesService: Error clearing notes: $e');
    }
  }
}
