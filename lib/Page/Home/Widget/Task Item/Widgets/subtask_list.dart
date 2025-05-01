import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/subtask_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/subtask_dialog.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';

class SubtaskList extends StatefulWidget {
  const SubtaskList({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  State<SubtaskList> createState() => _SubtaskListState();
}

class _SubtaskListState extends State<SubtaskList> {
  late bool _showSubtasks;

  @override
  void initState() {
    super.initState();
    // Hive'da kaydedilmiş değeri kullan, yoksa görev tamamlandıysa gizle, tamamlanmadıysa göster
    _showSubtasks = widget.taskModel.showSubtasks ?? !(widget.taskModel.status == TaskStatusEnum.COMPLETED);

    // Eğer showSubtasks null ise, varsayılan değeri kaydet
    if (widget.taskModel.showSubtasks == null) {
      widget.taskModel.showSubtasks = _showSubtasks;
      // Değişikliği kaydet
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.editTask(taskModel: widget.taskModel, selectedDays: []);
    }
  }

  @override
  void didUpdateWidget(SubtaskList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Görev durumu değiştiyse (tamamlandı -> tamamlanmadı) alt görevleri göster
    if (oldWidget.taskModel.status == TaskStatusEnum.COMPLETED && widget.taskModel.status != TaskStatusEnum.COMPLETED) {
      setState(() {
        _showSubtasks = true;
        // Değişikliği kaydet
        widget.taskModel.showSubtasks = _showSubtasks;
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        taskProvider.editTask(taskModel: widget.taskModel, selectedDays: []);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.taskModel.subtasks == null || widget.taskModel.subtasks!.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showSubtasks = !_showSubtasks;
                // Değişikliği kaydet
                widget.taskModel.showSubtasks = _showSubtasks;
                final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                taskProvider.editTask(taskModel: widget.taskModel, selectedDays: []);
              });
            },
            child: Row(
              children: [
                Icon(
                  _showSubtasks ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  _showSubtasks ? LocaleKeys.HideSubtasks.tr() : LocaleKeys.ShowSubtasks.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (_showSubtasks) ...widget.taskModel.subtasks!.map((subtask) => _buildSubtaskItem(context, subtask)),
        ],
      ),
    );
  }

  Widget _buildSubtaskItem(BuildContext context, SubTaskModel subtask) {
    return InkWell(
      onTap: () {
        _toggleSubtaskCompletion(context, subtask);
      },
      onLongPress: () {
        // Show edit dialog when long-pressed
        _showSubtaskEditDialog(context, subtask);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: subtask.isCompleted,
                    activeColor: AppColors.main,
                    onChanged: (value) {
                      if (value != null) {
                        _toggleSubtaskCompletion(context, subtask);
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
              ],
            ),
            // Show description if available
            if (subtask.description != null && subtask.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 2),
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
    );
  }

  void _toggleSubtaskCompletion(BuildContext context, SubTaskModel subtask) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.toggleSubtaskCompletion(widget.taskModel, subtask);
  }

  void _showSubtaskEditDialog(BuildContext context, SubTaskModel subtask) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubtaskDialog(
        subtask: subtask,
        onSave: (title, description) {
          // Update the subtask with new title and description
          final taskProvider = Provider.of<TaskProvider>(context, listen: false);
          taskProvider.updateSubtask(widget.taskModel, subtask, title, description);
        },
      ),
    );
  }
}
