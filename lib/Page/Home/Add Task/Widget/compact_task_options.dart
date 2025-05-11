import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/category_model.dart';
import 'package:gamify_todo/Model/subtask_model.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/category_selector.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/location_input.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/select_priority.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/subtask_dialog.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/subtask_manager.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Provider/category_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';

class CompactTaskOptions extends StatelessWidget {
  const CompactTaskOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    // Get selected category if any
    CategoryModel? selectedCategory;
    if (addTaskProvider.categoryId != null) {
      selectedCategory = categoryProvider.categoryList.firstWhere(
        (category) => category.id == addTaskProvider.categoryId,
        orElse: () => CategoryModel(title: LocaleKeys.NoCategory.tr(), color: AppColors.main),
      );
    }

    // Get priority color, icon and text
    Color priorityColor;
    IconData priorityIcon;
    String priorityText;

    switch (addTaskProvider.priority) {
      case 1:
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high_rounded;
        priorityText = LocaleKeys.HighPriority.tr();
        break;
      case 2:
        priorityColor = Colors.orange;
        priorityIcon = Icons.drag_handle_rounded;
        priorityText = LocaleKeys.MediumPriority.tr();
        break;
      default:
        priorityColor = Colors.green;
        priorityIcon = Icons.arrow_downward_rounded;
        priorityText = LocaleKeys.LowPriority.tr();
    }

    // Get subtask info
    final subtaskCount = addTaskProvider.subtasks.length;
    final completedCount = addTaskProvider.subtasks.where((subtask) => subtask.isCompleted).length;

    // Get location info
    final hasLocation = addTaskProvider.locationController.text.isNotEmpty;

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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: AppColors.main,
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                "Task Options",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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

          // Options grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Location option
              _buildOptionItem(
                context: context,
                icon: Icons.location_on_rounded,
                iconColor: hasLocation ? AppColors.main : AppColors.text.withValues(alpha: 0.5),
                label: LocaleKeys.Location.tr(),
                value: hasLocation ? addTaskProvider.locationController.text : null,
                onTap: () {
                  addTaskProvider.unfocusAll();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const LocationBottomSheet(),
                  );
                },
              ),

              // Priority option
              _buildOptionItem(
                context: context,
                icon: priorityIcon,
                iconColor: priorityColor,
                label: LocaleKeys.Priority.tr(),
                value: priorityText,
                valueColor: priorityColor,
                onTap: () {
                  addTaskProvider.unfocusAll();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const PriorityBottomSheet(),
                  );
                },
              ),

              // Category option
              _buildOptionItem(
                context: context,
                icon: Icons.label_rounded,
                iconColor: selectedCategory != null ? selectedCategory.color : AppColors.text.withValues(alpha: 0.5),
                label: LocaleKeys.Category.tr(),
                value: selectedCategory?.title,
                valueColor: selectedCategory?.color,
                onTap: () {
                  addTaskProvider.unfocusAll();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const CategoryBottomSheet(),
                  );
                },
              ),

              // Subtasks option
              _buildOptionItem(
                context: context,
                icon: Icons.checklist_rounded,
                iconColor: subtaskCount > 0 ? AppColors.main : AppColors.text.withValues(alpha: 0.5),
                label: LocaleKeys.Subtasks.tr(),
                value: subtaskCount > 0 ? "$completedCount/$subtaskCount" : null,
                valueColor: AppColors.main,
                onTap: () {
                  addTaskProvider.unfocusAll();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => SubtasksBottomSheet(
                      onAddSubtask: () => _showSubtaskDialog(context),
                      onEditSubtask: (subtask) => _showSubtaskDialog(context, subtask: subtask),
                      onToggleSubtask: (index) => _toggleSubtaskCompletion(context, index),
                      onRemoveSubtask: (index) => _removeSubtask(context, index),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    String? value,
    Color? valueColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.42, // Approximately 2 items per row
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.text.withValues(alpha: 0.1),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text.withValues(alpha: 0.7),
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: valueColor ?? AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.text.withValues(alpha: 0.3),
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for subtasks
  void _showSubtaskDialog(BuildContext context, {SubTaskModel? subtask}) {
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
            _addNewSubtask(context, title, description);
          } else {
            _editSubtask(context, subtask, title, description);
          }
        },
      ),
    );
  }

  void _addNewSubtask(BuildContext context, String title, String? description) {
    final addTaskProvider = context.read<AddTaskProvider>();

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

  void _editSubtask(BuildContext context, SubTaskModel subtask, String title, String? description) {
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

  void _toggleSubtaskCompletion(BuildContext context, int index) {
    final addTaskProvider = context.read<AddTaskProvider>();
    addTaskProvider.toggleSubtaskCompletion(index);
  }

  void _removeSubtask(BuildContext context, int index) {
    final addTaskProvider = context.read<AddTaskProvider>();
    addTaskProvider.removeSubtask(index);
  }
}
