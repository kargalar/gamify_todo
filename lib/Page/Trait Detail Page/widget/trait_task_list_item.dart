import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Page/Task%20Detail%20Page/routine_detail_page.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';

class TraitTaskListItem extends StatelessWidget {
  final TaskModel task;
  final Duration taskDuration;
  final bool isRoutine;

  const TraitTaskListItem({
    super.key,
    required this.task,
    required this.taskDuration,
    this.isRoutine = false,
  });

  Color _getStatusColor(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.DONE:
        return AppColors.green;
      case TaskStatusEnum.FAILED:
        return AppColors.red;
      case TaskStatusEnum.CANCEL:
        return AppColors.purple;
      case TaskStatusEnum.ARCHIVED:
        return AppColors.blue;
      case TaskStatusEnum.OVERDUE:
        return AppColors.orange;
    }
  }

  String _getStatusText(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.DONE:
        return LocaleKeys.Done.tr();
      case TaskStatusEnum.FAILED:
        return LocaleKeys.Failed.tr();
      case TaskStatusEnum.CANCEL:
        return LocaleKeys.Cancelled.tr();
      case TaskStatusEnum.ARCHIVED:
        return LocaleKeys.Archived.tr();
      case TaskStatusEnum.OVERDUE:
        return LocaleKeys.Overdue.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArchived = task.status == TaskStatusEnum.ARCHIVED;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        if (isRoutine) {
          await NavigatorService().goTo(
            RoutineDetailPage(taskModel: task),
            transition: Transition.rightToLeft,
          );
        } else {
          await NavigatorService().goTo(
            AddTaskPage(editTask: task),
            transition: Transition.rightToLeft,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isArchived ? AppColors.panelBackground2.withValues(alpha: 0.5) : AppColors.panelBackground2,
          borderRadius: BorderRadius.circular(16),
          border: isArchived ? Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1) : null,
          boxShadow: isArchived
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isArchived ? Colors.grey : AppColors.text,
                      decoration: isArchived ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                ),
                if (!isRoutine && task.status != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status!).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(task.status!).withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _getStatusText(task.status!),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(task.status!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  task.taskDate != null ? task.taskDate!.toLocal().toString().split(' ')[0] : "No date",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.main.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppColors.main,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        taskDuration.textShort2hour(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.main,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
