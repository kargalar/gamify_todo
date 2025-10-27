import 'package:flutter/material.dart';
import 'package:next_level/Model/note_model.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Service/notes_service.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Provider/category_provider.dart';

/// Notları ve kategorileri yöneten Provider
class NotesProvider with ChangeNotifier {
  static final NotesProvider _instance = NotesProvider._internal();

  factory NotesProvider() {
    return _instance;
  }

  NotesProvider._internal() {
    loadData();
  }

  final NotesService _notesService = NotesService();

  // State
  List<NoteModel> _notes = [];
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _showArchivedOnly = false;

  // Getters
  List<NoteModel> get notes => _notes;
  List<CategoryModel> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get showArchivedOnly => _showArchivedOnly;
  CategoryModel? get selectedCategory {
    if (_selectedCategoryId == null) return null;
    try {
      return _categories.firstWhere((cat) => cat.id == _selectedCategoryId);
    } catch (e) {
      return null;
    }
  }

  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Filtrelenmiş notlar
  List<NoteModel> get filteredNotes {
    var filtered = _notes;

    // Arşiv filtreleme
    if (_showArchivedOnly) {
      filtered = filtered.where((note) => note.isArchived).toList();
    } else {
      filtered = filtered.where((note) => !note.isArchived).toList();
    }

    // Kategori filtreleme
    if (_selectedCategoryId != null) {
      filtered = filtered.where((note) => note.categoryId == _selectedCategoryId).toList();
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      filtered = filtered.where((note) {
        return note.title.toLowerCase().contains(queryLower) || note.content.toLowerCase().contains(queryLower);
      }).toList();
    }

    return filtered;
  }

  /// Sabitlenmiş notlar
  List<NoteModel> get pinnedNotes {
    final pinned = filteredNotes.where((note) => note.isPinned).toList();
    // sortOrder'a göre sırala (yüksek değer = üstte)
    pinned.sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
    return pinned;
  }

  /// Sabitlenmemiş notlar
  List<NoteModel> get unpinnedNotes {
    final unpinned = filteredNotes.where((note) => !note.isPinned).toList();
    // sortOrder'a göre sırala (yüksek değer = üstte)
    unpinned.sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
    return unpinned;
  }

  /// Kategoriye göre not sayıları
  Map<String, int> get noteCounts {
    final counts = <String, int>{};
    for (var category in _categories) {
      counts[category.id] = _notes.where((note) => note.categoryId == category.id).length;
    }
    return counts;
  }

  /// Verileri yükle (notlar ve kategoriler)
  Future<void> loadData() async {
    try {
      LogService.debug('📡 NotesProvider: Loading data from Hive');
      _setLoading(true);
      _setError(null);

      await _notesService.initialize();
      await CategoryProvider().initialize();

      _notes = await _notesService.getNotes();
      // SADECE NOTE TİPİNDEKİ KATEGORİLERİ YÜKLEYELİM
      _categories = CategoryProvider().categoryList.where((cat) => cat.categoryType == CategoryType.note).toList();

      LogService.debug('✅ NotesProvider: Loaded ${_notes.length} notes and ${_categories.length} note categories');
    } catch (e) {
      LogService.error('❌ NotesProvider: Error loading data: $e');
      _setError('Veriler yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Notları yükle
  Future<void> loadNotes() async {
    try {
      LogService.debug('📡 NotesProvider: Loading notes from Hive');
      _setLoading(true);
      _setError(null);

      await _notesService.initialize();
      _notes = await _notesService.getNotes();

      LogService.debug('✅ NotesProvider: Loaded ${_notes.length} notes');
      _setLoading(false);
    } catch (e) {
      LogService.error('❌ NotesProvider: Error loading notes: $e');
      _setError('Notlar yüklenirken hata oluştu: $e');
      _setLoading(false);
    }
  }

  /// Kategori seç
  void selectCategory(String? categoryId) {
    LogService.debug('🔖 NotesProvider: Category selected: $categoryId');
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// Arama sorgusu güncelle
  void updateSearchQuery(String query) {
    LogService.debug('🔍 NotesProvider: Search query updated: $query');
    _searchQuery = query;
    notifyListeners();
  }

  /// Arama sorgusunu temizle
  void clearSearchQuery() {
    LogService.debug('🧹 NotesProvider: Search query cleared');
    _searchQuery = '';
    notifyListeners();
  }

  /// Yeni not ekle
  Future<bool> addNote({
    required String title,
    String content = '',
    String? categoryId,
    int colorIndex = 0,
  }) async {
    try {
      LogService.debug('➕ NotesProvider: Adding new note: $title');
      _setError(null);

      final now = DateTime.now();
      // En yüksek sortOrder değerini bul ve 1 ekle (yeni not en üstte olacak)
      final maxSortOrder = _notes.isEmpty ? 0 : _notes.map((n) => n.sortOrder).reduce((a, b) => a > b ? a : b);

      final note = NoteModel(
        title: title,
        content: content,
        categoryId: categoryId,
        colorIndex: colorIndex,
        createdAt: now,
        updatedAt: now,
        isPinned: false,
        sortOrder: maxSortOrder + 1,
      );

      final success = await _notesService.addNote(note);

      if (success) {
        await loadData(); // Listeyi yenile
        LogService.debug('✅ NotesProvider: Note added successfully with sortOrder: ${note.sortOrder}');
      } else {
        LogService.debug('❌ NotesProvider: Failed to add note');
        _setError('Not eklenemedi');
      }

      return success;
    } catch (e) {
      LogService.error('❌ NotesProvider: Error adding note: $e');
      _setError('Not eklenirken hata oluştu: $e');
      return false;
    }
  }

  /// Notu güncelle
  Future<bool> updateNote(NoteModel note) async {
    try {
      LogService.debug('🔄 NotesProvider: Updating note: ${note.id}');
      _setError(null);

      final success = await _notesService.updateNote(note);

      if (success) {
        await loadData(); // Listeyi yenile
        LogService.debug('✅ NotesProvider: Note updated successfully');
      } else {
        LogService.debug('❌ NotesProvider: Failed to update note');
        _setError('Not güncellenemedi');
      }

      return success;
    } catch (e) {
      LogService.error('❌ NotesProvider: Error updating note: $e');
      _setError('Not güncellenirken hata oluştu: $e');
      return false;
    }
  }

  /// Notu sil
  Future<bool> deleteNote(int noteId) async {
    try {
      LogService.debug('🗑️ NotesProvider: Deleting note: $noteId');
      _setError(null);

      final success = await _notesService.deleteNote(noteId);

      if (success) {
        await loadData(); // Listeyi yenile
        LogService.debug('✅ NotesProvider: Note deleted successfully');
      } else {
        LogService.debug('❌ NotesProvider: Failed to delete note');
        _setError('Not silinemedi');
      }

      return success;
    } catch (e) {
      LogService.error('❌ NotesProvider: Error deleting note: $e');
      _setError('Not silinirken hata oluştu: $e');
      return false;
    }
  }

  /// Notu sabitle/sabitliği kaldır
  Future<bool> togglePinNote(int noteId, bool isPinned) async {
    try {
      LogService.debug('📌 NotesProvider: Toggling pin for note: $noteId to $isPinned');
      _setError(null);

      final success = await _notesService.togglePinNote(noteId, isPinned);

      if (success) {
        await loadData(); // Listeyi yenile
        LogService.debug('✅ NotesProvider: Note pin toggled successfully');
      } else {
        LogService.debug('❌ NotesProvider: Failed to toggle note pin');
        _setError('Note pin status could not be changed');
      }

      return success;
    } catch (e) {
      LogService.error('❌ NotesProvider: Error toggling note pin: $e');
      _setError('Error changing note pin status: $e');
      return false;
    }
  }

  /// Tek bir notu getir
  Future<NoteModel?> getNote(int noteId) async {
    try {
      LogService.debug('📖 NotesProvider: Getting note: $noteId');
      _setError(null);

      final note = await _notesService.getNote(noteId);

      if (note != null) {
        LogService.debug('✅ NotesProvider: Note retrieved successfully');
      } else {
        LogService.debug('⚠️ NotesProvider: Note not found');
        _setError('Not bulunamadı');
      }

      return note;
    } catch (e) {
      LogService.error('❌ NotesProvider: Error getting note: $e');
      _setError('Not getirilirken hata oluştu: $e');
      return null;
    }
  }

  /// Kategori ekle
  Future<bool> addCategory(CategoryModel category) async {
    try {
      LogService.debug('➕ NotesProvider: Adding category: ${category.title}');
      await CategoryProvider().addCategory(category);

      // Kategoriyi listeye hemen ekle
      _categories.add(category);

      // UI'ı hemen güncelle
      notifyListeners();

      LogService.debug('✅ NotesProvider: Category added successfully');
      return true;
    } catch (e) {
      LogService.error('❌ NotesProvider: Error adding category: $e');
      _setError('Kategori eklenirken hata oluştu: $e');
      return false;
    }
  }

  /// Kategori güncelle
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      LogService.debug('🔄 NotesProvider: Updating category: ${category.id}');
      CategoryProvider().updateCategory(category);

      // Kategoriyi listede güncelle
      final index = _categories.indexWhere((cat) => cat.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      }

      // UI'ı hemen güncelle
      notifyListeners();

      LogService.debug('✅ NotesProvider: Category updated successfully');
      return true;
    } catch (e) {
      LogService.error('❌ NotesProvider: Error updating category: $e');
      _setError('Kategori güncellenirken hata oluştu: $e');
      return false;
    }
  }

  /// Kategori sil
  Future<bool> deleteCategory(String categoryId) async {
    try {
      LogService.debug('🗑️ NotesProvider: Deleting category: $categoryId');

      // Bu kategoriye ait notları kontrol et
      final notesInCategory = _notes.where((note) => note.categoryId == categoryId).toList();
      if (notesInCategory.isNotEmpty) {
        LogService.debug('⚠️ NotesProvider: Category has ${notesInCategory.length} notes, deleting them first');
        // Kategoriye ait tüm notları sil
        for (final note in notesInCategory) {
          await _notesService.deleteNote(note.id);
          _notes.removeWhere((n) => n.id == note.id); // Listeden hemen kaldır
        }
      }

      final category = CategoryProvider().getCategoryById(categoryId);
      if (category != null) {
        await CategoryProvider().deleteCategory(category);

        // Kategoriyi listeden hemen kaldır
        _categories.removeWhere((cat) => cat.id == categoryId);

        if (_selectedCategoryId == categoryId) {
          _selectedCategoryId = null;
        }

        // UI'ı hemen güncelle
        notifyListeners();

        LogService.debug('✅ NotesProvider: Category deleted successfully');
        return true;
      } else {
        LogService.debug('❌ NotesProvider: Category not found');
        _setError('Kategori bulunamadı');
        return false;
      }
    } catch (e) {
      LogService.error('❌ NotesProvider: Error deleting category: $e');
      _setError('Kategori silinirken hata oluştu: $e');
      return false;
    }
  }

  /// Kategoriye göre not al
  CategoryModel? getCategoryById(String? categoryId) {
    if (categoryId == null) return null;
    try {
      return _categories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Change archive filter
  void toggleArchivedFilter() {
    LogService.debug('📦 NotesProvider: Toggling archived filter - current: $_showArchivedOnly');
    _showArchivedOnly = !_showArchivedOnly;
    notifyListeners();
    LogService.debug('✅ NotesProvider: Archived filter toggled - new: $_showArchivedOnly');
  }

  /// Archive/unarchive note
  Future<bool> toggleArchiveNote(int noteId) async {
    try {
      LogService.debug('📦 NotesProvider: Toggling archive for noteId: $noteId');
      _setError(null);

      final success = await _notesService.toggleArchiveNote(noteId);

      if (success) {
        await loadData();
        LogService.debug('✅ NotesProvider: Note archive toggled successfully');
      } else {
        LogService.debug('❌ NotesProvider: Failed to toggle archive note');
        _setError('Note could not be archived');
      }

      return success;
    } catch (e) {
      LogService.error('❌ NotesProvider: Error toggling archive note - $e');
      _setError('Error archiving note: $e');
      return false;
    }
  }

  /// Notların sırasını değiştir (sürükle-bırak için)
  Future<bool> reorderNotes({
    required int oldIndex,
    required int newIndex,
    required bool isPinnedList,
  }) async {
    try {
      LogService.debug('🔄 NotesProvider: Reordering notes from $oldIndex to $newIndex (pinned: $isPinnedList)');
      _setError(null);

      // Doğru listeyi al
      final notesList = List<NoteModel>.from(isPinnedList ? pinnedNotes : unpinnedNotes);

      if (oldIndex >= notesList.length || newIndex >= notesList.length || oldIndex < 0 || newIndex < 0) {
        LogService.error('❌ NotesProvider: Invalid reorder indices - oldIndex: $oldIndex, newIndex: $newIndex, listLength: ${notesList.length}');
        return false;
      }

      // Taşınacak notu listeden çıkar
      final movedNote = notesList.removeAt(oldIndex);

      // Yeni pozisyona ekle
      notesList.insert(newIndex, movedNote);

      LogService.debug('  � New order after move:');
      for (var i = 0; i < notesList.length; i++) {
        LogService.debug('    $i: Note ${notesList[i].id} - ${notesList[i].title}');
      }

      // Tüm listeye yeni sortOrder değerleri ata
      // En üstteki not en yüksek değere sahip olacak

      // Önce tüm notları lokal olarak güncelle (optimistik UI güncellemesi)
      final updatedNotes = <NoteModel>[];
      for (int i = 0; i < notesList.length; i++) {
        final note = notesList[i];
        final newSortOrder = notesList.length - i; // Tersten sıralama

        if (note.sortOrder != newSortOrder) {
          final updatedNote = note.copyWith(
            sortOrder: newSortOrder,
            updatedAt: DateTime.now(),
          );
          updatedNotes.add(updatedNote);

          // Lokal listeyi hemen güncelle
          final mainIndex = _notes.indexWhere((n) => n.id == note.id);
          if (mainIndex != -1) {
            _notes[mainIndex] = updatedNote;
          }

          LogService.debug('  ✏️ Updated Note ${note.id}: sortOrder ${note.sortOrder} → $newSortOrder');
        }
      }

      // UI'ı hemen güncelle (kullanıcı anında değişikliği görsün)
      notifyListeners();
      LogService.debug('  🎨 UI updated immediately');

      // Ardından veritabanına kaydet (arka planda)
      for (final updatedNote in updatedNotes) {
        await _notesService.updateNote(updatedNote);
      }

      LogService.debug('✅ NotesProvider: Notes reordered and saved successfully');
      return true;
    } catch (e) {
      LogService.error('❌ NotesProvider: Error reordering notes: $e');
      _setError('Not sıralaması değiştirilirken hata oluştu: $e');
      // Hata durumunda listeyi yeniden yükle
      await loadData();
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    if (error != null) {
      notifyListeners();
    }
  }

  void clearAllNotes() {
    _notes.clear();
    _categories.clear();
    _selectedCategoryId = null;
    _searchQuery = '';
    _showArchivedOnly = false;
    notifyListeners();
  }
}
