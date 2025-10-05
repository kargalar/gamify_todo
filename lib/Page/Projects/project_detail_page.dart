import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:next_level/Model/project_model.dart';
import 'package:next_level/Model/project_subtask_model.dart';
import 'package:next_level/Model/project_note_model.dart';
import 'package:next_level/Provider/projects_provider.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Widgets/Common/description_editor.dart' as shared;
import 'package:next_level/Widgets/Common/add_subtask_bottom_sheet.dart';
import 'package:next_level/Widgets/Projects/add_edit_project_bottom_sheet.dart';
import 'package:next_level/Widgets/Projects/add_project_note_bottom_sheet.dart';

/// Proje detay sayfası - Modern tasarım (tab'sız)
/// Layout: Title → Description → Subtasks → Notes
class ProjectDetailPage extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailPage({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  List<ProjectSubtaskModel> _subtasks = [];
  List<ProjectNoteModel> _notes = [];
  bool _isLoading = true;
  late ProjectModel _currentProject;

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project;
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    setState(() => _isLoading = true);
    final provider = context.read<ProjectsProvider>();

    _subtasks = await provider.getProjectSubtasks(_currentProject.id);
    _notes = await provider.getProjectNotes(_currentProject.id);

    setState(() => _isLoading = false);
    debugPrint('📂 ProjectDetailPage: Loaded ${_subtasks.length} subtasks, ${_notes.length} notes');
  }

  void _openDescriptionEditor() {
    final controller = TextEditingController(text: _currentProject.description);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => shared.DescriptionEditor(
          controller: controller,
          title: 'Proje Açıklaması',
          onChanged: (text) async {
            // Auto-save
            final provider = context.read<ProjectsProvider>();
            final updated = _currentProject.copyWith(
              description: text,
              updatedAt: DateTime.now(),
            );
            await provider.updateProject(updated);
            setState(() {
              _currentProject = updated;
            });
            debugPrint('✅ ProjectDetailPage: Description auto-saved');
          },
        ),
      ),
    );
  }

  Future<void> _showEditProjectBottomSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditProjectBottomSheet(project: _currentProject),
    );

    if (result == true) {
      // Refresh project data
      // ignore: use_build_context_synchronously
      final provider = context.read<ProjectsProvider>();
      final projects = provider.projects;
      final updated = projects.firstWhere((p) => p.id == _currentProject.id);
      setState(() {
        _currentProject = updated;
      });
      debugPrint('✅ ProjectDetailPage: Project updated, UI refreshed');
    }
  }

  Future<void> _toggleArchive() async {
    final provider = context.read<ProjectsProvider>();
    await provider.toggleArchiveProject(_currentProject.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentProject.isArchived ? 'Proje arşivden çıkarıldı' : 'Proje arşivlendi',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Projeyi Sil'),
        content: const Text(
          'Bu projeyi silmek istediğinizden emin misiniz?\n\nTüm görevler ve notlar da silinecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<ProjectsProvider>();
      await provider.deleteProject(_currentProject.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proje silindi')),
        );
      }
    }
  }

  Future<void> _addSubtask() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSubtaskBottomSheet(
        customTitle: 'Yeni Proje Görevi',
        onSave: (title, description) async {
          final provider = context.read<ProjectsProvider>();
          final subtask = ProjectSubtaskModel(
            id: 'subtask_${DateTime.now().millisecondsSinceEpoch}',
            projectId: _currentProject.id,
            title: title,
            description: description,
            isCompleted: false,
            createdAt: DateTime.now(),
            orderIndex: _subtasks.length,
          );

          await provider.addSubtask(subtask);
          await _loadProjectData();
          debugPrint('✅ ProjectDetailPage: Subtask added');
        },
      ),
    );
  }

  Future<void> _addNote() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddProjectNoteBottomSheet(
        onSave: (title, content) async {
          final provider = context.read<ProjectsProvider>();
          final note = ProjectNoteModel(
            id: 'note_${DateTime.now().millisecondsSinceEpoch}',
            projectId: _currentProject.id,
            title: title,
            content: content,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await provider.addProjectNote(note);
          await _loadProjectData();
          debugPrint('✅ ProjectDetailPage: Note added with title: $title');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentProject.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          // Pin butonu
          IconButton(
            icon: Icon(
              _currentProject.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _currentProject.isPinned ? AppColors.yellow : null,
            ),
            onPressed: () async {
              final provider = context.read<ProjectsProvider>();
              await provider.togglePinProject(_currentProject.id);
              setState(() {
                _currentProject = _currentProject.copyWith(isPinned: !_currentProject.isPinned);
              });
            },
          ),
          // Düzenleme menüsü
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditProjectBottomSheet();
              } else if (value == 'archive') {
                _toggleArchive();
              } else if (value == 'delete') {
                _confirmDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Düzenle'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(
                      _currentProject.isArchived ? Icons.unarchive : Icons.archive,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(_currentProject.isArchived ? 'Arşivden Çıkar' : 'Arşivle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Açıklama alanı
                  _buildDescriptionSection(),

                  const SizedBox(height: 16),

                  // Görevler bölümü
                  _buildSubtasksSection(),

                  const SizedBox(height: 16),

                  // Notlar bölümü
                  _buildNotesSection(),

                  const SizedBox(height: 80), // FAB için boşluk
                ],
              ),
            ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.panelBackground2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 20, color: AppColors.text.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(
                'Açıklama',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: _openDescriptionEditor,
                tooltip: 'Açıklamayı Düzenle',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentProject.description.isEmpty ? 'Açıklama eklenmedi. Düzenle butonuna tıklayın.' : _currentProject.description,
            style: TextStyle(
              fontSize: 14,
              color: _currentProject.description.isEmpty ? AppColors.grey : AppColors.text.withValues(alpha: 0.8),
              fontStyle: _currentProject.description.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtasksSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.panelBackground2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_box_outlined, size: 20, color: AppColors.text.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(
                'Görevler (${_subtasks.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: _addSubtask,
                tooltip: 'Görev Ekle',
              ),
            ],
          ),
          if (_subtasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Henüz görev eklenmedi',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.text.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subtasks.length,
              onReorder: (oldIndex, newIndex) async {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }

                final provider = context.read<ProjectsProvider>();
                final item = _subtasks.removeAt(oldIndex);
                _subtasks.insert(newIndex, item);

                // Update orderIndex for all subtasks
                for (int i = 0; i < _subtasks.length; i++) {
                  _subtasks[i].orderIndex = i;
                  await provider.updateSubtask(_subtasks[i]);
                }

                setState(() {});
                debugPrint('✅ Subtasks reordered');
              },
              itemBuilder: (context, index) {
                final subtask = _subtasks[index];
                return _buildSubtaskItem(subtask, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSubtaskItem(ProjectSubtaskModel subtask, int index) {
    return Slidable(
      key: ValueKey(subtask.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              final provider = context.read<ProjectsProvider>();
              await provider.deleteSubtask(subtask.id);
              await _loadProjectData();
              debugPrint('🗑️ Subtask deleted via slidable');
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Sil',
          ),
        ],
      ),
      child: Container(
        key: ValueKey(subtask.id),
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: AppColors.panelBackground2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () async {
            // Tap anywhere to check/uncheck
            final provider = context.read<ProjectsProvider>();
            await provider.toggleSubtaskCompleted(subtask.id);
            await _loadProjectData();
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox (non-interactive, just visual)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(
                    subtask.isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: subtask.isCompleted ? AppColors.main : AppColors.text.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        subtask.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                          color: subtask.isCompleted ? AppColors.text.withValues(alpha: 0.5) : AppColors.text,
                        ),
                      ),
                      if (subtask.description != null && subtask.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtask.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text.withValues(alpha: 0.6),
                            decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                // Drag handle for reordering
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: AppColors.text.withValues(alpha: 0.4),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.panelBackground2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_outlined, size: 20, color: AppColors.text.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(
                'Notlar (${_notes.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: _addNote,
                tooltip: 'Not Ekle',
              ),
            ],
          ),
          if (_notes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Henüz not eklenmedi',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.text.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ..._notes.map((note) => _buildNoteItem(note)),
        ],
      ),
    );
  }

  Widget _buildNoteItem(ProjectNoteModel note) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panelBackground2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.title != null && note.title!.isNotEmpty) ...[
                  Text(
                    note.title!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.text.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () async {
              final provider = context.read<ProjectsProvider>();
              await provider.deleteProjectNote(note.id);
              await _loadProjectData();
            },
          ),
        ],
      ),
    );
  }
}
