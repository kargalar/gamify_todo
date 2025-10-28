import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../General/app_colors.dart';
import '../../Model/category_model.dart';
import '../../Model/project_model.dart';
import '../../Provider/navbar_provider.dart';
import '../../Provider/navbar_visibility_provider.dart';
import '../../Provider/projects_provider.dart';
import '../../Service/locale_keys.g.dart';
import '../../Service/logging_service.dart';
import '../../Widgets/Common/add_item_dialog.dart';
import '../../Widgets/Common/category_filter_widget.dart';
import '../../Widgets/Common/standard_app_bar.dart';
import '../../Widgets/Projects/project_card.dart';
import '../Home/Widget/create_category_bottom_sheet.dart';
import 'project_detail_page.dart';

/// Projeler ana sayfası
class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, Map<String, int>> _projectTaskCounts = {}; // projectId -> {total, completed}
  Map<String, int> _projectNoteCounts = {}; // projectId -> noteCount
  int _previousTaskCountVersion = 0;
  int _previousNoteCountVersion = 0;

  // Public method to show add project dialog from outside
  void showAddProjectDialog() {
    _showAddProjectDialog(context);
  }

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında projeleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ProjectsProvider>();
      _previousTaskCountVersion = provider.taskCountVersion;
      _previousNoteCountVersion = provider.noteCountVersion;
      await provider.loadProjects();
      await _loadProjectTaskCounts();
      await _loadProjectNoteCounts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectTaskCounts() async {
    final provider = context.read<ProjectsProvider>();
    final newCounts = <String, Map<String, int>>{};

    for (final project in provider.projects) {
      // Sadece subtask'ları say (projelerle ilişkili görevler)
      final subtasks = await provider.getProjectSubtasks(project.id);
      final subtaskCount = subtasks.length;
      final subtaskCompletedCount = subtasks.where((subtask) => subtask.isCompleted).length;

      newCounts[project.id] = {
        'total': subtaskCount,
        'completed': subtaskCompletedCount,
      };

      LogService.debug('📊 ProjectsPage: Project "${project.title}" has $subtaskCount tasks ($subtaskCompletedCount completed)');
    }

    if (mounted) {
      setState(() {
        _projectTaskCounts = newCounts;
      });
    }
  }

  Future<void> _loadProjectNoteCounts() async {
    final provider = context.read<ProjectsProvider>();
    final newCounts = <String, int>{};

    for (final project in provider.projects) {
      // Notları say
      final notes = await provider.getProjectNotes(project.id);
      newCounts[project.id] = notes.length;
    }

    if (mounted) {
      setState(() {
        _projectNoteCounts = newCounts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectsProvider>();
    final visibilityProvider = context.read<NavbarVisibilityProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        // Go to first visible page instead of hardcoded index 1
        final safeIndex = visibilityProvider.getSafePageIndex(1);
        context.read<NavbarProvider>().updateIndex(safeIndex);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: StandardAppBar(
          title: LocaleKeys.Projects.tr(),
          isSearching: _isSearching,
          onSearchToggle: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                provider.clearSearchQuery();
              }
            });
            LogService.debug('🔍 Search toggled: $_isSearching');
          },
          showArchivedOnly: provider.showArchivedOnly,
          onArchiveToggle: () {
            provider.toggleArchivedFilter();
            LogService.debug('📦 Archive filter toggled: ${provider.showArchivedOnly}');
          },
        ),
        body: Consumer<ProjectsProvider>(
          builder: (context, provider, _) {
            // Task count version değiştiğinde task count'larını yeniden yükle
            if (provider.taskCountVersion != _previousTaskCountVersion) {
              _previousTaskCountVersion = provider.taskCountVersion;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadProjectTaskCounts();
              });
            }

            // Note count version değiştiğinde note count'larını yeniden yükle
            if (provider.noteCountVersion != _previousNoteCountVersion) {
              _previousNoteCountVersion = provider.noteCountVersion;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadProjectNoteCounts();
              });
            }

            // Projeler değiştiğinde task count'larını yeniden yükle
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (provider.projects.isNotEmpty && _projectTaskCounts.isEmpty) {
                _loadProjectTaskCounts();
              }
            });
            // Yükleniyor
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Hata
            if (provider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => provider.loadProjects(),
                      icon: const Icon(Icons.refresh),
                      label: Text(LocaleKeys.Retry.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.main,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Kategori filtresi
                CategoryFilterWidget(
                  categories: provider.categories,
                  selectedCategoryId: provider.selectedCategoryId,
                  onCategorySelected: (categoryId) => provider.setSelectedCategory(categoryId as String?),
                  itemCounts: provider.projectCounts,
                  onCategoryLongPress: (context, category) async {
                    final result = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.transparent,
                      builder: (context) => CreateCategoryBottomSheet(categoryModel: category),
                    );

                    // Kategori güncellendiyse veya silindiyse, provider'ı güncelle
                    if (result != null && context.mounted) {
                      await provider.loadCategories();
                    }
                  },
                  onCategoryAdded: () async {
                    // Yeni kategori eklendikten sonra kategorileri yeniden yükle
                    LogService.debug('🔄 ProjectsPage: onCategoryAdded called, reloading categories');
                    await provider.loadCategories();
                    LogService.debug('✅ ProjectsPage: Categories reloaded');
                  },
                  categoryType: CategoryType.project,
                  showEmptyCategories: true, // Boş kategorileri de göster
                ),

                // Inline arama barı (arama aktifse göster)
                if (_isSearching)
                  Container(
                    height: 40,
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (value) {
                        provider.updateSearchQuery(value);
                        LogService.debug('🔍 Search query: $value');
                      },
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: LocaleKeys.SearchHint.tr(),
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.text.withValues(alpha: 0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: AppColors.text.withValues(alpha: 0.5),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: AppColors.text.withValues(alpha: 0.5),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.clearSearchQuery();
                                  LogService.debug('🔍 Search cleared');
                                },
                              )
                            : null,
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                        isDense: true,
                      ),
                    ),
                  ),

                // Projeler listesi
                Expanded(
                  child: _buildProjectsList(context, provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProjectsList(BuildContext context, ProjectsProvider provider) {
    final pinnedProjects = provider.pinnedProjects;
    final unpinnedProjects = provider.unpinnedProjects;

    if (provider.filteredProjects.isEmpty) {
      final message = provider.showArchivedOnly ? LocaleKeys.NoArchivedProjects.tr() : LocaleKeys.NoProjectsFound.tr();
      LogService.debug('📁 ProjectsPage: No projects found. Archived filter: ${provider.showArchivedOnly}, Message: $message');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        // Sabitlenmiş projeler
        if (pinnedProjects.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.push_pin, size: 16, color: AppColors.grey),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.Pinned.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          _buildReorderableProjectsList(context, provider, pinnedProjects, isPinnedList: true),
        ],

        // Diğer projeler
        if (unpinnedProjects.isNotEmpty) ...[
          if (pinnedProjects.isEmpty) const SizedBox(height: 8),
          if (pinnedProjects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                LocaleKeys.OtherProjects.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey,
                ),
              ),
            ),
          _buildReorderableProjectsList(context, provider, unpinnedProjects, isPinnedList: false),
        ],

        const SizedBox(height: 80), // FAB için boşluk
      ],
    );
  }

  /// Sürüklenebilir projeler listesi
  Widget _buildReorderableProjectsList(BuildContext context, ProjectsProvider provider, List<ProjectModel> projects, {required bool isPinnedList}) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false, // Varsayılan handle icon'unu kaldır
      proxyDecorator: (child, index, animation) {
        // Sürükleme sırasında kartın görünümünü özelleştir
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final animValue = Curves.easeInOut.transform(animation.value);
            final scale = 1.0 + (animValue * 0.05); // Hafif büyütme efekti
            final elevation = animValue * 8.0; // Hafif gölge efekti

            return Transform.scale(
              scale: scale,
              child: Material(
                elevation: elevation,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      itemCount: projects.length,
      onReorder: (oldIndex, newIndex) async {
        LogService.debug('🔄 Reordering project from $oldIndex to $newIndex');

        // newIndex düzeltmesi (Flutter ReorderableListView için gerekli)
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }

        await provider.reorderProjects(
          oldIndex: oldIndex,
          newIndex: newIndex,
          isPinnedList: isPinnedList,
        );
      },
      itemBuilder: (context, index) {
        final project = projects[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(project.id),
          index: index,
          child: _buildProjectCard(context, provider, project),
        );
      },
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectsProvider provider, ProjectModel project) {
    // Get category for the project
    CategoryModel? category;
    try {
      category = provider.categories.firstWhere(
        (cat) => cat.id == project.categoryId,
      );
    } catch (e) {
      category = null;
    }

    // Get task counts from cached data
    final taskCounts = _projectTaskCounts[project.id] ?? {'total': 0, 'completed': 0};
    final taskCount = taskCounts['total'] ?? 0;
    final completedTaskCount = taskCounts['completed'] ?? 0;

    // Get note count from cached data
    final noteCount = _projectNoteCounts[project.id] ?? 0;

    return ProjectCard(
      itemId: project.id,
      project: project,
      category: category,
      taskCount: taskCount,
      completedTaskCount: completedTaskCount,
      noteCount: noteCount,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProjectDetailPage(project: project),
          ),
        );
      },
      onPin: () async {
        final success = await provider.togglePinProject(project.id);
        if (context.mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(project.isPinned ? 'Project unpinned' : 'Project pinned')),
          );
          LogService.debug('📌 Project ${project.isPinned ? 'unpinned' : 'pinned'}: ${project.title}');
        }
      },
      onArchive: () async {
        final success = await provider.toggleArchiveProject(project.id);
        if (context.mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(project.isArchived ? 'Project unarchived' : 'Project archived')),
          );
          LogService.debug('📦 Project ${project.isArchived ? 'unarchived' : 'archived'}: ${project.title}');
        }
      },
      onDelete: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(LocaleKeys.DeleteProject.tr()),
            content: Text(LocaleKeys.DeleteProjectConfirmation.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(LocaleKeys.Cancel.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(LocaleKeys.Delete.tr()),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          final success = await provider.deleteProject(project.id);
          if (context.mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Project deleted')),
            );
            LogService.debug('🗑️ Project deleted: ${project.title}');
          }
        }
      },
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemDialog(
        title: LocaleKeys.NewProject.tr(),
        icon: Icons.add_box_rounded,
        titleLabel: LocaleKeys.ProjectTitleLabel.tr(),
        titleHint: LocaleKeys.ProjectTitleHint.tr(),
        titleRequired: true,
        descriptionLabel: LocaleKeys.Description.tr(),
        descriptionHint: LocaleKeys.ProjectDescriptionHint.tr(),
        descriptionRequired: false,
        descriptionMaxLines: 3,
        descriptionMinLines: 1,
        showCancelButton: true,
        onSave: (title, description) async {
          final project = ProjectModel(
            id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
            title: title!,
            description: description?.isEmpty ?? true ? '' : description!,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final provider = context.read<ProjectsProvider>();
          final success = await provider.addProject(project);

          if (context.mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(LocaleKeys.ProjectCreated.tr())),
              );
              LogService.debug('✅ Project created: ${project.id}');
            }
          }
        },
        isEditing: false,
      ),
    );
  }
}
