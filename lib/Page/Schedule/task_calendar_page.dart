import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/add_task_page.dart';
import 'package:gamify_todo/Service/navigator_service.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';

class TaskCalendarPage extends StatelessWidget {
  const TaskCalendarPage({super.key});

  String _getDurationText(TaskModel task) {
    if (task.remainingDuration == null) return 'Belirtilmemiş';

    if (task.type == TaskTypeEnum.COUNTER) {
      final totalMicroseconds = task.remainingDuration!.inMicroseconds * task.targetCount!;
      final totalDuration = Duration(microseconds: totalMicroseconds.toInt());
      return totalDuration.textShort2hour();
    }

    return task.remainingDuration!.textShort2hour();
  }

  Duration _calculateTotalDuration(List<TaskModel> tasks) {
    int totalMicroseconds = 0;

    for (var task in tasks) {
      if (task.remainingDuration != null) {
        if (task.type == TaskTypeEnum.COUNTER) {
          totalMicroseconds += task.remainingDuration!.inMicroseconds * task.targetCount!;
        } else {
          totalMicroseconds += task.remainingDuration!.inMicroseconds;
        }
      }
    }

    return Duration(microseconds: totalMicroseconds);
  }

  Map<DateTime, List<TaskModel>> _groupTasksByDate(List<TaskModel> tasks) {
    final Map<DateTime, List<TaskModel>> grouped = {};

    for (var task in tasks) {
      final date = DateTime(
        task.taskDate.year,
        task.taskDate.month,
        task.taskDate.day,
      );

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(task);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.taskList.where((task) => task.routineID == null).toList();
    final groupedTasks = _groupTasksByDate(tasks);
    final sortedDates = groupedTasks.keys.toList()..sort();

    if (sortedDates.isEmpty) {
      return const Center(
        child: Text('Henüz görev eklenmemiş'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Table(
        border: TableBorder.all(
          color: AppColors.text.withAlpha(51),
          width: 1,
        ),
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(
              color: AppColors.text.withAlpha(26),
            ),
            children: const [
              TableCell(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Tarih',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Görevler',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          // Date rows
          ...sortedDates.map((date) {
            final dayTasks = groupedTasks[date]!;
            final totalDuration = _calculateTotalDuration(dayTasks);

            return TableRow(
              children: [
                // Date
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${date.day}/${date.month}/${date.year}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Toplam: ${totalDuration.textShort2hour()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text.withAlpha(179),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tasks for the day
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: dayTasks
                          .map(
                            (task) => InkWell(
                              onTap: () async {
                                await NavigatorService().goTo(
                                  AddTaskPage(editTask: task),
                                  transition: Transition.rightToLeft,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.task_alt, color: Colors.green, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(task.title),
                                          if (task.description?.isNotEmpty ?? false)
                                            Text(
                                              task.description!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.text.withAlpha(179),
                                              ),
                                            ),
                                          Text(
                                            '${_getDurationText(task)}${task.time != null ? ' • ${task.time!.hour}:${task.time!.minute.toString().padLeft(2, '0')}' : ''}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.text.withAlpha(179),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
