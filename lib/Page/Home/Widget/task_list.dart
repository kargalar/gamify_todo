import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Page/Home/Widget/task_item.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:provider/provider.dart';

class TaskList extends StatefulWidget {
  const TaskList({super.key});

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    context.watch<AddTaskProvider>();

    final selectedDate = taskProvider.selectedDate;
    final selectedDateTaskList = taskProvider.getTasksForDate(selectedDate);
    final selectedDateRutinTaskList = taskProvider.getRoutineTasksForDate(selectedDate);
    final selectedDateGhostRutinTaskList = taskProvider.getGhostRoutineTasksForDate(selectedDate);

    return selectedDateTaskList.isEmpty && selectedDateGhostRutinTaskList.isEmpty && selectedDateRutinTaskList.isEmpty
        ? Center(
            child: Text(
              LocaleKeys.NoTaskForToday.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : SingleChildScrollView(
            child: Column(
              children: [
                // Normal tasks
                if (selectedDateTaskList.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(0),
                    itemCount: selectedDateTaskList.length,
                    itemBuilder: (context, index) {
                      return TaskItem(taskModel: selectedDateTaskList[index]);
                    },
                  ),

                // Routine Tasks
                if (selectedDateRutinTaskList.isNotEmpty) ...[
                  if (selectedDateTaskList.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 15),
                  ],
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(0),
                    itemCount: selectedDateRutinTaskList.length,
                    itemBuilder: (context, index) {
                      return TaskItem(
                        taskModel: selectedDateRutinTaskList[index],
                        isRoutine: true,
                      );
                    },
                  ),
                ],

                // Future routines ghosts
                if (selectedDateGhostRutinTaskList.isNotEmpty) ...[
                  if (selectedDateTaskList.isNotEmpty || selectedDateRutinTaskList.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 15),
                  ],
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(0),
                    itemCount: selectedDateGhostRutinTaskList.length,
                    itemBuilder: (context, index) {
                      return TaskItem(
                        taskModel: selectedDateGhostRutinTaskList[index],
                        isRoutine: true,
                      );
                    },
                  ),
                ],

                // navbar space
                const SizedBox(height: 100),
              ],
            ),
          );
  }
}
