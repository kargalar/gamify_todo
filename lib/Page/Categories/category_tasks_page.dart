import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/category_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Page/Home/Widget/task_item.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CategoryTasksPage extends StatelessWidget {
  final CategoryModel? category; // Optional category for filtering

  const CategoryTasksPage({
    super.key,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: category != null
            // Show category title and color if a category is provided
            ? Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: category!.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category!.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            // Show "All Tasks" title if no category is provided
            : Text(
                LocaleKeys.AllTasks.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      body: _TaskList(category: category),
    );
  }
}

class _TaskList extends StatelessWidget {
  final CategoryModel? category;

  const _TaskList({this.category});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    // Get tasks based on whether a category is provided
    final List<TaskModel> tasks = category != null ? taskProvider.getTasksByCategoryId(category!.id) : taskProvider.getAllTasks();

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              category != null ? LocaleKeys.NoTasksInCategory.tr() : LocaleKeys.NoTasksYet.tr(),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Group tasks by date
    final Map<DateTime, List<TaskModel>> groupedTasks = {};
    for (var task in tasks) {
      final date = DateTime(task.taskDate.year, task.taskDate.month, task.taskDate.day);
      if (!groupedTasks.containsKey(date)) {
        groupedTasks[date] = [];
      }
      groupedTasks[date]!.add(task);
    }

    // Sort dates
    final sortedDates = groupedTasks.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
            _buildDateHeader(date),
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

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    String dateText;
    if (date.isAtSameMomentAs(today)) {
      dateText = LocaleKeys.Today.tr();
    } else if (date.isAtSameMomentAs(tomorrow)) {
      dateText = LocaleKeys.Tomorrow.tr();
    } else if (date.isAtSameMomentAs(yesterday)) {
      dateText = LocaleKeys.Yesterday.tr();
    } else {
      dateText = DateFormat.yMMMd().format(date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        dateText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.text.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
