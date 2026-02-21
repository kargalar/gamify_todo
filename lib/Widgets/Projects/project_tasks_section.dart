import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../General/app_colors.dart';
import '../../Core/helper.dart';
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              icon: Icons.delete_outline_rounded,
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
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: task.isCompleted ? 0.6 : 1.0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: task.isCompleted ? AppColors.green.withValues(alpha: 0.06) : AppColors.panelBackground2.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: task.isCompleted ? AppColors.green.withValues(alpha: 0.15) : AppColors.text.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Circular check indicator
                    GestureDetector(
                      onTap: () async {
                        final provider = context.read<ProjectsProvider>();
                        await provider.toggleSubtaskCompleted(task.id);
                        widget.onTasksChanged();
                        LogService.debug('✅ Task toggled: ${task.title}');
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: task.isCompleted ? AppColors.green.withValues(alpha: 0.15) : Colors.transparent,
                          border: Border.all(
                            color: task.isCompleted ? AppColors.green : AppColors.text.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: task.isCompleted ? const Icon(Icons.check_rounded, size: 14, color: AppColors.green) : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Task content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              decorationColor: AppColors.text.withValues(alpha: 0.3),
                              color: task.isCompleted ? AppColors.text.withValues(alpha: 0.5) : AppColors.text,
                            ),
                          ),
                          if (task.description != null && task.description!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              task.description!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.text.withValues(alpha: 0.4),
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                decorationColor: AppColors.text.withValues(alpha: 0.2),
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
      ),
    );
  }
}
