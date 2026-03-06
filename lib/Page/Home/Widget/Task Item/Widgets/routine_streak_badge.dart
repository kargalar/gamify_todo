import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/task_streak_helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';

class RoutineStreakBadge extends StatelessWidget {
  const RoutineStreakBadge({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  Widget build(BuildContext context) {
    if (taskModel.routineID == null) {
      return const SizedBox.shrink();
    }

    return Consumer<TaskLogProvider>(
      builder: (context, taskLogProvider, child) {
        final stats = TaskStreakHelper.calculateStats(
          taskLogProvider.getLogsByRoutineId(taskModel.routineID!),
          anchorDate: taskModel.taskDate,
        );

        if (stats.currentStreak <= 0) {
          return const SizedBox.shrink();
        }

        return Tooltip(
          message: '${LocaleKeys.CurrentStreak.tr()}: ${stats.currentStreak}',
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 2),
                Text(
                  '${stats.currentStreak}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
