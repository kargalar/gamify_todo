import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
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
                  if (selectedDateTaskList.isEmpty) const SizedBox(height: 10),
                  Text(
                    LocaleKeys.Routines.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedDateRutinTaskList.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(0),
                      itemCount: selectedDateRutinTaskList.length,
                      itemBuilder: (context, index) {
                        return TaskItem(taskModel: selectedDateRutinTaskList[index]);
                      },
                    ),
                ],

                // Future routines ghosts
                if (selectedDateGhostRutinTaskList.isNotEmpty) ...[
                  if (selectedDateTaskList.isEmpty) const SizedBox(height: 10),
                  Text(
                    LocaleKeys.FutureRoutines.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepPurple,
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(0),
                    itemCount: selectedDateGhostRutinTaskList.length,
                    itemBuilder: (context, index) {
                      return TaskItem(taskModel: selectedDateGhostRutinTaskList[index]);
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
