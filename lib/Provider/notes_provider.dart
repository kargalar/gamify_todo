import 'package:flutter/material.dart';
import 'package:next_level/Model/note_model.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Service/notes_service.dart';
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
    // Oluşturma tarihine göre sırala (yeniden eskiye)
    pinned.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return pinned;
  }

  /// Sabitlenmemiş notlar
  List<NoteModel> get unpinnedNotes {
    final unpinned = filteredNotes.where((note) => !note.isPinned).toList();
    // Oluşturma tarihine göre sırala (yeniden eskiye)
    unpinned.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      debugPrint('📡 NotesProvider: Loading data from Hive');
      _setLoading(true);
      _setError(null);

      await _notesService.initialize();
      await CategoryProvider().initialize();

      _notes = await _notesService.getNotes();
      // SADECE NOTE TİPİNDEKİ KATEGORİLERİ YÜKLEYELİM
      _categories = CategoryProvider().categoryList.where((cat) => cat.categoryType == CategoryType.note).toList();

      debugPrint('✅ NotesProvider: Loaded ${_notes.length} notes and ${_categories.length} note categories');
    } catch (e) {
      debugPrint('❌ NotesProvider: Error loading data: $e');
      _setError('Veriler yüklenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Notları yükle
  Future<void> loadNotes() async {
    try {
      debugPrint('📡 NotesProvider: Loading notes from Hive');
      _setLoading(true);
      _setError(null);

      await _notesService.initialize();
      _notes = await _notesService.getNotes();

      debugPrint('✅ NotesProvider: Loaded ${_notes.length} notes');
      _setLoading(false);
    } catch (e) {
      debugPrint('❌ NotesProvider: Error loading notes: $e');
      _setError('Notlar yüklenirken hata oluştu: $e');
      _setLoading(false);
    }
  }

  /// Kategori seç
  void selectCategory(String? categoryId) {
    debugPrint('🔖 NotesProvider: Category selected: $categoryId');
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// Arama sorgusu güncelle
  void updateSearchQuery(String query) {
    debugPrint('🔍 NotesProvider: Search query updated: $query');
    _searchQuery = query;
    notifyListeners();
  }

  /// Arama sorgusunu temizle
  void clearSearchQuery() {
    debugPrint('🧹 NotesProvider: Search query cleared');
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
      debugPrint('➕ NotesProvider: Adding new note: $title');
      _setError(null);

      final now = DateTime.now();
      final note = NoteModel(
        title: title,
        content: content,
        categoryId: categoryId,
        colorIndex: colorIndex,
        createdAt: now,
        updatedAt: now,
        isPinned: false,
      );

      final success = await _notesService.addNote(note);

      if (success) {
        await loadData(); // Listeyi yenile
        debugPrint('✅ NotesProvider: Note added successfully');
      } else {
        debugPrint('❌ NotesProvider: Failed to add note');
        _setError('Not eklenemedi');
      }

      return success;
    } catch (e) {
      debugPrint('❌ NotesProvider: Error adding note: $e');
      _setError('Not eklenirken hata oluştu: $e');
      return false;
    }
  }

  /// Notu güncelle
  Future<bool> updateNote(NoteModel note) async {
    try {
      debugPrint('🔄 NotesProvider: Updating note: ${note.id}');
      _setError(null);

      final success = await _notesService.updateNote(note);

      if (success) {
        await loadData(); // Listeyi yenile
        debugPrint('✅ NotesProvider: Note updated successfully');
      } else {
        debugPrint('❌ NotesProvider: Failed to update note');
        _setError('Not güncellenemedi');
      }

      return success;
    } catch (e) {
      debugPrint('❌ NotesProvider: Error updating note: $e');
      _setError('Not güncellenirken hata oluştu: $e');
      return false;
    }
  }

  /// Notu sil
  Future<bool> deleteNote(int noteId) async {
    try {
      debugPrint('🗑️ NotesProvider: Deleting note: $noteId');
      _setError(null);

      final success = await _notesService.deleteNote(noteId);

      if (success) {
        await loadData(); // Listeyi yenile
        debugPrint('✅ NotesProvider: Note deleted successfully');
      } else {
        debugPrint('❌ NotesProvider: Failed to delete note');
        _setError('Not silinemedi');
      }

      return success;
    } catch (e) {
      debugPrint('❌ NotesProvider: Error deleting note: $e');
      _setError('Not silinirken hata oluştu: $e');
      return false;
    }
  }

  /// Notu sabitle/sabitliği kaldır
  Future<bool> togglePinNote(int noteId, bool isPinned) async {
    try {
      debugPrint('📌 NotesProvider: Toggling pin for note: $noteId to $isPinned');
      _setError(null);

      final success = await _notesService.togglePinNote(noteId, isPinned);

      if (success) {
        await loadData(); // Listeyi yenile
        debugPrint('✅ NotesProvider: Note pin toggled successfully');
      } else {
        debugPrint('❌ NotesProvider: Failed to toggle note pin');
        _setError('Not sabitleme durumu değiştirilemedi');
      }

      return success;
    } catch (e) {
      debugPrint('❌ NotesProvider: Error toggling note pin: $e');
      _setError('Not sabitleme durumu değiştirilirken hata oluştu: $e');
      return false;
    }
  }

  /// Tek bir notu getir
  Future<NoteModel?> getNote(int noteId) async {
    try {
      debugPrint('📖 NotesProvider: Getting note: $noteId');
      _setError(null);

      final note = await _notesService.getNote(noteId);

      if (note != null) {
        debugPrint('✅ NotesProvider: Note retrieved successfully');
      } else {
        debugPrint('⚠️ NotesProvider: Note not found');
        _setError('Not bulunamadı');
      }

      return note;
    } catch (e) {
      debugPrint('❌ NotesProvider: Error getting note: $e');
      _setError('Not getirilirken hata oluştu: $e');
      return null;
    }
  }

  /// Kategori ekle
  Future<bool> addCategory(CategoryModel category) async {
    try {
      debugPrint('➕ NotesProvider: Adding category: ${category.title}');
      await CategoryProvider().addCategory(category);

      // Kategoriyi listeye hemen ekle
      _categories.add(category);

      // UI'ı hemen güncelle
      notifyListeners();

      debugPrint('✅ NotesProvider: Category added successfully');
      return true;
    } catch (e) {
      debugPrint('❌ NotesProvider: Error adding category: $e');
      _setError('Kategori eklenirken hata oluştu: $e');
      return false;
    }
  }

  /// Kategori güncelle
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      debugPrint('🔄 NotesProvider: Updating category: ${category.id}');
      CategoryProvider().updateCategory(category);

      // Kategoriyi listede güncelle
      final index = _categories.indexWhere((cat) => cat.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      }

      // UI'ı hemen güncelle
      notifyListeners();

      debugPrint('✅ NotesProvider: Category updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ NotesProvider: Error updating category: $e');
      _setError('Kategori güncellenirken hata oluştu: $e');
      return false;
    }
  }

  /// Kategori sil
  Future<bool> deleteCategory(String categoryId) async {
    try {
      debugPrint('🗑️ NotesProvider: Deleting category: $categoryId');

      // Bu kategoriye ait notları kontrol et
      final notesInCategory = _notes.where((note) => note.categoryId == categoryId).toList();
      if (notesInCategory.isNotEmpty) {
        debugPrint('⚠️ NotesProvider: Category has ${notesInCategory.length} notes, deleting them first');
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

        debugPrint('✅ NotesProvider: Category deleted successfully');
        return true;
      } else {
        debugPrint('❌ NotesProvider: Category not found');
        _setError('Kategori bulunamadı');
        return false;
      }
    } catch (e) {
      debugPrint('❌ NotesProvider: Error deleting category: $e');
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

  /// Arşiv filtresini değiştir
  void toggleArchivedFilter() {
    debugPrint('📦 NotesProvider: Toggling archived filter - current: $_showArchivedOnly');
    _showArchivedOnly = !_showArchivedOnly;
    notifyListeners();
    debugPrint('✅ NotesProvider: Archived filter toggled - new: $_showArchivedOnly');
  }

  /// Notu arşivle/arşivden çıkar
  Future<bool> toggleArchiveNote(int noteId) async {
    try {
      debugPrint('📦 NotesProvider: Toggling archive for noteId: $noteId');
      _setError(null);

      final success = await _notesService.toggleArchiveNote(noteId);

      if (success) {
        await loadData();
        debugPrint('✅ NotesProvider: Note archive toggled successfully');
      } else {
        debugPrint('❌ NotesProvider: Failed to toggle archive note');
        _setError('Not arşivlenemedi');
      }

      return success;
    } catch (e) {
      debugPrint('❌ NotesProvider: Error toggling archive note - $e');
      _setError('Not arşivlenirken hata oluştu: $e');
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
