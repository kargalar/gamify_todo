import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Provider/projects_provider.dart';
import 'package:next_level/Widgets/Projects/project_card.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/project_model.dart';
import 'package:next_level/Model/project_subtask_model.dart';
import 'package:next_level/Model/project_note_model.dart';
import 'package:next_level/Page/Projects/project_detail_page.dart';
import 'package:next_level/Widgets/Common/standard_app_bar.dart';
import 'package:next_level/Widgets/Common/add_subtask_bottom_sheet.dart';
import 'package:next_level/Widgets/Projects/add_project_note_bottom_sheet.dart';
import 'package:next_level/Widgets/Common/category_filter_widget.dart';
import 'package:next_level/Page/Home/Widget/create_category_bottom_sheet.dart';

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

                  // Eğer kategori silindiyse, provider'ı güncelle
                  if (result == true && context.mounted) {
                    await provider.loadCategories();
                  }
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
}
