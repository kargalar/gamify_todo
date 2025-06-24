import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

class ArchiveButton extends StatelessWidget {
  const ArchiveButton({
    super.key,
    required this.routine,
    required this.taskModel,
  });

  final RoutineModel routine;
  final TaskModel taskModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () async {
          // Show confirmation dialog
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(LocaleKeys.ArchiveRoutine.tr()),
              content: Text(LocaleKeys.ArchiveRoutineConfirmation.tr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(LocaleKeys.Cancel.tr()),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(LocaleKeys.ArchiveRoutine.tr()),
                ),
              ],
            ),
          );
          if (confirm == true) {
            // Mark routine as archived
            routine.isArchived = true;

            // Update the routine
            await ServerManager().updateRoutine(routineModel: routine);

            // Mark all related tasks as archived
            final tasks = TaskProvider().taskList.where((t) => t.routineID == taskModel.routineID);
            for (var task in tasks) {
              // Only archive tasks that are not already archived to preserve existing status
              if (task.status != TaskStatusEnum.ARCHIVED) {
                task.status = TaskStatusEnum.ARCHIVED;
                await ServerManager().updateTask(taskModel: task);

                // Create log for the archiving action to maintain history
                TaskLogProvider().addTaskLog(
                  task,
                  customStatus: TaskStatusEnum.ARCHIVED,
                );
              }
            }

            // Note: We deliberately DO NOT delete task logs here to preserve progress history
            // The logs will remain in the database and will be available when the routine is unarchived

            TaskProvider().updateItems();
          }
        },
        child: Text(LocaleKeys.ArchiveRoutine.tr()),
      ),
    );
  }
}
