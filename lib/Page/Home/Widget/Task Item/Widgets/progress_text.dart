import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Home/Widget/Task%20Item/Widgets/task_status.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/task_model.dart';

class ProgressText extends StatelessWidget {
  const ProgressText({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  Widget build(BuildContext context) {
    if (taskModel.type == TaskTypeEnum.CHECKBOX && taskModel.status == null) return const SizedBox();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (taskModel.type != TaskTypeEnum.CHECKBOX) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.panelBackground2.withAlpha(77),
              borderRadius: BorderRadius.circular(8),
            ),
            child: taskModel.type == TaskTypeEnum.COUNTER
                ? Text(
                    "${taskModel.currentCount ?? 0}/${taskModel.targetCount ?? 0}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Text(
                    "${taskModel.currentDuration!.textShortDynamic()}/${taskModel.remainingDuration!.textShortDynamic()}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: taskModel.isTimerActive! ? AppColors.main : null,
                    ),
                  ),
          ),
          const SizedBox(width: 5),
        ],
        TaskStatus(taskModel: taskModel),
      ],
    );
  }
}
