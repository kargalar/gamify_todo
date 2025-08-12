import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Page/Home/Widget/create_category_bottom_sheet.dart';
import 'package:next_level/Page/Inbox/Widget/date_filter_state.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';

class InboxCategoriesSection extends StatelessWidget {
  final CategoryModel? selectedCategory;
  final Function(CategoryModel?) onCategorySelected;
  final String searchQuery;
  final bool showRoutines;
  final bool showTasks;
  final DateFilterState dateFilterState;
  final Set<TaskTypeEnum> selectedTaskTypes;
  final Set<TaskStatusEnum> selectedStatuses;
  final bool showEmptyStatus;

  const InboxCategoriesSection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryContent(context),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final categories = categoryProvider.getActiveCategories();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All tasks option
          _buildCategoryTag(
            context,
            null,
            isSelected: selectedCategory == null,
            taskProvider: taskProvider,
          ),
          const SizedBox(width: 8),

          // Category tags
          ...categories.map((category) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildCategoryTag(
                  context,
                  category,
                  isSelected: selectedCategory?.id == category.id,
                  taskProvider: taskProvider,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(BuildContext context, CategoryModel? category, {required bool isSelected, required TaskProvider taskProvider}) {
    final color = category?.color ?? AppColors.main;

    // Get tasks for this specific category as if it were selected
    List<dynamic> tasks;
    if (category != null) {
      tasks = taskProvider.getTasksByCategoryId(category.id);
    } else {
      tasks = taskProvider.getAllTasks();
    }

    // Apply the same filtering logic as InboxTaskList would for this category
    tasks = _applyFilters(tasks, forCategory: category);

    final int taskCount = tasks.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onCategorySelected(category),
        onLongPress: category != null
            ? () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.transparent,
                  builder: (context) => CreateCategoryBottomSheet(categoryModel: category),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.panelBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
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
                const SizedBox(width: 8),
              ],

              // Category name
              Text(
                category?.title ?? LocaleKeys.AllTasks.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppColors.text.withValues(alpha: 0.7),
                ),
              ),

              // Task count
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.2) : AppColors.text.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  taskCount.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : AppColors.text.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Apply the same filtering logic as InboxTaskList
  List<dynamic> _applyFilters(List<dynamic> tasks, {CategoryModel? forCategory}) {
    // Apply routine/task filter
    tasks = tasks.where((task) {
      bool isRoutine = task.routineID != null;
      return (isRoutine && showRoutines) || (!isRoutine && showTasks);
    }).toList();

    // Apply task type filter
    tasks = tasks.where((task) => selectedTaskTypes.contains(task.type)).toList();

    // Apply date filter (mirror InboxTaskList grouping: today's dated tasks are not shown, so don't count them)
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    tasks = tasks.where((task) {
      switch (dateFilterState) {
        case DateFilterState.all:
          // Include undated tasks and dated tasks except those dated today
          if (task.taskDate == null) return true;
          final d = DateTime(task.taskDate!.year, task.taskDate!.month, task.taskDate!.day);
          return d != todayDate;
        case DateFilterState.withDate:
          // Include only dated tasks except those dated today
          if (task.taskDate == null) return false;
          final d = DateTime(task.taskDate!.year, task.taskDate!.month, task.taskDate!.day);
          return d != todayDate;
        case DateFilterState.withoutDate:
          // Only undated tasks
          return task.taskDate == null;
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

    return tasks;
  }
}
