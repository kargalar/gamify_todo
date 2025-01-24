import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/task_model.dart';

class TaskTime extends StatelessWidget {
  const TaskTime({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (taskModel.time != null) ...[
          Text(
            taskModel.time!.to24Hours(),
          ),
          const SizedBox(width: 5),
        ],
        if (taskModel.isNotificationOn) ...[
          Icon(
            Icons.notifications,
            color: AppColors.dirtyMain,
          ),
        ] else if (taskModel.isAlarmOn) ...[
          const Icon(
            Icons.alarm,
            color: AppColors.dirtyRed,
          ),
        ]
      ],
    );
  }
}
