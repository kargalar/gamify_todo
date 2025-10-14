import 'package:flutter/material.dart';
import 'package:next_level/Model/project_model.dart';
import 'package:next_level/Model/project_subtask_model.dart';
import 'package:next_level/Model/project_note_model.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Service/projects_service.dart';
import 'package:next_level/Service/project_subtasks_service.dart';
import 'package:next_level/Service/project_notes_service.dart';
import 'package:next_level/Provider/category_provider.dart';

/// Projeleri yöneten Provider
class ProjectsProvider with ChangeNotifier {
  static final ProjectsProvider _instance = ProjectsProvider._internal();

  factory ProjectsProvider() {
    return _instance;
  }

  ProjectsProvider._internal() {
    loadProjects();
    loadCategories();
  }

  final ProjectsService _projectsService = ProjectsService();
  final ProjectSubtasksService _subtasksService = ProjectSubtasksService();
  final ProjectNotesService _notesService = ProjectNotesService();

  // State
  List<ProjectModel> _projects = [];
  List<CategoryModel> _categories = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _showArchivedOnly = false;
  String? _selectedCategoryId;

  // Getters
  List<ProjectModel> get projects => _projects;
  List<CategoryModel> get categories => _categories;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showArchivedOnly => _showArchivedOnly;
  String? get selectedCategoryId => _selectedCategoryId;

  /// Kategorileri yükle
  Future<void> loadCategories() async {
    try {
      debugPrint('📡 ProjectsProvider: Loading categories');
      final categoryProvider = CategoryProvider();
      await categoryProvider.initialize();
      _categories = categoryProvider.getActiveCategories();
      debugPrint('✅ ProjectsProvider: Loaded ${_categories.length} categories');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error loading categories: $e');
    }
  }

  /// Kategori filtresi ayarla
  void setSelectedCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    debugPrint('🔍 ProjectsProvider: Category filter set to: $categoryId');
    notifyListeners();
  }

  /// Get category by ID
  CategoryModel? getCategoryById(String? id) {
    if (id == null) return null;
    return _categories.firstWhere(
      (category) => category.id == id,
      orElse: () => CategoryModel(id: '', title: '', color: Colors.grey),
    );
  }

  /// Add new category
  Future<bool> addCategory(CategoryModel category) async {
    try {
      final categoryProvider = CategoryProvider();
      categoryProvider.addCategory(category);
      await loadCategories();
      debugPrint('✅ ProjectsProvider: Category added successfully');
      return true;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error adding category: $e');
      return false;
    }
  }

  /// Update category
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      final categoryProvider = CategoryProvider();
      categoryProvider.updateCategory(category);
      await loadCategories();
      debugPrint('✅ ProjectsProvider: Category updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error updating category: $e');
      return false;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      final category = getCategoryById(categoryId);
      if (category != null) {
        final categoryProvider = CategoryProvider();
        categoryProvider.deleteCategory(category);
        await loadCategories();
        debugPrint('✅ ProjectsProvider: Category deleted successfully');
      }
      return true;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error deleting category: $e');
      return false;
    }
  }

  /// Proje sayıları (kategori bazlı)
  Map<String, int> get projectCounts {
    final counts = <String, int>{};
    for (var category in _categories) {
      counts[category.id] = _projects.where((project) => project.categoryId == category.id).length;
    }
    return counts;
  }

  /// Filtrelenmiş projeler
  List<ProjectModel> get filteredProjects {
    var filtered = _projects;

    // Arşiv filtreleme
    if (_showArchivedOnly) {
      filtered = filtered.where((project) => project.isArchived).toList();
    } else {
      filtered = filtered.where((project) => !project.isArchived).toList();
    }

    // Kategori filtreleme
    if (_selectedCategoryId != null) {
      filtered = filtered.where((project) => project.categoryId == _selectedCategoryId).toList();
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      filtered = filtered.where((project) {
        return project.title.toLowerCase().contains(queryLower) || project.description.toLowerCase().contains(queryLower);
      }).toList();
    }

    return filtered;
  }

  /// Sabitlenmiş projeler
  List<ProjectModel> get pinnedProjects {
    return filteredProjects.where((project) => project.isPinned).toList();
  }

  /// Sabitlenmemiş projeler
  List<ProjectModel> get unpinnedProjects {
    return filteredProjects.where((project) => !project.isPinned).toList();
  }

  /// Projeleri yükle
  Future<void> loadProjects() async {
    try {
      debugPrint('📡 ProjectsProvider: Loading projects from Hive');
      _setLoading(true);
      _setError(null);

      await _projectsService.initialize();
      _projects = await _projectsService.getProjects();

      debugPrint('✅ ProjectsProvider: Loaded ${_projects.length} projects');
      _setLoading(false);
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error loading projects: $e');
      _setError('Projeler yüklenirken hata oluştu: $e');
      _setLoading(false);
    }
  }

  /// Yeni proje ekle
  Future<bool> addProject(ProjectModel project) async {
    try {
      debugPrint('➕ ProjectsProvider: Adding new project');
      final success = await _projectsService.addProject(project);
      if (success) {
        await loadProjects();
        debugPrint('✅ ProjectsProvider: Project added successfully');
      }
      return success;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error adding project: $e');
      return false;
    }
  }

  /// Projeyi güncelle
  Future<bool> updateProject(ProjectModel project) async {
    try {
      debugPrint('🔄 ProjectsProvider: Updating project');
      final success = await _projectsService.updateProject(project);
      if (success) {
        await loadProjects();
        debugPrint('✅ ProjectsProvider: Project updated successfully');
      }
      return success;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error updating project: $e');
      return false;
    }
  }

  /// Projeyi sil (subtask ve notlar ile birlikte)
  Future<bool> deleteProject(String projectId) async {
    try {
      debugPrint('🗑️ ProjectsProvider: Deleting project and its data');

      // Önce subtask ve notları sil
      await _subtasksService.deleteSubtasksByProjectId(projectId);
      await _notesService.deleteNotesByProjectId(projectId);

      // Sonra projeyi sil
      final success = await _projectsService.deleteProject(projectId);
      if (success) {
        await loadProjects();
        debugPrint('✅ ProjectsProvider: Project deleted successfully');
      }
      return success;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error deleting project: $e');
      return false;
    }
  }

  /// Projeyi sabitle/sabitlemeyi kaldır
  Future<bool> togglePinProject(String projectId) async {
    try {
      debugPrint('📌 ProjectsProvider: Toggling project pin');
      final success = await _projectsService.togglePinProject(projectId);
      if (success) {
        await loadProjects();
        debugPrint('✅ ProjectsProvider: Project pin toggled successfully');
      }
      return success;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error toggling pin: $e');
      return false;
    }
  }

  /// Arşiv filtresini değiştir
  void toggleArchivedFilter() {
    debugPrint('📦 ProjectsProvider: Toggling archived filter - Current: $_showArchivedOnly');
    _showArchivedOnly = !_showArchivedOnly;
    debugPrint('📦 ProjectsProvider: New archived filter state: $_showArchivedOnly');
    notifyListeners();
  }

  /// Projeyi arşivle/arşivden çıkar
  Future<bool> toggleArchiveProject(String projectId) async {
    try {
      debugPrint('📦 ProjectsProvider: Toggling project archive');
      final success = await _projectsService.toggleArchiveProject(projectId);
      if (success) {
        await loadProjects();
        debugPrint('✅ ProjectsProvider: Project archive toggled successfully');
      }
      return success;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error toggling archive: $e');
      return false;
    }
  }

  /// Arama sorgusu güncelle
  void updateSearchQuery(String query) {
    debugPrint('🔍 ProjectsProvider: Search query updated: $query');
    _searchQuery = query;
    notifyListeners();
  }

  /// Arama sorgusunu temizle
  void clearSearchQuery() {
    debugPrint('🔍 ProjectsProvider: Search query cleared');
    _searchQuery = '';
    notifyListeners();
  }

  /// ID'ye göre proje getir
  ProjectModel? getProjectById(String projectId) {
    return _projectsService.getProjectById(projectId);
  }

  /// Projeye ait subtask'ları getir
  Future<List<ProjectSubtaskModel>> getProjectSubtasks(String projectId) async {
    return await _subtasksService.getSubtasksByProjectId(projectId);
  }

  /// Projeye ait notları getir
  Future<List<ProjectNoteModel>> getProjectNotes(String projectId) async {
    return await _notesService.getNotesByProjectId(projectId);
  }

  /// Subtask ekle
  Future<bool> addSubtask(ProjectSubtaskModel subtask) async {
    try {
      debugPrint('➕ ProjectsProvider: Adding subtask');
      final success = await _subtasksService.addSubtask(subtask);
      if (success) {
        debugPrint('✅ ProjectsProvider: Subtask added successfully');
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error adding subtask: $e');
      return false;
    }
  }

  /// Subtask güncelle
  Future<bool> updateSubtask(ProjectSubtaskModel subtask) async {
    try {
      debugPrint('🔄 ProjectsProvider: Updating subtask');
      final success = await _subtasksService.updateSubtask(subtask);
      if (success) {
        debugPrint('✅ ProjectsProvider: Subtask updated successfully');
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error updating subtask: $e');
      return false;
    }
  }

  /// Subtask tamamlanma durumunu değiştir
  Future<bool> toggleSubtaskCompleted(String subtaskId) async {
    try {
      debugPrint('✅ ProjectsProvider: Toggling subtask completed');
      final success = await _subtasksService.toggleSubtaskCompleted(subtaskId);
      if (success) {
        debugPrint('✅ ProjectsProvider: Subtask toggled successfully');
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error toggling subtask: $e');
      return false;
    }
  }

  /// Subtask sil
  Future<bool> deleteSubtask(String subtaskId) async {
    try {
      debugPrint('🗑️ ProjectsProvider: Deleting subtask');
      final success = await _subtasksService.deleteSubtask(subtaskId);
      if (success) {
        debugPrint('✅ ProjectsProvider: Subtask deleted successfully');
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error deleting subtask: $e');
      return false;
    }
  }

  /// Proje notu ekle
  Future<bool> addProjectNote(ProjectNoteModel note) async {
    try {
      debugPrint('➕ ProjectsProvider: Adding project note');
      final success = await _notesService.addNote(note);
      if (success) {
        debugPrint('✅ ProjectsProvider: Project note added successfully');
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error adding project note: $e');
      return false;
    }
  }

  /// Proje notunu güncelle
  Future<bool> updateProjectNote(ProjectNoteModel note) async {
    try {
      debugPrint('🔄 ProjectsProvider: Updating project note');
      final success = await _notesService.updateNote(note);
      if (success) {
        debugPrint('✅ ProjectsProvider: Project note updated successfully');
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error updating project note: $e');
      return false;
    }
  }

  /// Proje notunu sil
  Future<bool> deleteProjectNote(String noteId) async {
    try {
      debugPrint('🗑️ ProjectsProvider: Deleting project note');
      final success = await _notesService.deleteNote(noteId);
      if (success) {
        debugPrint('✅ ProjectsProvider: Project note deleted successfully');
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ ProjectsProvider: Error deleting project note: $e');
      return false;
    }
  }

  // Private methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
}
