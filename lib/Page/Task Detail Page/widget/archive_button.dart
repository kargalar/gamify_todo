import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Service/server_manager.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Model/routine_model.dart';
import 'package:gamify_todo/Model/task_model.dart';

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
              title: const Text('Archive Routine'),
              content: const Text('Are you sure you want to archive this routine? This will stop new task creation but you can still view its statistics. Geri döndürülemez.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Archive'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            // Mark routine as completed
            routine.isArchived = true;

            // Update the routine
            await ServerManager().updateRoutine(routineModel: routine);

            // Mark all related tasks as archived
            final tasks = TaskProvider().taskList.where((t) => t.routineID == taskModel.routineID);

            for (var task in tasks) {
              task.status = TaskStatusEnum.ARCHIVED;
              await ServerManager().updateTask(taskModel: task);
            }

            TaskProvider().updateItems();
          }
        },
        child: const Text('Archive Routine'),
      ),
    );
  }
}
