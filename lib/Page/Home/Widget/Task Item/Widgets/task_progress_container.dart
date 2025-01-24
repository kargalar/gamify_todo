import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/task_model.dart';

class TaskProgressContainer extends StatelessWidget {
  const TaskProgressContainer({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 2,
      width: taskModel.status == TaskStatusEnum.COMPLETED
          ? 1.sw
          : taskModel.type == TaskTypeEnum.TIMER
              ? ((taskModel.currentDuration?.inSeconds ?? 0) / (taskModel.remainingDuration?.inSeconds ?? 1)).clamp(0.0, 1.0) * 1.sw
              : taskModel.type == TaskTypeEnum.COUNTER
                  ? ((taskModel.currentCount ?? 0) / (taskModel.targetCount ?? 1)).clamp(0.0, 1.0) * 1.sw
                  : 0.sw,
      decoration: BoxDecoration(
        color: AppColors.deepMain,
      ),
    );
  }
}
