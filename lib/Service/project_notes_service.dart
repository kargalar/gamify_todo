import 'package:hive_flutter/hive_flutter.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Model/project_note_model.dart';

/// Proje notları için Hive işlemleri
class ProjectNotesService {
  static final ProjectNotesService _instance = ProjectNotesService._internal();
  factory ProjectNotesService() => _instance;
  ProjectNotesService._internal();

  static const String _boxName = 'project_notes';
  Box<ProjectNoteModel>? _notesBox;

  /// Hive box'ını aç
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _notesBox = await Hive.openBox<ProjectNoteModel>(_boxName);
        LogService.debug('✅ ProjectNotesService: Hive box opened successfully');
      } else {
        _notesBox = Hive.box<ProjectNoteModel>(_boxName);
        LogService.debug('✅ ProjectNotesService: Hive box already open');
      }
    } catch (e) {
      LogService.error('❌ ProjectNotesService: Error opening Hive box: $e');
    }
  }

  /// Projeye ait notları getir
  Future<List<ProjectNoteModel>> getNotesByProjectId(String projectId) async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ ProjectNotesService: Notes box is null');
        return [];
      }

      final notes = _notesBox!.values.where((note) => note.projectId == projectId).toList();

      // Oluşturulma tarihine göre sırala (yeni önce)
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      LogService.debug('✅ ProjectNotesService: Loaded ${notes.length} notes for project: $projectId');
      return notes;
    } catch (e) {
      LogService.error('❌ ProjectNotesService: Error getting notes: $e');
      return [];
    }
  }

  /// Yeni not ekle
  Future<bool> addNote(ProjectNoteModel note) async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ ProjectNotesService: Cannot add note - box is null');
        return false;
      }

      LogService.debug('➕ ProjectNotesService: Adding new note: ${note.id}');
      await _notesBox!.put(note.id, note);
      LogService.debug('✅ ProjectNotesService: Note added successfully');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectNotesService: Error adding note: $e');
      return false;
    }
  }

  /// Notu güncelle
  Future<bool> updateNote(ProjectNoteModel note) async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ ProjectNotesService: Cannot update note - box is null');
        return false;
      }

      LogService.debug('🔄 ProjectNotesService: Updating note: ${note.id}');
      note.updatedAt = DateTime.now();
      await _notesBox!.put(note.id, note);
      LogService.debug('✅ ProjectNotesService: Note updated successfully');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectNotesService: Error updating note: $e');
      return false;
    }
  }

  /// Notu sil
  Future<bool> deleteNote(String noteId) async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ ProjectNotesService: Cannot delete note - box is null');
        return false;
      }

      LogService.debug('🗑️ ProjectNotesService: Deleting note: $noteId');
      await _notesBox!.delete(noteId);
      LogService.debug('✅ ProjectNotesService: Note deleted successfully');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectNotesService: Error deleting note: $e');
      return false;
    }
  }

  /// Projeye ait tüm notları sil
  Future<bool> deleteNotesByProjectId(String projectId) async {
    try {
      await initialize();
      if (_notesBox == null) {
        LogService.error('❌ ProjectNotesService: Cannot delete notes - box is null');
        return false;
      }

      final notesToDelete = _notesBox!.values.where((note) => note.projectId == projectId).toList();

      LogService.debug('🗑️ ProjectNotesService: Deleting ${notesToDelete.length} notes for project: $projectId');

      for (var note in notesToDelete) {
        await _notesBox!.delete(note.id);
      }

      LogService.debug('✅ ProjectNotesService: All notes deleted for project');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectNotesService: Error deleting notes: $e');
      return false;
    }
  }
}
