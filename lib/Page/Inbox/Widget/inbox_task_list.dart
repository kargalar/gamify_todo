import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Widget/task_item.dart';
import 'package:next_level/Page/Inbox/Widget/inbox_date_header.dart';
import 'package:next_level/Page/Inbox/Widget/date_filter_state.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';

class InboxTaskList extends StatelessWidget {
  final CategoryModel? selectedCategory;
  final String searchQuery;
  final bool showRoutines;
  final bool showTasks;
  final bool showPinned;
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
    required this.showPinned,
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

    // Apply routine/task filter and exclude archived routines
    tasks = tasks.where((task) {
      bool isRoutine = task.routineID != null;
      bool isArchived = task.status == TaskStatusEnum.ARCHIVED;

      // If it's a routine
      if (isRoutine) {
        // Never show archived routines in inbox (they have their own page)
        if (isArchived) {
          return false;
        }
        // Show non-archived routines based on showRoutines flag
        return showRoutines;
      }

      // For non-routine tasks, use the showTasks flag
      return showTasks;
    }).toList();

    // Apply pinned filter
    if (showPinned) {
      tasks = tasks.where((task) => task.isPinned).toList();
    }

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
        final lowerQuery = searchQuery.toLowerCase();

        // Search in task title and description
        bool matchesTask = task.title.toLowerCase().contains(lowerQuery) || (task.description?.toLowerCase().contains(lowerQuery) ?? false);

        // Search in subtasks titles and descriptions
        bool matchesSubtasks = false;
        if (task.subtasks != null && task.subtasks!.isNotEmpty) {
          matchesSubtasks = task.subtasks!.any((subtask) {
            return subtask.title.toLowerCase().contains(lowerQuery) || (subtask.description?.toLowerCase().contains(lowerQuery) ?? false);
          });
        }

        return matchesTask || matchesSubtasks;
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

    // Group tasks by date and status
    final Map<DateTime, List<TaskModel>> groupedTasks = {};
    final List<TaskModel> overdueTasks = [];
    final List<TaskModel> tasksWithoutDate = [];
    final DateTime today = DateTime.now();
    final DateTime todayDate = DateTime(today.year, today.month, today.day);

    for (var task in tasks) {
      if (task.status == TaskStatusEnum.OVERDUE) {
        // Overdue tasks go to a special group
        overdueTasks.add(task);
      } else if (task.taskDate == null) {
        // Tasks without date
        tasksWithoutDate.add(task);
      } else {
        final date = DateTime(task.taskDate!.year, task.taskDate!.month, task.taskDate!.day);
        if (!groupedTasks.containsKey(date)) {
          groupedTasks[date] = [];
        }
        groupedTasks[date]!.add(task);
      }
    }

    // Create ordered list of dates with special keys
    final List<DateTime> sortedDates = [];

    // 1. Add overdue tasks first (if any)
    if (overdueTasks.isNotEmpty) {
      final overdueDate = DateTime(1969, 1, 1); // Special date for overdue tasks
      groupedTasks[overdueDate] = overdueTasks;
      sortedDates.add(overdueDate);
    }

    // 2. Add today's tasks
    // if (groupedTasks.containsKey(todayDate)) {
    //   sortedDates.add(todayDate);
    // }

    // 3. Add tasks without dates
    if (tasksWithoutDate.isNotEmpty) {
      final inboxDate = DateTime(1970, 1, 1); // Special date for inbox/no date
      groupedTasks[inboxDate] = tasksWithoutDate;
      sortedDates.add(inboxDate);
    }

    // 4. Add future tasks (sorted ascending)
    final futureDates = groupedTasks.keys.where((date) => date.isAfter(todayDate) && date.year > 1970).toList()..sort();
    sortedDates.addAll(futureDates);

    // 5. Add past tasks (sorted descending - most recent first)
    final pastDates = groupedTasks.keys.where((date) => date.isBefore(todayDate) && date.year > 1970).toList()..sort((a, b) => b.compareTo(a)); // Descending order
    sortedDates.addAll(pastDates);

    // Build list with year separators
    final List<Widget> listChildren = [];
    int? lastPrintedYear;
    for (final date in sortedDates) {
      final tasksForDate = groupedTasks[date]!;
      taskProvider.sortTasksByPriorityAndTime(tasksForDate);

      final bool isRealDate = date.year > 1970; // skip sentinel years 1969 (overdue) & 1970 (no date)
      if (isRealDate && lastPrintedYear != date.year) {
        // Insert year header
        lastPrintedYear = date.year;
        listChildren.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              date.year.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.main,
                letterSpacing: 1.1,
              ),
            ),
          ),
        );
      }

      listChildren.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: InboxDateHeader(date: date),
        ),
      );
      listChildren.addAll(tasksForDate.map((task) => TaskItem(taskModel: task)));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => NavbarProvider().updateIndex(1),
      child: ListView(
        children: listChildren,
      ),
    );
  }
}
