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
  final bool showPinned;
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
    required this.showPinned,
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

    // "Tümü" chip'i için
    if (category == null) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox, size: 16),
              const SizedBox(width: 6),
              Text(LocaleKeys.AllTasks.tr()),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.3) : AppColors.panelBackground2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  taskCount.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          selectedColor: AppColors.main,
          backgroundColor: AppColors.panelBackground,
          checkmarkColor: Colors.white,
          onSelected: (_) => onCategorySelected(null),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.text,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    // Kategori chip'leri
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.transparent,
            builder: (context) => CreateCategoryBottomSheet(categoryModel: category),
          );
        },
        child: FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(category.title),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  taskCount.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          selectedColor: color.withValues(alpha: 0.3),
          backgroundColor: AppColors.panelBackground,
          checkmarkColor: color,
          onSelected: (_) => onCategorySelected(isSelected ? null : category),
          labelStyle: TextStyle(
            color: AppColors.text,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

    // Apply pinned filter
    if (showPinned) {
      tasks = tasks.where((task) => task.isPinned).toList();
    }

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
