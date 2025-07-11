import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Page/Home/Add Task/Widget/subtask_dialog.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';

class SubtaskManager extends StatefulWidget {
  const SubtaskManager({super.key});

  @override
  State<SubtaskManager> createState() => _SubtaskManagerState();
}

class _SubtaskManagerState extends State<SubtaskManager> {
  @override
  void dispose() {
    super.dispose();
  }

  bool _isFutureTask() {
    final addTaskProvider = context.read<AddTaskProvider>();
    if (addTaskProvider.editTask == null || addTaskProvider.editTask!.routineID == null || addTaskProvider.editTask!.taskDate == null) {
      return false;
    }

    final today = DateTime.now();
    final taskDate = addTaskProvider.editTask!.taskDate!;

    // Compare only dates, not time
    final todayDate = DateTime(today.year, today.month, today.day);
    final taskDateOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);

    return taskDateOnly.isAfter(todayDate);
  }

  void _showSubtaskDialog({SubTaskModel? subtask}) {
    // Unfocus any active text fields
    final provider = context.read<AddTaskProvider>();
    provider.unfocusAll();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => SubtaskDialog(
        subtask: subtask,
        onSave: (title, description) {
          if (subtask == null) {
            // Add new subtask
            _addNewSubtask(title, description);
          } else {
            // Edit existing subtask
            _editSubtask(subtask, title, description);
          }
        },
      ),
    );
  }

  void _addNewSubtask(String title, String? description) {
    final addTaskProvider = context.read<AddTaskProvider>();

    // Generate a unique ID for the subtask
    int subtaskId = 1;
    if (addTaskProvider.subtasks.isNotEmpty) {
      subtaskId = addTaskProvider.subtasks.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
    }

    addTaskProvider.addSubtask(SubTaskModel(
      id: subtaskId,
      title: title,
      description: description,
    ));
  }

  void _editSubtask(SubTaskModel subtask, String title, String? description) {
    final addTaskProvider = context.read<AddTaskProvider>();
    final index = addTaskProvider.subtasks.indexWhere((s) => s.id == subtask.id);

    if (index != -1) {
      // Update the subtask
      addTaskProvider.updateSubtask(
        index,
        SubTaskModel(
          id: subtask.id,
          title: title,
          description: description,
          isCompleted: subtask.isCompleted,
        ),
      );
    }
  }

  void _toggleSubtaskCompletion(int index) {
    final addTaskProvider = context.read<AddTaskProvider>();

    // Check if this is a future routine task - prevent completion for future tasks
    if (_isFutureTask()) {
      // Show warning for future routine tasks using Helper message (same as main task)
      return Helper().getMessage(
        status: StatusEnum.WARNING,
        message: 'You cannot complete subtasks for future routine tasks. Please wait until ${DateFormat('MMM dd').format(addTaskProvider.editTask!.taskDate!)} to complete this subtask.',
      );
    }

    // Check if this subtask is being completed (not already completed)
    final bool isSubtaskBeingCompleted = !addTaskProvider.subtasks[index].isCompleted;

    if (isSubtaskBeingCompleted) {
      // Add haptic feedback when completing a subtask
      HapticFeedback.lightImpact();
    }

    addTaskProvider.toggleSubtaskCompletion(index);
  }

  void _removeSubtask(int index) {
    final addTaskProvider = context.read<AddTaskProvider>();
    addTaskProvider.removeSubtask(index);
  }

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();
    final subtaskCount = addTaskProvider.subtasks.length;
    final completedCount = addTaskProvider.subtasks.where((subtask) => subtask.isCompleted).length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Unfocus any text fields before showing bottom sheet
          addTaskProvider.unfocusAll();

          // Show the subtasks bottom sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.transparent,
            builder: (context) => SubtasksBottomSheet(
              onAddSubtask: () => _showSubtaskDialog(),
              onEditSubtask: (subtask) => _showSubtaskDialog(subtask: subtask),
              onToggleSubtask: _toggleSubtaskCompletion,
              onRemoveSubtask: _removeSubtask,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Subtasks icon
              Icon(
                Icons.checklist_rounded,
                color: AppColors.main,
                size: 20,
              ),
              const SizedBox(width: 8),

              // Subtasks text
              Text(
                LocaleKeys.Subtasks.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(width: 8),

              // Subtask count indicator
              if (subtaskCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.main.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$completedCount/$subtaskCount",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.main,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  "No subtasks",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const Spacer(),

              // Add button
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    _showSubtaskDialog();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.add_rounded,
                      color: AppColors.main,
                      size: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Arrow icon to indicate it opens a bottom sheet
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.text.withValues(alpha: 0.3),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubtasksBottomSheet extends StatefulWidget {
  final VoidCallback onAddSubtask;
  final Function(SubTaskModel) onEditSubtask;
  final Function(int) onToggleSubtask;
  final Function(int) onRemoveSubtask;

  const SubtasksBottomSheet({
    super.key,
    required this.onAddSubtask,
    required this.onEditSubtask,
    required this.onToggleSubtask,
    required this.onRemoveSubtask,
  });

  @override
  State<SubtasksBottomSheet> createState() => _SubtasksBottomSheetState();
}

class _SubtasksBottomSheetState extends State<SubtasksBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();

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
                      bulletPoints: const ["Break down your task into smaller steps", "Tap checkbox to mark subtask as completed", "Long press to edit a subtask", "Swipe left to delete a subtask", "Drag to reorder subtasks"],
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
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onAddSubtask,
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
          ),
          const SizedBox(height: 16),

          // Subtasks list or empty state
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: addTaskProvider.subtasks.isEmpty
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
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: addTaskProvider.subtasks.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = addTaskProvider.subtasks.removeAt(oldIndex);
                          addTaskProvider.subtasks.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final subtask = addTaskProvider.subtasks[index];
                        // Check if this is a future routine task
                        final isFutureRoutine = addTaskProvider.editTask != null && addTaskProvider.editTask!.routineID != null && addTaskProvider.editTask!.taskDate != null && addTaskProvider.editTask!.taskDate!.isAfter(DateTime.now());
                        return _buildSubtaskItem(subtask, index, isFutureRoutine);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtaskItem(SubTaskModel subtask, int index, bool isFutureRoutine) {
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
        widget.onRemoveSubtask(index);
      },
      child: GestureDetector(
        onLongPress: () {
          // Edit subtask on long press
          widget.onEditSubtask(subtask);
        },
        onTap: () {
          // Edit subtask on long press
          widget.onEditSubtask(subtask);
        },
        child: Container(
          key: Key('subtask_item_${subtask.id}'),
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
                    // Don't allow interaction for future routine tasks
                    if (isFutureRoutine) {
                      return;
                    }
                    widget.onToggleSubtask(index);
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
                        color: isFutureRoutine
                            ? AppColors.text.withValues(alpha: 0.1) // Very faded for future routines
                            : (subtask.isCompleted ? AppColors.main : AppColors.text.withValues(alpha: 0.3)),
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
}
