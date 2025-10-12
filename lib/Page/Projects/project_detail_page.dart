// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:next_level/Model/project_model.dart';
import 'package:next_level/Model/project_subtask_model.dart';
import 'package:next_level/Model/project_note_model.dart';
import 'package:next_level/Provider/projects_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
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
  bool hasClipboardData = false;

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

    // Check clipboard after loading data
    _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      // Try to parse
      final parsed = _parseSubtasksFromText(data.text!);
      if (mounted) {
        setState(() {
          hasClipboardData = parsed.isNotEmpty;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          hasClipboardData = false;
        });
      }
    }
  }

  void _openDescriptionEditor() {
    final controller = TextEditingController(text: _currentProject.description);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => shared.DescriptionEditor(
          controller: controller,
          title: LocaleKeys.ProjectDescription.tr(),
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
            _currentProject.isArchived ? LocaleKeys.ProjectUnarchived.tr() : LocaleKeys.ProjectArchived.tr(),
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
        title: Text(LocaleKeys.DeleteProject.tr()),
        content: Text(LocaleKeys.DeleteProjectConfirmation.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocaleKeys.Cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(LocaleKeys.Delete.tr()),
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
          SnackBar(content: Text(LocaleKeys.ProjectDeleted.tr())),
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
        customTitle: LocaleKeys.NewProjectTask.tr(),
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
            orderIndex: _notes.length,
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
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 20),
                    const SizedBox(width: 8),
                    Text(LocaleKeys.Edit.tr()),
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
                    Text(_currentProject.isArchived ? LocaleKeys.Unarchive.tr() : LocaleKeys.Archive.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(LocaleKeys.Delete.tr(), style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background,
                    AppColors.background.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Proje Bilgileri Kartı (Yeni!)
                    _buildProjectInfoCard(),

                    const SizedBox(height: 20),

                    // Görevler bölümü
                    _buildSubtasksSection(),

                    const SizedBox(height: 20),

                    // Notlar bölümü
                    _buildNotesSection(),

                    const SizedBox(height: 80), // FAB için boşluk
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProjectInfoCard() {
    return InkWell(
      onTap: () {
        // Proje adı ve bilgilerini düzenle
        _showEditProjectBottomSheet();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.main.withValues(alpha: 0.1),
              AppColors.main.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.main.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.main.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.main.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    color: AppColors.main,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentProject.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Açıklama (eğer varsa)
            if (_currentProject.description.isNotEmpty) ...[
              Divider(color: AppColors.main.withValues(alpha: 0.2), height: 24),
              GestureDetector(
                onTap: () {
                  // Açıklama alanına tıklanınca description editor'ı aç
                  _openDescriptionEditor();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: AppColors.text.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          LocaleKeys.Description.tr(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text.withValues(alpha: 0.7),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: AppColors.main,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentProject.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.text.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Divider(color: AppColors.main.withValues(alpha: 0.2), height: 24),
              GestureDetector(
                onTap: () {
                  // Açıklama ekle butonuna tıklanınca description editor'ı aç
                  _openDescriptionEditor();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.main.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.main.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        size: 16,
                        color: AppColors.main.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        LocaleKeys.AddDescription.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.main.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubtasksSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.panelBackground2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_box_outlined,
                  size: 18,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocaleKeys.Tasks.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_subtasks.where((s) => s.isCompleted).length}/${_subtasks.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                ),
              ),
              const Spacer(),
              // Three dot menu
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'copy all',
                    child: Row(
                      children: [
                        const Icon(Icons.content_copy, size: 18),
                        const SizedBox(width: 8),
                        Text(LocaleKeys.CopyAll.tr()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'copy incomplete',
                    child: Row(
                      children: [
                        const Icon(Icons.content_copy, size: 18),
                        const SizedBox(width: 8),
                        Text(LocaleKeys.CopyIncomplete.tr()),
                      ],
                    ),
                  ),
                  if (hasClipboardData)
                    PopupMenuItem(
                      value: 'paste',
                      child: Row(
                        children: [
                          const Icon(Icons.content_paste, size: 18),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.Paste.tr()),
                        ],
                      ),
                    ),
                  if (_subtasks.isNotEmpty)
                    PopupMenuItem(
                      value: 'complete all',
                      child: Row(
                        children: [
                          const Icon(Icons.done_all, size: 18),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.CompleteAll.tr()),
                        ],
                      ),
                    ),
                  if (_subtasks.isNotEmpty)
                    PopupMenuItem(
                      value: 'clear all',
                      child: Row(
                        children: [
                          const Icon(Icons.clear_all, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.ClearAll.tr(), style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'copy all':
                      _copyAllSubtasks();
                      break;
                    case 'copy incomplete':
                      _copyIncompleteSubtasks();
                      break;
                    case 'paste':
                      _pasteSubtasks();
                      break;
                    case 'complete all':
                      _completeAllSubtasks();
                      break;
                    case 'clear all':
                      _clearAllSubtasks();
                      break;
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.add, size: 18, color: AppColors.main),
                onPressed: _addSubtask,
                tooltip: LocaleKeys.AddTask.tr(),
              ),
            ],
          ),
          if (_subtasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 48,
                      color: AppColors.text.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LocaleKeys.NoTasksYet.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.text.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
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
            label: LocaleKeys.Delete.tr(),
          ),
        ],
      ),
      child: Container(
        key: ValueKey(subtask.id),
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              subtask.isCompleted ? AppColors.green.withValues(alpha: 0.05) : AppColors.panelBackground2,
              AppColors.panelBackground2.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: subtask.isCompleted ? AppColors.green.withValues(alpha: 0.2) : AppColors.panelBackground2,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: () async {
            // Tap anywhere to check/uncheck
            final provider = context.read<ProjectsProvider>();
            await provider.toggleSubtaskCompleted(subtask.id);
            await _loadProjectData();
          },
          onLongPress: () async {
            // Long press to edit subtask
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddSubtaskBottomSheet(
                initialTitle: subtask.title,
                initialDescription: subtask.description,
                onSave: (title, description) async {
                  final provider = context.read<ProjectsProvider>();
                  subtask.title = title;
                  subtask.description = description;
                  await provider.updateSubtask(subtask);
                  await _loadProjectData();
                  debugPrint('✅ ProjectDetailPage: Subtask updated');
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox (non-interactive, just visual)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: subtask.isCompleted ? AppColors.green.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    subtask.isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: subtask.isCompleted ? AppColors.green : AppColors.text.withValues(alpha: 0.4),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtask.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.text.withValues(alpha: 0.3),
                          color: subtask.isCompleted ? AppColors.text.withValues(alpha: 0.5) : AppColors.text,
                        ),
                      ),
                      if (subtask.description != null && subtask.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtask.description!,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.text.withValues(alpha: 0.5),
                            decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: AppColors.text.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Drag handle for reordering
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: AppColors.text.withValues(alpha: 0.3),
                    size: 18,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.panelBackground2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.note_outlined,
                  size: 18,
                  color: AppColors.yellow,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Notlar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_notes.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.yellow,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.add, size: 18, color: AppColors.main),
                onPressed: _addNote,
                tooltip: 'Not Ekle',
              ),
            ],
          ),
          if (_notes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 48,
                      color: AppColors.text.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Henüz not eklenmedi',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.text.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) async {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }

                setState(() {
                  final note = _notes.removeAt(oldIndex);
                  _notes.insert(newIndex, note);
                });

                // Update order indices and save
                final provider = context.read<ProjectsProvider>();
                for (int i = 0; i < _notes.length; i++) {
                  _notes[i].orderIndex = i;
                  await provider.updateProjectNote(_notes[i]);
                }

                setState(() {});
                debugPrint('✅ Notes reordered');
              },
              children: _notes.map((note) => _buildNoteItem(note)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(ProjectNoteModel note) {
    return Slidable(
      key: ValueKey(note.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              final provider = context.read<ProjectsProvider>();
              await provider.deleteProjectNote(note.id);
              await _loadProjectData();
              debugPrint('🗑️ Note deleted via slidable');
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: LocaleKeys.Delete.tr(),
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: () async {
          // Long press to edit note
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddProjectNoteBottomSheet(
              initialTitle: note.title,
              initialContent: note.content,
              onSave: (title, content) async {
                final provider = context.read<ProjectsProvider>();
                note.title = title;
                note.content = content;
                note.updatedAt = DateTime.now();
                await provider.updateProjectNote(note);
                await _loadProjectData();
                debugPrint('✅ ProjectDetailPage: Note updated with title: $title');
              },
            ),
          );
        },
        child: Container(
          key: ValueKey(note.id),
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.panelBackground2,
                AppColors.panelBackground2.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.yellow.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Note icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.sticky_note_2,
                  size: 14,
                  color: AppColors.yellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.title != null && note.title!.isNotEmpty) ...[
                      Text(
                        note.title!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (note.content != null && note.content!.isNotEmpty)
                      Text(
                        note.content!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Drag handle for reordering
              Icon(
                Icons.drag_handle_rounded,
                color: AppColors.text.withValues(alpha: 0.3),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ SUBTASK CLIPBOARD OPERATIONS ============

  void _copyAllSubtasks() {
    if (_subtasks.isEmpty) {
      debugPrint('⚠️ ProjectDetailPage: No subtasks to copy');
      return;
    }

    // Create bullet list with completed/incomplete status and descriptions
    final bulletList = _subtasks.map((subtask) {
      final status = subtask.isCompleted ? '✓' : '○';
      String result = '$status ${subtask.title}';

      // Add description if it exists and is not empty
      if (subtask.description != null && subtask.description!.isNotEmpty) {
        result += '\n    ${subtask.description}';
      }

      return result;
    }).join('\n');

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: bulletList)).then((_) {
      // Update UI to show paste button
      setState(() {
        hasClipboardData = true;
      });
      // Show confirmation snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.SubtasksCopied.tr(args: [_subtasks.length.toString()])),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.main,
        ),
      );
      debugPrint('✅ ProjectDetailPage: ${_subtasks.length} subtasks copied to clipboard');
    });
  }

  void _copyIncompleteSubtasks() {
    final incomplete = _subtasks.where((s) => !s.isCompleted).toList();
    if (incomplete.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.NoIncompleteTasks.tr()),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.text.withValues(alpha: 0.7),
        ),
      );
      debugPrint('⚠️ ProjectDetailPage: No incomplete subtasks to copy');
      return;
    }

    final bulletList = incomplete.map((subtask) {
      String result = '○ ${subtask.title}';
      if (subtask.description != null && subtask.description!.isNotEmpty) {
        result += '\n    ${subtask.description}';
      }
      return result;
    }).join('\n');

    Clipboard.setData(ClipboardData(text: bulletList)).then((_) {
      setState(() {
        hasClipboardData = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.IncompleteSubtasksCopied.tr(args: [incomplete.length.toString()])),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.main,
        ),
      );
      debugPrint('✅ ProjectDetailPage: ${incomplete.length} incomplete subtasks copied');
    });
  }

  List<ProjectSubtaskModel> _parseSubtasksFromText(String text) {
    final lines = text.split('\n');
    final List<ProjectSubtaskModel> parsedSubtasks = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check if line starts with status
      if (line.startsWith('✓ ') || line.startsWith('○ ')) {
        final isCompleted = line.startsWith('✓ ');
        final title = line.substring(2).trim();
        String? description;

        // Check next line for description
        if (i + 1 < lines.length && lines[i + 1].startsWith('    ')) {
          description = lines[i + 1].substring(4).trim();
          i++; // Skip description line
        }

        parsedSubtasks.add(ProjectSubtaskModel(
          id: DateTime.now().millisecondsSinceEpoch.toString() + parsedSubtasks.length.toString(),
          projectId: _currentProject.id,
          title: title,
          description: description ?? '',
          isCompleted: isCompleted,
          orderIndex: parsedSubtasks.length,
          createdAt: DateTime.now(),
        ));
      }
    }

    return parsedSubtasks;
  }

  Future<void> _pasteSubtasks() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.isEmpty) {
      debugPrint('⚠️ ProjectDetailPage: Clipboard is empty');
      return;
    }

    final parsedSubtasks = _parseSubtasksFromText(data.text!);
    if (parsedSubtasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.NoValidTasksInClipboard.tr()),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('⚠️ ProjectDetailPage: No valid subtasks in clipboard');
      return;
    }

    // Add all parsed subtasks
    final provider = context.read<ProjectsProvider>();
    for (final parsed in parsedSubtasks) {
      await provider.addSubtask(parsed);
    }

    await _loadProjectData(); // Refresh data
    _checkClipboard(); // Re-check clipboard after paste

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocaleKeys.SubtasksPasted.tr(args: [parsedSubtasks.length.toString()])),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.main,
      ),
    );
    debugPrint('✅ ProjectDetailPage: ${parsedSubtasks.length} subtasks pasted');
  }

  Future<void> _completeAllSubtasks() async {
    if (_subtasks.isEmpty) {
      debugPrint('⚠️ ProjectDetailPage: No subtasks to complete');
      return;
    }

    final provider = context.read<ProjectsProvider>();
    int completedCount = 0;

    for (final subtask in _subtasks) {
      if (!subtask.isCompleted) {
        subtask.isCompleted = true;
        await provider.updateSubtask(subtask);
        completedCount++;
      }
    }

    await _loadProjectData(); // Refresh data

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocaleKeys.TasksCompleted.tr(args: [completedCount.toString()])),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.green,
      ),
    );
    debugPrint('✅ ProjectDetailPage: $completedCount subtasks completed');
  }

  Future<void> _clearAllSubtasks() async {
    if (_subtasks.isEmpty) {
      debugPrint('⚠️ ProjectDetailPage: No subtasks to clear');
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.DeleteAllTasks.tr()),
        content: Text(LocaleKeys.DeleteAllTasksConfirmation.tr(args: [_subtasks.length.toString()])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocaleKeys.Cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final provider = context.read<ProjectsProvider>();
    final count = _subtasks.length;

    for (final subtask in _subtasks) {
      await provider.deleteSubtask(subtask.id);
    }

    await _loadProjectData(); // Refresh data

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocaleKeys.TasksDeleted.tr(args: [count.toString()])),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.red,
      ),
    );
    debugPrint('✅ ProjectDetailPage: $count subtasks cleared');
  }
}
