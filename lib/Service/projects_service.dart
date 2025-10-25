import 'package:hive_flutter/hive_flutter.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Model/project_model.dart';

/// Projeler için Hive işlemleri
class ProjectsService {
  static final ProjectsService _instance = ProjectsService._internal();
  factory ProjectsService() => _instance;
  ProjectsService._internal();

  static const String _boxName = 'projects';
  Box<ProjectModel>? _projectsBox;

  /// Hive box'ını aç
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _projectsBox = await Hive.openBox<ProjectModel>(_boxName);
        LogService.debug('✅ ProjectsService: Hive box opened successfully');
      } else {
        _projectsBox = Hive.box<ProjectModel>(_boxName);
        LogService.debug('✅ ProjectsService: Hive box already open');
      }
    } catch (e) {
      LogService.error('❌ ProjectsService: Error opening Hive box: $e');
    }
  }

  /// Tüm projeleri getir
  Future<List<ProjectModel>> getProjects() async {
    try {
      await initialize();
      if (_projectsBox == null) {
        LogService.error('❌ ProjectsService: Projects box is null');
        return [];
      }

      final projects = _projectsBox!.values.toList();
      // Sabitlenmiş ve güncellenmiş tarihe göre sırala
      projects.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });

      LogService.debug('✅ ProjectsService: Loaded ${projects.length} projects');
      return projects;
    } catch (e) {
      LogService.error('❌ ProjectsService: Error getting projects: $e');
      return [];
    }
  }

  /// Yeni proje ekle
  Future<bool> addProject(ProjectModel project) async {
    try {
      await initialize();
      if (_projectsBox == null) {
        LogService.error('❌ ProjectsService: Cannot add project - box is null');
        return false;
      }

      LogService.debug('➕ ProjectsService: Adding new project: ${project.id}');
      await _projectsBox!.put(project.id, project);
      LogService.debug('✅ ProjectsService: Project added successfully');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectsService: Error adding project: $e');
      return false;
    }
  }

  /// Projeyi güncelle
  Future<bool> updateProject(ProjectModel project) async {
    try {
      await initialize();
      if (_projectsBox == null) {
        LogService.error('❌ ProjectsService: Cannot update project - box is null');
        return false;
      }

      LogService.debug('🔄 ProjectsService: Updating project: ${project.id}');
      project.updatedAt = DateTime.now();
      await _projectsBox!.put(project.id, project);
      LogService.debug('✅ ProjectsService: Project updated successfully');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectsService: Error updating project: $e');
      return false;
    }
  }

  /// Projeyi sil
  Future<bool> deleteProject(String projectId) async {
    try {
      await initialize();
      if (_projectsBox == null) {
        LogService.error('❌ ProjectsService: Cannot delete project - box is null');
        return false;
      }

      LogService.debug('🗑️ ProjectsService: Deleting project: $projectId');
      await _projectsBox!.delete(projectId);
      LogService.debug('✅ ProjectsService: Project deleted successfully');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectsService: Error deleting project: $e');
      return false;
    }
  }

  /// Pin/unpin project
  Future<bool> togglePinProject(String projectId) async {
    try {
      await initialize();
      if (_projectsBox == null) {
        LogService.error('❌ ProjectsService: Cannot pin project - box is null');
        return false;
      }

      final project = _projectsBox!.get(projectId);
      if (project == null) {
        LogService.debug('❌ ProjectsService: Project not found: $projectId');
        return false;
      }

      LogService.debug('📌 ProjectsService: Toggling pin for project: $projectId');
      project.isPinned = !project.isPinned;
      project.updatedAt = DateTime.now();
      await _projectsBox!.put(projectId, project);
      LogService.debug('✅ ProjectsService: Project pin toggled - isPinned: ${project.isPinned}');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectsService: Error toggling pin: $e');
      return false;
    }
  }

  /// Archive/unarchive project
  Future<bool> toggleArchiveProject(String projectId) async {
    try {
      await initialize();
      if (_projectsBox == null) {
        LogService.error('❌ ProjectsService: Cannot archive project - box is null');
        return false;
      }

      final project = _projectsBox!.get(projectId);
      if (project == null) {
        LogService.debug('❌ ProjectsService: Project not found: $projectId');
        return false;
      }

      LogService.debug('📦 ProjectsService: Toggling archive for project: $projectId');
      project.isArchived = !project.isArchived;
      project.updatedAt = DateTime.now();
      await _projectsBox!.put(projectId, project);
      LogService.debug('✅ ProjectsService: Project archive toggled - isArchived: ${project.isArchived}');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectsService: Error toggling archive: $e');
      return false;
    }
  }

  /// ID'ye göre proje getir
  ProjectModel? getProjectById(String projectId) {
    try {
      if (_projectsBox == null) {
        LogService.error('❌ ProjectsService: Cannot get project - box is null');
        return null;
      }
      return _projectsBox!.get(projectId);
    } catch (e) {
      LogService.error('❌ ProjectsService: Error getting project by ID: $e');
      return null;
    }
  }

  /// Tüm projeleri sil
  Future<void> clearAllProjects() async {
    try {
      await initialize();
      if (_projectsBox == null) {
        LogService.error('❌ ProjectsService: Cannot clear projects - box is null');
        return;
      }
      await _projectsBox!.clear();
      LogService.debug('✅ ProjectsService: All projects cleared');
    } catch (e) {
      LogService.error('❌ ProjectsService: Error clearing projects: $e');
    }
  }
}
