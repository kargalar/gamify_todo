import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/subtask_model.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/subtask_dialog.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    color: AppColors.main,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LocaleKeys.Subtasks.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _showSubtaskDialog();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.main.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: AppColors.main,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          LocaleKeys.AddSubtask.tr(),
                          style: TextStyle(
                            color: AppColors.main,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Subtasks list or empty state
          if (addTaskProvider.subtasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_box_outline_blank_rounded,
                      color: AppColors.text.withValues(alpha: 0.3),
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No subtasks",
                      style: TextStyle(
                        color: AppColors.text.withValues(alpha: 0.5),
                        fontSize: 14,
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
                return _buildSubtaskItem(subtask, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSubtaskItem(SubTaskModel subtask, int index) {
    return Dismissible(
      key: Key('subtask_${subtask.id}'),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_rounded,
          color: AppColors.red,
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
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: subtask.isCompleted ? AppColors.main.withValues(alpha: 0.05) : AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: subtask.isCompleted ? AppColors.main.withValues(alpha: 0.2) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Checkbox with animation
                    InkWell(
                      onTap: () {
                        final provider = context.read<AddTaskProvider>();
                        provider.unfocusAll();
                        _toggleSubtaskCompletion(index);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: subtask.isCompleted ? AppColors.main : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: subtask.isCompleted ? AppColors.main : AppColors.text.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: subtask.isCompleted
                            ? const Center(
                                child: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title with animation
                    Expanded(
                      child: Text(
                        subtask.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: subtask.isCompleted ? FontWeight.normal : FontWeight.bold,
                          decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                          color: subtask.isCompleted ? AppColors.text.withValues(alpha: 0.5) : AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Action buttons
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
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 18,
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
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.red.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),

                        // Drag handle
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.drag_handle_rounded,
                                size: 18,
                                color: AppColors.text.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Description with animation
                if (subtask.description != null && subtask.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 34, top: 6, right: 8),
                    child: Text(
                      subtask.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtask.isCompleted ? AppColors.text.withValues(alpha: 0.4) : AppColors.text.withValues(alpha: 0.7),
                        decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
