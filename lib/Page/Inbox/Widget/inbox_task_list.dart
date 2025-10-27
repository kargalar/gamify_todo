import 'dart:ui';

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
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:provider/provider.dart';

class InboxTaskList extends StatefulWidget {
  final CategoryModel? selectedCategory;
  final String searchQuery;
  final bool showRoutines;
  final bool showTasks;
  final bool showTodayTasks;
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
    required this.showTodayTasks,
    required this.dateFilterState,
    required this.selectedTaskTypes,
    required this.selectedStatuses,
    required this.showEmptyStatus,
  });

  @override
  State<InboxTaskList> createState() => _InboxTaskListState();
}

class _InboxTaskListState extends State<InboxTaskList> {
  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    // Get tasks based on selected category
    List<TaskModel> allTasks;
    if (widget.selectedCategory != null) {
      allTasks = taskProvider.getTasksByCategoryId(widget.selectedCategory!.id);
    } else {
      allTasks = taskProvider.getAllTasks();
    }

    // Exclude archived routines from all tasks (they have their own page)
    final allTasksWithoutArchived = allTasks.where((task) {
      bool isArchived = task.status == TaskStatusEnum.ARCHIVED;
      return !isArchived;
    }).toList();

    // Check if there are no tasks at all (before any filters)
    if (allTasksWithoutArchived.isEmpty) {
      LogService.debug('📭 Inbox: No tasks found at all');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 100, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.NoTasksYet.tr(),
              style: TextStyle(
                fontSize: 18,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.AddFirstTask.tr(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Start with all tasks
    List<TaskModel> tasks = List.from(allTasksWithoutArchived);

    // Apply routine/task filter
    tasks = tasks.where((task) {
      bool isRoutine = task.routineID != null;

      // For routines
      if (isRoutine) {
        return widget.showRoutines;
      }

      // For non-routine tasks
      return widget.showTasks;
    }).toList();

    // Apply task type filter
    tasks = tasks.where((task) => widget.selectedTaskTypes.contains(task.type)).toList();

    // Apply date filter
    LogService.debug('📅 InboxTaskList: Applying date filter: ${widget.dateFilterState}');

    tasks = tasks.where((task) {
      switch (widget.dateFilterState) {
        case DateFilterState.all:
          return true; // Show all tasks
        case DateFilterState.withDate:
          // Show tasks with dates
          return task.taskDate != null;
        case DateFilterState.withoutDate:
          return task.taskDate == null; // Show only tasks without dates
      }
    }).toList();

    LogService.debug('📊 InboxTaskList: After date filter, ${tasks.length} tasks remaining');

    // Apply status filtering
    tasks = tasks.where((task) {
      bool matchesStatus = false;

      // Check if task matches selected statuses
      if (widget.selectedStatuses.isNotEmpty && widget.selectedStatuses.contains(task.status)) {
        matchesStatus = true;
      }

      // Check if task matches empty status filter
      if (widget.showEmptyStatus && task.status == null) {
        matchesStatus = true;
      }

      // If no filters are selected, show nothing
      if (widget.selectedStatuses.isEmpty && !widget.showEmptyStatus) {
        return false;
      }

      return matchesStatus;
    }).toList();

    // Apply search filter if search query is not empty
    if (widget.searchQuery.isNotEmpty) {
      tasks = tasks.where((task) {
        final lowerQuery = widget.searchQuery.toLowerCase();

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

    // Check if tasks are empty after filters
    if (tasks.isEmpty) {
      LogService.debug('🔍 Inbox: No tasks found after applying filters');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.NoTasksFound.tr(),
              style: TextStyle(
                fontSize: 18,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
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

        // Filter out today's tasks if showTodayTasks is false
        if (!widget.showTodayTasks && date == todayDate) {
          debugPrint('🔍 [Inbox Filter] Today task filtered out: ${task.title}');
          continue;
        }

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

    // 2. Add today's tasks (if any)
    if (groupedTasks.containsKey(todayDate)) {
      sortedDates.add(todayDate);
      debugPrint('✅ [Inbox Filter] Today tasks section added: ${groupedTasks[todayDate]!.length} tasks');
    }

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

    // Check if all tasks were filtered out during grouping (e.g., by showTodayTasks filter)
    if (sortedDates.isEmpty) {
      LogService.debug('🔍 Inbox: All tasks filtered out during grouping (showTodayTasks: ${widget.showTodayTasks})');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.NoTasksFound.tr(),
              style: TextStyle(
                fontSize: 18,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Build list with year separators
    final List<Widget> listChildren = [];
    int? lastPrintedYear;
    final currentYear = DateTime.now().year;
    for (final date in sortedDates) {
      final tasksForDate = groupedTasks[date]!;

      // sortOrder'a göre sırala (yüksekten düşüğe)
      tasksForDate.sort((a, b) => b.sortOrder.compareTo(a.sortOrder));

      final bool isRealDate = date.year > 1970; // skip sentinel years 1969 (overdue) & 1970 (no date)
      if (isRealDate && lastPrintedYear != date.year && date.year != currentYear) {
        // Insert year header (skip current year)
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

      // Her tarih grubu için ReorderableListView
      listChildren.add(
        _buildReorderableTaskGroup(
          tasks: tasksForDate,
          groupDate: date,
          taskProvider: taskProvider,
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => NavbarProvider().updateIndex(1),
      child: ListView(
        children: listChildren,
      ),
    );
  }

  Widget _buildReorderableTaskGroup({
    required List<TaskModel> tasks,
    required DateTime groupDate,
    required TaskProvider taskProvider,
  }) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      padding: EdgeInsets.zero,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final double animValue = Curves.easeInOut.transform(animation.value);
            final double elevation = lerpDouble(0, 6, animValue)!;
            final double scale = lerpDouble(1.0, 1.02, animValue)!;
            return Transform.scale(
              scale: scale,
              child: Material(
                elevation: elevation,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      onReorder: (int oldIndex, int newIndex) {
        _handleTaskReorder(
          tasks: tasks,
          groupDate: groupDate,
          oldIndex: oldIndex,
          newIndex: newIndex,
          taskProvider: taskProvider,
        );
      },
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ReorderableDragStartListener(
          key: ValueKey(task.key),
          index: index,
          child: TaskItem(taskModel: task),
        );
      },
    );
  }

  Future<void> _handleTaskReorder({
    required List<TaskModel> tasks,
    required DateTime groupDate,
    required int oldIndex,
    required int newIndex,
    required TaskProvider taskProvider,
  }) async {
    try {
      LogService.debug('🔄 Inbox: Reordering task from $oldIndex to $newIndex in group ${DateFormat('dd/MM/yyyy').format(groupDate)}');

      // ReorderableListView'in klasik sorunu - düzeltme yap
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      if (oldIndex >= tasks.length || newIndex >= tasks.length || oldIndex < 0 || newIndex < 0) {
        LogService.error('❌ Inbox: Invalid reorder indices - oldIndex: $oldIndex, newIndex: $newIndex, listLength: ${tasks.length}');
        return;
      }

      // Taşınacak task'ı listeden çıkar
      final movedTask = tasks.removeAt(oldIndex);

      // Yeni pozisyona ekle
      tasks.insert(newIndex, movedTask);

      // Tüm task'lara yeni sortOrder değerlerini ata
      final updatedTasks = <TaskModel>[];
      for (int i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        final newSortOrder = tasks.length - i;

        if (task.sortOrder != newSortOrder) {
          task.sortOrder = newSortOrder;
          updatedTasks.add(task);
          LogService.debug('  ✏️ Updated Task ${task.id}: sortOrder → $newSortOrder');
        }
      }

      // UI'ı hemen güncelle
      setState(() {});
      LogService.debug('  🎨 UI updated immediately');

      // Veritabanına kaydet (arka planda)
      for (final updatedTask in updatedTasks) {
        try {
          await updatedTask.save();
          await ServerManager().updateTask(taskModel: updatedTask);
        } catch (e) {
          LogService.error('❌ Error saving task ${updatedTask.id}: $e');
        }
      }

      LogService.debug('✅ Inbox: Tasks reordered and saved successfully');
    } catch (e) {
      LogService.error('❌ Inbox: Error reordering tasks: $e');
      setState(() {});
    }
  }
}
