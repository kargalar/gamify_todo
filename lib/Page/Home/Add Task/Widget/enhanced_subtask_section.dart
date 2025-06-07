import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/subtask_dialog.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/subtask_manager.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';

class EnhancedSubtaskSection extends StatefulWidget {
  const EnhancedSubtaskSection({super.key});

  @override
  State<EnhancedSubtaskSection> createState() => _EnhancedSubtaskSectionState();
}

class _EnhancedSubtaskSectionState extends State<EnhancedSubtaskSection> {
  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();
    final subtaskCount = addTaskProvider.subtasks.length;
    final completedCount = addTaskProvider.subtasks.where((subtask) => subtask.isCompleted).length;

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => subtaskCount > 0 ? _showSubtasksBottomSheet() : _showSubtaskDialog(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Icon
                Icon(
                  Icons.checklist_rounded,
                  color: AppColors.main,
                  size: 20,
                ),
                const SizedBox(width: 8),

                // Title
                Text(
                  LocaleKeys.Subtasks.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(width: 8),

                // Content based on state
                if (subtaskCount > 0) ...[
                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.main.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.main.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$completedCount/$subtaskCount",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.main,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.main.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: subtaskCount > 0 ? completedCount / subtaskCount : 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.main,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                GestureDetector(
                  onTap: () => _showSubtaskDialog(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.main.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: AppColors.main,
                      size: 16,
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.text.withValues(alpha: 0.3),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
            _addNewSubtask(title, description);
          } else {
            _editExistingSubtask(subtask, title, description);
          }
          setState(() {}); // Refresh the UI
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

  void _editExistingSubtask(SubTaskModel subtask, String title, String? description) {
    final addTaskProvider = context.read<AddTaskProvider>();
    final index = addTaskProvider.subtasks.indexWhere((s) => s.id == subtask.id);

    if (index != -1) {
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
    addTaskProvider.toggleSubtaskCompletion(index);
    setState(() {}); // Refresh the UI
  }

  void _showSubtasksBottomSheet() {
    final addTaskProvider = context.read<AddTaskProvider>();
    addTaskProvider.unfocusAll();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => SubtasksBottomSheet(
        onAddSubtask: () => _showSubtaskDialog(),
        onEditSubtask: (subtask) => _showSubtaskDialog(subtask: subtask),
        onToggleSubtask: _toggleSubtaskCompletion,
        onRemoveSubtask: (index) {
          final addTaskProvider = context.read<AddTaskProvider>();
          addTaskProvider.removeSubtask(index);
          setState(() {}); // Refresh the UI
        },
      ),
    );
  }
}
