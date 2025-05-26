import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Widget/task_item.dart';
import 'package:next_level/Page/Inbox/Widget/inbox_date_header.dart';
import 'package:next_level/Page/Inbox/Widget/date_filter_state.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';

class InboxTaskList extends StatelessWidget {
  final CategoryModel? selectedCategory;
  final String searchQuery;
  final bool showRoutines;
  final bool showTasks;
  final DateFilterState dateFilterState;
  final Set<TaskTypeEnum> selectedTaskTypes;
  final Set<TaskStatusEnum> selectedStatuses;
  final bool showEmptyStatus;

  const InboxTaskList({
    super.key,
    required this.selectedCategory,
    required this.searchQuery,
    required this.showRoutines,
    required this.showTasks,
    required this.dateFilterState,
    required this.selectedTaskTypes,
    required this.selectedStatuses,
    required this.showEmptyStatus,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    // Get tasks based on selected category
    List<TaskModel> tasks;
    if (selectedCategory != null) {
      tasks = taskProvider.getTasksByCategoryId(selectedCategory!.id);
    } else {
      tasks = taskProvider.getAllTasks();
    }

    // Apply routine/task filter
    tasks = tasks.where((task) {
      bool isRoutine = task.routineID != null;
      return (isRoutine && showRoutines) || (!isRoutine && showTasks);
    }).toList();

    // Apply task type filter
    tasks = tasks.where((task) => selectedTaskTypes.contains(task.type)).toList();

    // Apply date filter
    tasks = tasks.where((task) {
      switch (dateFilterState) {
        case DateFilterState.all:
          return true; // Show all tasks
        case DateFilterState.withDate:
          return task.taskDate != null; // Show only tasks with dates
        case DateFilterState.withoutDate:
          return task.taskDate == null; // Show only tasks without dates
      }
    }).toList();

    // Apply status filtering
    tasks = tasks.where((task) {
      bool matchesStatus = false;

      // Check if task matches selected statuses
      if (selectedStatuses.isNotEmpty && selectedStatuses.contains(task.status)) {
        matchesStatus = true;
      }

      // Check if task matches empty status filter
      if (showEmptyStatus && task.status == null) {
        matchesStatus = true;
      }

      // If no filters are selected, show nothing
      if (selectedStatuses.isEmpty && !showEmptyStatus) {
        return false;
      }

      return matchesStatus;
    }).toList();

    // Apply search filter if search query is not empty
    if (searchQuery.isNotEmpty) {
      tasks = tasks.where((task) {
        return task.title.toLowerCase().contains(searchQuery.toLowerCase()) || (task.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              selectedCategory != null ? LocaleKeys.NoTasksInCategory.tr() : LocaleKeys.NoTasksYet.tr(),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Group tasks by date
    final Map<DateTime, List<TaskModel>> groupedTasks = {};
    final List<TaskModel> tasksWithoutDate = [];

    for (var task in tasks) {
      if (task.taskDate == null) {
        tasksWithoutDate.add(task);
      } else {
        final date = DateTime(task.taskDate!.year, task.taskDate!.month, task.taskDate!.day);
        if (!groupedTasks.containsKey(date)) {
          groupedTasks[date] = [];
        }
        groupedTasks[date]!.add(task);
      }
    }

    // Add tasks without dates at the top with a special key
    if (tasksWithoutDate.isNotEmpty) {
      final inboxDate = DateTime(1970, 1, 1); // Special date for inbox/no date
      groupedTasks[inboxDate] = tasksWithoutDate;
    }

    // Sort dates
    final sortedDates = groupedTasks.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final tasksForDate = groupedTasks[date]!;

        // Sort tasks by priority and time
        taskProvider.sortTasksByPriorityAndTime(tasksForDate);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            InboxDateHeader(date: date),
            const SizedBox(height: 8),

            // Tasks for this date
            ...tasksForDate.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TaskItem(taskModel: task),
                )),

            // Add space between date groups
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
