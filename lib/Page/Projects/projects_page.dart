import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../General/app_colors.dart';
import '../../Model/category_model.dart';
import '../../Model/project_model.dart';
import '../../Enum/task_status_enum.dart';
import '../../Provider/navbar_provider.dart';
import '../../Provider/projects_provider.dart';
import '../../Provider/task_provider.dart';
import '../../Service/locale_keys.g.dart';
import '../../Widgets/Common/add_item_dialog.dart';
import '../../Widgets/Common/category_filter_widget.dart';
import '../../Widgets/Common/common_button.dart';
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
      await provider.loadProjects();
      await _loadProjectTaskCounts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectTaskCounts() async {
    final provider = context.read<ProjectsProvider>();
    final taskProvider = context.read<TaskProvider>();
    final newCounts = <String, Map<String, int>>{};

    for (final project in provider.projects) {
      // Genel task'ları say (categoryId ile)
      final generalTasks = taskProvider.taskList.where((task) => task.categoryId == project.categoryId).toList();
      final generalTaskCount = generalTasks.length;
      final generalCompletedCount = generalTasks.where((task) => task.status == TaskStatusEnum.DONE).length;

      // Subtask'ları say
      final subtasks = await provider.getProjectSubtasks(project.id);
      final subtaskCount = subtasks.length;
      final subtaskCompletedCount = subtasks.where((subtask) => subtask.isCompleted).length;

      newCounts[project.id] = {
        'total': generalTaskCount + subtaskCount,
        'completed': generalCompletedCount + subtaskCompletedCount,
      };
    }

    if (mounted) {
      setState(() {
        _projectTaskCounts = newCounts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectsProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        context.read<NavbarProvider>().updateIndex(1);
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
            debugPrint('🔍 Search toggled: $_isSearching');
          },
          showArchivedOnly: provider.showArchivedOnly,
          onArchiveToggle: () {
            provider.toggleArchivedFilter();
            debugPrint('📦 Archive filter toggled: ${provider.showArchivedOnly}');
          },
        ),
        body: Consumer<ProjectsProvider>(
          builder: (context, provider, _) {
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
                    CommonButton(
                      text: LocaleKeys.Retry.tr(),
                      icon: Icons.refresh,
                      onPressed: () => provider.loadProjects(),
                    ),
                  ],
                ),
              );
            }

            // Projeler yok
            if (provider.projects.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_open, size: 100, color: AppColors.grey),
                    const SizedBox(height: 16),
                    Text(
                      LocaleKeys.NoProjectsYet.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LocaleKeys.AddFirstProject.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                      textAlign: TextAlign.center,
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
                    await provider.loadCategories();
                  },
                  showIcons: true,
                  showColors: true,
                  showAddButton: true,
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
                        debugPrint('🔍 Search query: $value');
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
                                  debugPrint('🔍 Search cleared');
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.NoProjectsFound.tr(),
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
          ...pinnedProjects.map((project) => _buildProjectCard(context, provider, project)),
          const SizedBox(height: 8),
        ],

        // Diğer projeler
        if (unpinnedProjects.isNotEmpty) ...[
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
          ...unpinnedProjects.map((project) => _buildProjectCard(context, provider, project)),
        ],

        const SizedBox(height: 80), // FAB için boşluk
      ],
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

    return ProjectCard(
      itemId: project.id,
      project: project,
      category: category,
      taskCount: taskCount,
      completedTaskCount: completedTaskCount,
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
          debugPrint('📌 Project ${project.isPinned ? 'unpinned' : 'pinned'}: ${project.title}');
        }
      },
      onArchive: () async {
        final success = await provider.toggleArchiveProject(project.id);
        if (context.mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(project.isArchived ? 'Project unarchived' : 'Project archived')),
          );
          debugPrint('📦 Project ${project.isArchived ? 'unarchived' : 'archived'}: ${project.title}');
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
            debugPrint('🗑️ Project deleted: ${project.title}');
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
              debugPrint('✅ Project created: ${project.id}');
            }
          }
        },
        isEditing: false,
      ),
    );
  }
}
