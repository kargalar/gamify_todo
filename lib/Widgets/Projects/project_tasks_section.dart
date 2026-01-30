import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../General/app_colors.dart';
import '../../Core/helper.dart';
import '../../Core/Enums/status_enum.dart';
import '../../Model/project_model.dart';
import '../../Model/project_subtask_model.dart';
import '../../Provider/projects_provider.dart';
import '../../Service/logging_service.dart';
import '../Common/add_item_dialog.dart';

class ProjectTasksSection extends StatefulWidget {
  final ProjectModel project;
  final List<ProjectSubtaskModel> tasks;
  final VoidCallback onTasksChanged;

  const ProjectTasksSection({
    super.key,
    required this.project,
    required this.tasks,
    required this.onTasksChanged,
  });

  @override
  State<ProjectTasksSection> createState() => _ProjectTasksSectionState();
}

class _ProjectTasksSectionState extends State<ProjectTasksSection> {
  late List<ProjectSubtaskModel> _subtasks;
  ProjectSubtaskModel? _deletedTask;
  // ignore: unused_field
  int? _deletedTaskIndex;

  @override
  void initState() {
    super.initState();
    _subtasks = List.from(widget.tasks);
    if (widget.project.showOnlyIncompleteTasks == true) {
      _subtasks = _subtasks.where((t) => !t.isCompleted).toList();
    }
  }

  @override
  void didUpdateWidget(ProjectTasksSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _subtasks = List.from(widget.tasks);
    if (widget.project.showOnlyIncompleteTasks == true) {
      _subtasks = _subtasks.where((t) => !t.isCompleted).toList();
    }
  }

  void _copyAllTasks() {
    if (_subtasks.isEmpty) {
      LogService.error('⚠️ No tasks to copy');
      return;
    }

    final bulletList = _subtasks.map((task) {
      final status = task.isCompleted ? '✓' : '○';
      String result = '$status ${task.title}';
      if (task.description != null && task.description!.isNotEmpty) {
        result += '\n    ${task.description}';
      }
      return result;
    }).join('\n');

    Clipboard.setData(ClipboardData(text: bulletList)).then((_) {
      Helper().getMessage(message: '${_subtasks.length} tasks copied');
      LogService.debug('✅ ${_subtasks.length} tasks copied to clipboard');
    });
  }

  void _copyIncompleteTasks() {
    final incomplete = _subtasks.where((t) => !t.isCompleted).toList();
    if (incomplete.isEmpty) {
      Helper().getMessage(message: 'No incomplete tasks', status: StatusEnum.INFO);
      LogService.error('⚠️ No incomplete tasks to copy');
      return;
    }

    final bulletList = incomplete.map((task) {
      String result = '○ ${task.title}';
      if (task.description != null && task.description!.isNotEmpty) {
        result += '\n    ${task.description}';
      }
      return result;
    }).join('\n');

    Clipboard.setData(ClipboardData(text: bulletList)).then((_) {
      Helper().getMessage(message: '${incomplete.length} incomplete tasks copied');
      LogService.debug('✅ ${incomplete.length} incomplete tasks copied');
    });
  }

  Future<void> _toggleShowCompletedTasks() async {
    final provider = context.read<ProjectsProvider>();
    final newShowOnlyIncomplete = widget.project.showOnlyIncompleteTasks != true;

    widget.project.showOnlyIncompleteTasks = newShowOnlyIncomplete;
    await provider.updateProject(widget.project);

    setState(() {
      if (newShowOnlyIncomplete) {
        _subtasks = _subtasks.where((t) => !t.isCompleted).toList();
      } else {
        _subtasks = List.from(widget.tasks);
      }
    });

    Helper().getMessage(message: newShowOnlyIncomplete ? 'Completed tasks hidden' : 'All tasks shown');
    LogService.debug('✅ Show only incomplete: $newShowOnlyIncomplete');
  }

  Future<void> _completeAllTasks() async {
    final provider = context.read<ProjectsProvider>();
    for (final task in _subtasks) {
      if (!task.isCompleted) {
        await provider.toggleSubtaskCompleted(task.id);
      }
    }
    widget.onTasksChanged();
    LogService.debug('✅ All tasks completed');
  }

  Future<void> _clearAllTasks() async {
    final provider = context.read<ProjectsProvider>();
    for (final task in _subtasks) {
      await provider.deleteSubtask(task.id);
    }
    widget.onTasksChanged();
    LogService.debug('🗑️ All tasks deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.check_box_outlined, size: 14, color: AppColors.green),
              const SizedBox(width: 8),
              Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: AppColors.text.withValues(alpha: 0.6)),
                onSelected: (value) async {
                  switch (value) {
                    case 'copy_all':
                      _copyAllTasks();
                      break;
                    case 'copy_incomplete':
                      _copyIncompleteTasks();
                      break;
                    case 'toggle_completed':
                      _toggleShowCompletedTasks();
                      break;
                    case 'complete_all':
                      await _completeAllTasks();
                      break;
                    case 'clear_all':
                      await _clearAllTasks();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'copy_all',
                    child: Row(
                      children: [
                        const Icon(Icons.content_copy, size: 18),
                        const SizedBox(width: 8),
                        Text('Copy All'.tr()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'copy_incomplete',
                    child: Row(
                      children: [
                        const Icon(Icons.content_copy, size: 18),
                        const SizedBox(width: 8),
                        Text('Copy Incomplete'.tr()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_completed',
                    child: Row(
                      children: [
                        const Icon(Icons.visibility, size: 18),
                        const SizedBox(width: 8),
                        Text('Hide Completed'.tr()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'complete_all',
                    child: Row(
                      children: [
                        const Icon(Icons.done_all, size: 18),
                        const SizedBox(width: 8),
                        Text('Complete All'.tr()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        const Icon(Icons.clear_all, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Clear All'.tr(), style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ReorderableListView(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            physics: const NeverScrollableScrollPhysics(),
            proxyDecorator: (child, index, animation) {
              return Material(
                color: Colors.transparent,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.05).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
                  child: child,
                ),
              );
            },
            onReorder: (oldIndex, newIndex) async {
              if (oldIndex < newIndex) newIndex -= 1;

              setState(() {
                final item = _subtasks.removeAt(oldIndex);
                _subtasks.insert(newIndex, item);
              });

              final provider = context.read<ProjectsProvider>();
              for (int i = 0; i < _subtasks.length; i++) {
                _subtasks[i].orderIndex = i;
                await provider.updateSubtask(_subtasks[i]);
              }

              if (mounted) {
                setState(() {});
                widget.onTasksChanged();
              }

              LogService.debug('✅ Tasks reordered in ${widget.project.title}');
            },
            children: _subtasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              return _buildTaskItem(context, task, index);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, ProjectSubtaskModel task, int index) {
    return ReorderableDelayedDragStartListener(
      key: ValueKey(task.id),
      index: index,
      child: Slidable(
        key: ValueKey(task.id),
        endActionPane: ActionPane(
          extentRatio: 0.2,
          motion: const ScrollMotion(),
          closeThreshold: 0.1,
          openThreshold: 0.1,
          children: [
            SlidableAction(
              onPressed: (_) async {
                // Store deleted task for undo
                _deletedTask = task;
                _deletedTaskIndex = _subtasks.indexOf(task);

                final provider = context.read<ProjectsProvider>();
                await provider.deleteSubtask(task.id);
                widget.onTasksChanged();

                Helper().getUndoMessage(
                  message: 'Task deleted',
                  onUndo: () async {
                    if (_deletedTask != null) {
                      final provider = context.read<ProjectsProvider>();
                      await provider.addSubtask(_deletedTask!);
                      widget.onTasksChanged();

                      _deletedTask = null;
                      _deletedTaskIndex = null;
                    }
                  },
                );
                LogService.debug('🗑️ Task deleted: ${task.title}');
              },
              backgroundColor: AppColors.matteRed,
              borderRadius: BorderRadius.circular(12),
              foregroundColor: AppColors.white,
              icon: Icons.delete,
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddItemDialog(
                title: 'edit_task'.tr(),
                icon: Icons.edit_note_rounded,
                titleLabel: 'task_title'.tr(),
                titleHint: 'enter_task_title'.tr(),
                titleRequired: true,
                initialTitle: task.title,
                descriptionLabel: 'description'.tr(),
                descriptionHint: 'enter_task_description'.tr(),
                descriptionRequired: false,
                initialDescription: task.description,
                descriptionMaxLines: 5,
                descriptionMinLines: 2,
                showCancelButton: true,
                onSave: (title, description) async {
                  if (title != null && title.isNotEmpty) {
                    final provider = context.read<ProjectsProvider>();
                    task.title = title;
                    task.description = description;
                    await provider.updateSubtask(task);
                    widget.onTasksChanged();
                    LogService.debug('✅ Task updated: $title');
                  }
                },
                isEditing: true,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              key: ValueKey(task.id),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    task.isCompleted ? AppColors.green.withValues(alpha: 0.05) : AppColors.panelBackground2,
                    AppColors.panelBackground2.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: task.isCompleted ? AppColors.green.withValues(alpha: 0.2) : AppColors.panelBackground2,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final provider = context.read<ProjectsProvider>();
                      await provider.toggleSubtaskCompleted(task.id);
                      widget.onTasksChanged();
                      LogService.debug('✅ Task toggled: ${task.title}');
                    },
                    child: Container(
                      color: AppColors.transparent,
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        task.isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        color: task.isCompleted ? AppColors.green : AppColors.text.withValues(alpha: 0.4),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted ? AppColors.text.withValues(alpha: 0.5) : AppColors.text,
                          ),
                        ),
                        if (task.description != null && task.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description!,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.text.withValues(alpha: 0.5),
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
