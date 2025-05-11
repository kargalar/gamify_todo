import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/subtask_model.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/subtask_dialog.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Widgets/clickable_tooltip.dart';
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

  void _showSubtaskDialog({SubTaskModel? subtask}) {
    // Unfocus any active text fields
    final provider = context.read<AddTaskProvider>();
    provider.unfocusAll();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClickableTooltip(
                title: LocaleKeys.Subtasks.tr(),
                bulletPoints: const ["Break down your task into smaller steps", "Tap checkbox to mark subtask as completed", "Long press to edit a subtask", "Swipe left to delete a subtask", "Drag to reorder subtasks"],
                child: Container(
                  color: AppColors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        Icons.checklist_rounded,
                        color: AppColors.main,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        LocaleKeys.Subtasks.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
                    _showSubtaskDialog();
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

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Subtasks list or empty state
          if (addTaskProvider.subtasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_box_outline_blank_rounded,
                      color: AppColors.text.withValues(alpha: 0.3),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "No subtasks",
                      style: TextStyle(
                        color: AppColors.text.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
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
                  return _buildCompactSubtaskItem(subtask, index);
                },
              ),
            ),
        ],
      ),
    );
  }

  // Compact version of subtask item for side-by-side layout
  Widget _buildCompactSubtaskItem(SubTaskModel subtask, int index) {
    return Dismissible(
      key: Key('subtask_${subtask.id}'),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
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
        _removeSubtask(index);
      },
      child: GestureDetector(
        onLongPress: () {
          // Edit subtask on long press
          _showSubtaskDialog(subtask: subtask);
        },
        child: Container(
          key: Key('subtask_item_${subtask.id}'),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: subtask.isCompleted ? AppColors.main.withValues(alpha: 0.05) : AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: subtask.isCompleted ? AppColors.main.withValues(alpha: 0.2) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // Checkbox with animation
                InkWell(
                  onTap: () {
                    final provider = context.read<AddTaskProvider>();
                    provider.unfocusAll();
                    _toggleSubtaskCompletion(index);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 16,
                    height: 16,
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
                              size: 12,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 6),

                // Title with animation
                Expanded(
                  child: Text(
                    subtask.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: subtask.isCompleted ? FontWeight.normal : FontWeight.bold,
                      decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                      color: subtask.isCompleted ? AppColors.text.withValues(alpha: 0.5) : AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Action buttons - more compact
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _showSubtaskDialog(subtask: subtask);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: AppColors.main.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),

                    // Delete button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final provider = context.read<AddTaskProvider>();
                          provider.unfocusAll();
                          _removeSubtask(index);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 14,
                            color: AppColors.red.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),

                    // Drag handle
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            size: 14,
                            color: AppColors.text.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _removeSubtask(int index) {
    final addTaskProvider = context.read<AddTaskProvider>();
    addTaskProvider.removeSubtask(index);
  }

  void _toggleSubtaskCompletion(int index) {
    final addTaskProvider = context.read<AddTaskProvider>();
    addTaskProvider.toggleSubtaskCompletion(index);
  }
}
