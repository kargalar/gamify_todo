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
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.Subtasks.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              _showSubtaskDialog();
            },
            borderRadius: AppColors.borderRadiusAll,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: AppColors.borderRadiusAll,
                border: Border.all(color: AppColors.main.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocaleKeys.AddSubtask.tr(),
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  Icon(
                    Icons.add_circle_outline,
                    color: AppColors.main,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (addTaskProvider.subtasks.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: addTaskProvider.subtasks.length,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: subtask.isCompleted,
                    activeColor: AppColors.main,
                    onChanged: (value) {
                      if (value != null) {
                        // Unfocus when toggling subtask
                        final provider = context.read<AddTaskProvider>();
                        provider.unfocusAll();
                        _toggleSubtaskCompletion(index);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subtask.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                      color: subtask.isCompleted ? AppColors.text.withValues(alpha: 0.6) : AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () {
                    // Edit subtask
                    _showSubtaskDialog(subtask: subtask);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.main,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    // Unfocus when removing subtask
                    final provider = context.read<AddTaskProvider>();
                    provider.unfocusAll();
                    _removeSubtask(index);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ],
            ),
            if (subtask.description != null && subtask.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 4, right: 8),
                child: Text(
                  subtask.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text.withValues(alpha: 0.7),
                    decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
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
