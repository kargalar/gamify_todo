import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/subtask_dialog.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';

class SubtasksBottomSheet extends StatefulWidget {
  final TaskModel taskModel;

  const SubtasksBottomSheet({
    super.key,
    required this.taskModel,
  });

  @override
  State<SubtasksBottomSheet> createState() => _SubtasksBottomSheetState();
}

class _SubtasksBottomSheetState extends State<SubtasksBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final subtasks = widget.taskModel.subtasks ?? [];
    final displayedSubtasks = widget.taskModel.showSubtasks ? subtasks : subtasks.where((subtask) => !subtask.isCompleted).toList();
    final completedCount = subtasks.where((subtask) => subtask.isCompleted).length;

    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.text.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with title and add button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      color: AppColors.main,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    ClickableTooltip(
                      title: LocaleKeys.Subtasks.tr(),
                      bulletPoints: const ["Tap checkbox to mark subtask as completed", "Long press to edit a subtask", "Swipe left to delete a subtask"],
                      child: Text(
                        LocaleKeys.Subtasks.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Show/Hide completed subtasks toggle
                    if (completedCount > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: InkWell(
                          onTap: () {
                            taskProvider.toggleTaskSubtaskVisibility(widget.taskModel);
                          },
                          child: Row(
                            children: [
                              Icon(
                                widget.taskModel.showSubtasks ? Icons.visibility_off : Icons.visibility,
                                size: 14,
                                color: AppColors.text.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.taskModel.showSubtasks ? LocaleKeys.HideCompleted.tr() : LocaleKeys.ShowCompleted.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.text.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _showSubtaskDialog(null);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.main.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_rounded,
                                color: AppColors.main,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                LocaleKeys.Add.tr(),
                                style: TextStyle(
                                  color: AppColors.main,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Subtasks list or empty state
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: subtasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_box_outline_blank_rounded,
                            color: AppColors.text.withValues(alpha: 0.3),
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No subtasks",
                            style: TextStyle(
                              color: AppColors.text.withValues(alpha: 0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: displayedSubtasks.length,
                      itemBuilder: (context, index) {
                        final subtask = displayedSubtasks[index];
                        return _buildSubtaskItem(subtask);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtaskItem(SubTaskModel subtask) {
    return Dismissible(
      key: Key('subtask_${subtask.id}'),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 10),
        child: const Icon(
          Icons.delete_rounded,
          color: AppColors.red,
          size: 16,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _removeSubtask(subtask);
      },
      child: InkWell(
        onTap: () {
          _showSubtaskDialog(subtask);
        },
        onLongPress: () {
          // Edit subtask on long press
          _showSubtaskDialog(subtask);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: subtask.isCompleted ? AppColors.main.withValues(alpha: 0.05) : AppColors.panelBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: subtask.isCompleted ? AppColors.main.withValues(alpha: 0.2) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Checkbox with animation
                InkWell(
                  onTap: () {
                    _toggleSubtaskCompletion(subtask);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: subtask.isCompleted ? AppColors.main : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: subtask.isCompleted ? AppColors.main : AppColors.text.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: subtask.isCompleted
                        ? const Center(
                            child: Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Title and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with animation
                      Text(
                        subtask.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: subtask.isCompleted ? FontWeight.normal : FontWeight.bold,
                          decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                          color: subtask.isCompleted ? AppColors.text.withValues(alpha: 0.5) : AppColors.text,
                        ),
                      ),

                      // Description if available
                      if (subtask.description != null && subtask.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtask.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.text.withValues(alpha: 0.6),
                              decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSubtaskCompletion(SubTaskModel subtask) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.toggleSubtaskCompletion(widget.taskModel, subtask);
    setState(() {});
  }

  void _removeSubtask(SubTaskModel subtask) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.removeSubtask(widget.taskModel, subtask);
    setState(() {});
  }

  void _showSubtaskDialog(SubTaskModel? subtask) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => SubtaskDialog(
        subtask: subtask,
        onSave: (title, description) {
          final taskProvider = Provider.of<TaskProvider>(context, listen: false);

          if (subtask == null) {
            // Add new subtask
            taskProvider.addSubtask(widget.taskModel, title, description);
          } else {
            // Update existing subtask
            taskProvider.updateSubtask(widget.taskModel, subtask, title, description);
          }
        },
      ),
    );
  }
}
