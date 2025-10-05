import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Provider/projects_provider.dart';
import 'package:next_level/Widgets/Projects/project_card.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/project_model.dart';
import 'package:next_level/Page/Projects/project_detail_page.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Projelerim',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          // Arama butonu
          IconButton(
            icon: Icon(
              _isSearching ? Icons.search_off : Icons.search,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  context.read<ProjectsProvider>().clearSearchQuery();
                }
              });
              debugPrint('🔍 Search toggled: $_isSearching');
            },
          ),
          // Arşiv butonu
          Consumer<ProjectsProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  provider.showArchivedOnly ? Icons.unarchive : Icons.archive,
                  color: provider.showArchivedOnly ? AppColors.orange : null,
                ),
                onPressed: () {
                  provider.toggleArchivedFilter();
                  debugPrint('📦 Archive filter toggled: ${provider.showArchivedOnly}');
                },
              );
            },
          ),
        ],
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
                    label: const Text('Yeniden Dene'),
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
                    'Henüz proje eklemediniz',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sağ alttaki + butonuna basarak\nilk projenizi ekleyin',
                    style: TextStyle(
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
                      hintText: 'Başlık veya açıklama ara...',
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
              'Proje bulunamadı',
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.push_pin, size: 16, color: AppColors.grey),
                SizedBox(width: 6),
                Text(
                  'Sabitlenmiş',
                  style: TextStyle(
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Diğer Projeler',
                style: TextStyle(
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
    );
  }

  void _confirmDelete(BuildContext context, ProjectsProvider provider, ProjectModel project) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Projeyi Sil'),
          content: const Text('Bu projeyi ve tüm alt görevlerini/notlarını silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
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
          title: const Text('Yeni Proje'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık *',
                  hintText: 'Proje başlığı',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Proje açıklaması (opsiyonel)',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen bir başlık girin')),
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
                      const SnackBar(content: Text('Proje oluşturuldu')),
                    );
                    debugPrint('✅ Project created: ${project.id}');
                  }
                }
              },
              child: const Text('Oluştur'),
            ),
          ],
        );
      },
    );
  }
}
