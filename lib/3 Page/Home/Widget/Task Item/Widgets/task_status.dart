import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/2%20General/app_colors.dart';
import 'package:gamify_todo/5%20Service/locale_keys.g.dart';
import 'package:gamify_todo/7%20Enum/task_status_enum.dart';
import 'package:gamify_todo/7%20Enum/task_type_enum.dart';
import 'package:gamify_todo/8%20Model/task_model.dart';

class TaskStatus extends StatelessWidget {
  const TaskStatus({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  Widget build(BuildContext context) {
    final List<Widget> statusWidgets = [];

    // Show completed status if completed
    if (taskModel.status == TaskStatusEnum.COMPLETED || (taskModel.type == TaskTypeEnum.COUNTER && taskModel.currentCount! >= taskModel.targetCount!) || (taskModel.type == TaskTypeEnum.TIMER && taskModel.currentDuration! >= taskModel.remainingDuration!)) {
      statusWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.green.withAlpha(80),
            borderRadius: AppColors.borderRadiusAll,
          ),
          child: Text(
            LocaleKeys.Completed.tr(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Show archived status if archived
    if (taskModel.status == TaskStatusEnum.ARCHIVED) {
      statusWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          margin: statusWidgets.isNotEmpty ? const EdgeInsets.only(left: 4) : null,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withAlpha(150), width: 1),
            borderRadius: AppColors.borderRadiusAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.archive_outlined,
                size: 12,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Archived',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show failed status
    if (taskModel.status == TaskStatusEnum.FAILED) {
      statusWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          margin: statusWidgets.isNotEmpty ? const EdgeInsets.only(left: 4) : null,
          decoration: BoxDecoration(
            color: AppColors.red.withAlpha(100),
            borderRadius: AppColors.borderRadiusAll,
          ),
          child: Text(
            LocaleKeys.Failed.tr(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Show cancel status
    if (taskModel.status == TaskStatusEnum.CANCEL) {
      statusWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          margin: statusWidgets.isNotEmpty ? const EdgeInsets.only(left: 4) : null,
          decoration: BoxDecoration(
            color: AppColors.purple.withAlpha(100),
            borderRadius: AppColors.borderRadiusAll,
          ),
          child: Text(
            LocaleKeys.Cancel.tr(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (statusWidgets.isEmpty) {
      return const SizedBox();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: statusWidgets,
    );
  }
}
