import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/Enums/status_enum.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/subtask_model.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';

class SubtaskManager extends StatefulWidget {
  const SubtaskManager({super.key});

  @override
  State<SubtaskManager> createState() => _SubtaskManagerState();
}

class _SubtaskManagerState extends State<SubtaskManager> {
  final TextEditingController _subtaskController = TextEditingController();

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
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
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Ensure this field gets focus when tapping anywhere in the container
                    final provider = context.read<AddTaskProvider>();
                    provider.subtaskFocus.requestFocus();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground,
                      borderRadius: AppColors.borderRadiusAll,
                    ),
                    child: TextField(
                      controller: _subtaskController,
                      focusNode: addTaskProvider.subtaskFocus,
                      autofocus: false, // Don't autofocus on page load
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: LocaleKeys.AddSubtask.tr(),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        suffixIcon: _subtaskController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _subtaskController.clear();
                                  // Unfocus after clearing
                                  try {
                                    if (addTaskProvider.subtaskFocus.hashCode != 0) {
                                      addTaskProvider.subtaskFocus.unfocus();
                                    }
                                  } catch (e) {
                                    // Focus node may have issues
                                  }
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        // Force rebuild to show/hide clear button
                        setState(() {});
                      },
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        _addSubtask();
                        // Unfocus after adding subtask
                        addTaskProvider.subtaskFocus.unfocus();
                      },
                      onTap: () {
                        // Ensure other text fields are unfocused, but keep this one focused
                        final provider = context.read<AddTaskProvider>();

                        // First unfocus all fields
                        provider.taskNameFocus.unfocus();
                        provider.descriptionFocus.unfocus();
                        provider.locationFocus.unfocus();

                        // Then explicitly request focus for this field
                        provider.subtaskFocus.requestFocus();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  _addSubtask();
                  // Unfocus after adding subtask
                  addTaskProvider.subtaskFocus.unfocus();
                },
                borderRadius: AppColors.borderRadiusAll,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.main,
                    borderRadius: AppColors.borderRadiusAll,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
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
                  provider.subtaskFocus.unfocus();
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
                decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                color: subtask.isCompleted ? AppColors.text.withValues(alpha: 0.6) : AppColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () {
              // Unfocus when removing subtask
              final provider = context.read<AddTaskProvider>();
              provider.subtaskFocus.unfocus();
              provider.unfocusAll();
              _removeSubtask(index);
            },
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline,
                size: 20,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) {
      Helper().getMessage(
        message: LocaleKeys.SubtaskEmpty.tr(),
        status: StatusEnum.WARNING,
      );
      return;
    }

    final addTaskProvider = context.read<AddTaskProvider>();

    // Unfocus all text fields
    addTaskProvider.subtaskFocus.unfocus();
    addTaskProvider.unfocusAll();

    // Generate a unique ID for the subtask
    int subtaskId = 1;
    if (addTaskProvider.subtasks.isNotEmpty) {
      subtaskId = addTaskProvider.subtasks.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
    }

    addTaskProvider.addSubtask(SubTaskModel(
      id: subtaskId,
      title: text,
    ));

    _subtaskController.clear();
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
