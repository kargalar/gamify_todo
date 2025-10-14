import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Provider/projects_provider.dart';
import 'package:next_level/Widgets/Projects/project_card.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/project_model.dart';
import 'package:next_level/Model/project_subtask_model.dart';
import 'package:next_level/Model/project_note_model.dart';
import 'package:next_level/Model/project_category_model.dart';
import 'package:next_level/Page/Projects/project_detail_page.dart';
import 'package:next_level/Widgets/Common/standard_app_bar.dart';
import 'package:next_level/Widgets/Common/add_subtask_bottom_sheet.dart';
import 'package:next_level/Widgets/Projects/add_project_note_bottom_sheet.dart';
import 'package:next_level/Widgets/Projects/add_project_category_dialog.dart';

/// Projeler ana sayfası
class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Public method to show add project dialog from outside
  void showAddProjectDialog() {
    _showAddProjectDialog(context);
  }

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında projeleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsProvider>().loadProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: LocaleKeys.NewProject.tr(),
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
              _buildCategoryFilter(context, provider),

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
    );
  }

  Widget _buildCategoryFilter(BuildContext context, ProjectsProvider provider) {
    final projectCounts = provider.projectCounts;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Tümü
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: provider.selectedCategoryId == null,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      size: 16,
                      color: provider.selectedCategoryId == null ? Colors.white : AppColors.text,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      LocaleKeys.All.tr(),
                      style: TextStyle(
                        color: provider.selectedCategoryId == null ? Colors.white : AppColors.text,
                        fontWeight: provider.selectedCategoryId == null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: provider.selectedCategoryId == null ? Colors.white.withValues(alpha: 0.3) : AppColors.panelBackground2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${provider.projects.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: provider.selectedCategoryId == null ? Colors.white : AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
                selectedColor: AppColors.text,
                backgroundColor: AppColors.panelBackground,
                checkmarkColor: Colors.white,
                onSelected: (_) => provider.setSelectedCategory(null),
              ),
            ),

            // Kategoriler
            ...provider.categories.map((category) {
              final count = projectCounts[category.id] ?? 0;
              // Sadece projesi olan kategorileri göster
              if (count == 0 && provider.selectedCategoryId != category.id) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onLongPress: () => _showEditCategoryDialog(context, provider, category),
                  child: FilterChip(
                    selected: provider.selectedCategoryId == category.id,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                          size: 16,
                          color: provider.selectedCategoryId == category.id ? Colors.white : Color(category.colorValue),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category.name,
                          style: TextStyle(
                            color: provider.selectedCategoryId == category.id ? Colors.white : AppColors.text,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: provider.selectedCategoryId == category.id ? Colors.white.withValues(alpha: 0.3) : AppColors.panelBackground2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: provider.selectedCategoryId == category.id ? Colors.white : AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    selectedColor: Color(category.colorValue),
                    backgroundColor: Color(category.colorValue).withValues(alpha: 0.1),
                    checkmarkColor: Colors.white,
                    onSelected: (_) => provider.setSelectedCategory(
                      provider.selectedCategoryId == category.id ? null : category.id,
                    ),
                    labelStyle: TextStyle(
                      color: provider.selectedCategoryId == category.id ? Colors.white : AppColors.text,
                      fontWeight: provider.selectedCategoryId == category.id ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),

            // Yeni Kategori Ekle butonu
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildAddCategoryButton(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, ProjectsProvider provider, ProjectCategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AddProjectCategoryDialog(
        existingCategories: provider.categories,
        editingCategory: category,
        onDeleteCategory: (category) async {
          // This won't be called since we're editing
        },
      ),
    ).then((result) {
      if (result != null) {
        // Update category
        final updatedCategory = category.copyWith(
          name: result['name'],
          colorValue: result['colorValue'],
          iconCodePoint: result['iconCodePoint'],
        );
        provider.updateCategory(updatedCategory);
      }
    });
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

  Widget _buildAddCategoryButton(BuildContext context, ProjectsProvider provider) {
    return ActionChip(
      label: Icon(
        Icons.add_circle_outline,
        size: 20,
        color: AppColors.main,
      ),
      onPressed: () => _showAddProjectCategoryDialog(context, provider),
      backgroundColor: AppColors.panelBackground,
      side: BorderSide(
        color: AppColors.main,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectsProvider provider, ProjectModel project) {
    return ProjectCard(
      project: project,
      onTap: () {
        debugPrint('📂 Project tapped: ${project.id}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailPage(project: project),
          ),
        );
      },
      onDelete: () => _confirmDelete(context, provider, project),
      getSubtaskCount: () async {
        final subtasks = await provider.getProjectSubtasks(project.id);
        return subtasks.length;
      },
      getNoteCount: () async {
        final notes = await provider.getProjectNotes(project.id);
        return notes.length;
      },
      onAddTask: () {
        debugPrint('➕ Quick add task to project: ${project.id}');
        _showQuickAddTaskDialog(context, provider, project);
      },
      onAddNote: () {
        debugPrint('📝 Quick add note to project: ${project.id}');
        _showQuickAddNoteDialog(context, provider, project);
      },
    );
  }

  void _showQuickAddTaskDialog(BuildContext context, ProjectsProvider provider, ProjectModel project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSubtaskBottomSheet(
        customTitle: LocaleKeys.QuickAddTask.tr(),
        onSave: (title, description) async {
          debugPrint('➕ Quick add task to project: ${project.id}');
          final subtask = ProjectSubtaskModel(
            id: 'subtask_${DateTime.now().millisecondsSinceEpoch}',
            projectId: project.id,
            title: title,
            description: description,
            isCompleted: false,
            createdAt: DateTime.now(),
            orderIndex: 0,
          );

          final success = await provider.addSubtask(subtask);

          if (success) {
            debugPrint('✅ Subtask added successfully');
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocaleKeys.TaskAdded.tr()),
                backgroundColor: AppColors.green,
              ),
            );
          } else {
            debugPrint('❌ Failed to add subtask');
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocaleKeys.TaskAddError.tr()),
                backgroundColor: AppColors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showQuickAddNoteDialog(BuildContext context, ProjectsProvider provider, ProjectModel project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddProjectNoteBottomSheet(
        onSave: (title, content) async {
          debugPrint('📝 Quick add note to project: ${project.id}');
          final now = DateTime.now();
          final note = ProjectNoteModel(
            id: 'note_${now.millisecondsSinceEpoch}',
            projectId: project.id,
            title: title,
            content: content,
            createdAt: now,
            updatedAt: now,
            orderIndex: 0,
          );

          final success = await provider.addProjectNote(note);

          if (success) {
            debugPrint('✅ Note added successfully');
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Not eklendi'),
                backgroundColor: AppColors.blue,
              ),
            );
          } else {
            debugPrint('❌ Failed to add note');
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocaleKeys.NoteAddError.tr()),
                backgroundColor: AppColors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProjectsProvider provider, ProjectModel project) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LocaleKeys.Delete.tr()),
          content: Text(LocaleKeys.ProjectDeleteConfirmation.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await provider.deleteProject(project.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Proje silindi')),
                  );
                }
                debugPrint('✅ Project ${project.id} deleted');
              },
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LocaleKeys.NewProject.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: LocaleKeys.ProjectTitleLabel.tr(),
                  hintText: LocaleKeys.ProjectTitleHint.tr(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: LocaleKeys.Description.tr(),
                  hintText: LocaleKeys.ProjectDescriptionHint.tr(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(LocaleKeys.PleaseEnterTitle.tr())),
                  );
                  return;
                }

                final project = ProjectModel(
                  id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                final provider = context.read<ProjectsProvider>();
                final success = await provider.addProject(project);

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(LocaleKeys.ProjectCreated.tr())),
                    );
                    debugPrint('✅ Project created: ${project.id}');
                  }
                }
              },
              child: Text(LocaleKeys.Create.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddProjectCategoryDialog(BuildContext context, ProjectsProvider provider) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddProjectCategoryDialog(
        existingCategories: provider.categories,
        onDeleteCategory: (category) {
          _showDeleteProjectCategoryDialog(context, provider, category);
        },
      ),
    );

    if (result != null) {
      debugPrint('✅ ProjectsPage: Category data received from dialog');

      // Yeni kategori oluştur
      final newCategory = ProjectCategoryModel(
        id: 'proj_cat_${DateTime.now().millisecondsSinceEpoch}',
        name: result['name'] as String,
        iconCodePoint: result['iconCodePoint'] as int,
        colorValue: result['colorValue'] as int,
        createdAt: DateTime.now(),
      );

      await provider.addCategory(newCategory);

      debugPrint('✅ ProjectsPage: New category created - ${newCategory.name}');
    }
  }

  void _showDeleteProjectCategoryDialog(BuildContext context, ProjectsProvider provider, ProjectCategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.DeleteCategory.tr()),
        content: Text(
          LocaleKeys.DeleteCategoryConfirmation.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleKeys.Cancel.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Dialog'u kapat
              final success = await provider.deleteCategory(category.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(LocaleKeys.CategoryDeleted.tr())),
                );
                debugPrint('✅ ProjectsPage: Category deleted - ${category.name}');
              }
            },
            child: Text(
              LocaleKeys.Delete.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
