import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/category_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Page/Home/Widget/create_category_dialog.dart';
import 'package:gamify_todo/Page/Home/Widget/task_item.dart';
import 'package:gamify_todo/Provider/category_provider.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  CategoryModel? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          LocaleKeys.Categories,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Add category button
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text(
              LocaleKeys.AddCategory,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Get.dialog(const CreateCategoryDialog());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category tags
          _buildCategoryTags(),

          // Divider
          Divider(
            color: AppColors.text.withValues(alpha: 0.1),
            height: 1,
            thickness: 1,
          ),

          // Task list
          Expanded(
            child: _buildTaskList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTags() {
    final categoryProvider = context.watch<CategoryProvider>();
    final activeCategories = categoryProvider.getActiveCategories();

    if (activeCategories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              Text(
                LocaleKeys.NoCategoriesYet,
                style: TextStyle(
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Get.dialog(const CreateCategoryDialog());
                },
                icon: const Icon(Icons.add),
                label: const Text(LocaleKeys.AddCategory),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.main,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // "All" tag
          _buildCategoryTag(
            null,
            isSelected: _selectedCategory == null,
          ),

          // Category tags
          ...activeCategories.map((category) => _buildCategoryTag(
                category,
                isSelected: _selectedCategory?.id == category.id,
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(CategoryModel? category, {required bool isSelected}) {
    final color = category?.color ?? AppColors.main;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.panelBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.text.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color indicator
            if (category != null) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],

            // Category name
            Text(
              category?.title ?? LocaleKeys.AllTasks,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppColors.text.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    final taskProvider = context.watch<TaskProvider>();

    // Get tasks based on selected category
    List<TaskModel> tasks;
    if (_selectedCategory != null) {
      tasks = taskProvider.getTasksByCategoryId(_selectedCategory!.id);
    } else {
      tasks = taskProvider.getAllTasks();
    }

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _selectedCategory != null ? LocaleKeys.NoTasksInCategory : LocaleKeys.NoTasksYet,
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
      dateText = LocaleKeys.Today;
    } else if (date.isAtSameMomentAs(tomorrow)) {
      dateText = LocaleKeys.Tomorrow;
    } else if (date.isAtSameMomentAs(yesterday)) {
      dateText = LocaleKeys.Yesterday;
    } else {
      dateText = "${date.day}/${date.month}/${date.year}";
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
