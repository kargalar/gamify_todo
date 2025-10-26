import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Page/Home/Widget/create_category_bottom_sheet.dart';
import 'package:next_level/Page/Inbox/Widget/date_filter_state.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Widgets/Common/category_filter_widget.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Service/logging_service.dart';

class InboxCategoriesSection extends StatelessWidget {
  final CategoryModel? selectedCategory;
  final Function(CategoryModel?) onCategorySelected;
  final String searchQuery;
  final bool showRoutines;
  final bool showTasks;
  final bool showTodayTasks;
  final DateFilterState dateFilterState;
  final Set<TaskTypeEnum> selectedTaskTypes;
  final Set<TaskStatusEnum> selectedStatuses;
  final bool showEmptyStatus;
  final VoidCallback? onCategoryDeleted; // Callback for when a category is deleted

  const InboxCategoriesSection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.searchQuery,
    required this.showRoutines,
    required this.showTasks,
    required this.showTodayTasks,
    required this.dateFilterState,
    required this.selectedTaskTypes,
    required this.selectedStatuses,
    required this.showEmptyStatus,
    this.onCategoryDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final categories = categoryProvider.getActiveCategories();

    // SADECE TASK KATEGORİLERİNİ GÖSTER (Inbox sadece task'lar için)
    final taskCategories = categories.where((cat) => cat.categoryType == CategoryType.task).toList();

    // Calculate counts for task categories only
    final Map<dynamic, int> itemCounts = {};
    for (final category in taskCategories) {
      final tasks = taskProvider.getTasksByCategoryId(category.id);
      final filteredTasks = _applyFilters(tasks, forCategory: category);
      itemCounts[category.id] = filteredTasks.length;
    }

    // Calculate total count for "All" option (only tasks)
    final allTasks = taskProvider.getAllTasks();
    final filteredAllTasks = _applyFilters(allTasks, forCategory: null);
    final totalTaskCount = filteredAllTasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task kategorileri (boş olsa bile "Tümü" ve "Ekle" butonu göster)
        CategoryFilterWidget(
          categories: taskCategories,
          selectedCategoryId: selectedCategory?.id,
          onCategorySelected: (categoryId) {
            if (categoryId == null) {
              onCategorySelected(null);
            } else {
              final category = taskCategories.firstWhere((cat) => cat.id == categoryId);
              onCategorySelected(category);
            }
          },
          showAllOption: true,
          itemCounts: {
            ...itemCounts,
            null: totalTaskCount,
          },
          onCategoryLongPress: (context, category) async {
            final result = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              barrierColor: Colors.transparent,
              builder: (context) => CreateCategoryBottomSheet(categoryModel: category),
            );

            // Eğer kategori silindiyse, CategoryProvider'ı yeniden yükle ve parent'ı bilgilendir
            if (result == true && context.mounted) {
              LogService.debug('🔄 InboxCategoriesSection: Category deleted, reloading CategoryProvider');
              await context.read<CategoryProvider>().initialize();
              LogService.debug('✅ InboxCategoriesSection: CategoryProvider reloaded');

              // Parent widget'ı bilgilendir (setState çağırsın)
              onCategoryDeleted?.call();
            }
          },
          showIcons: false,
          showColors: true,
          showAddButton: true,
          categoryType: CategoryType.task,
          showEmptyCategories: true,
        ),
      ],
    );
  }

  // Apply the same filtering logic as InboxTaskList
  List<dynamic> _applyFilters(List<dynamic> tasks, {CategoryModel? forCategory}) {
    // Apply routine/task filter
    tasks = tasks.where((task) {
      bool isRoutine = task.routineID != null;
      return (isRoutine && showRoutines) || (!isRoutine && showTasks);
    }).toList();

    // Apply pinned filter - NOTE: Pin filter now only affects sorting, not filtering
    // We keep this for backward compatibility but it doesn't filter out tasks
    // The actual pin sorting happens in inbox_task_list.dart

    // Apply task type filter
    tasks = tasks.where((task) => selectedTaskTypes.contains(task.type)).toList();

    // Apply date filter
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    tasks = tasks.where((task) {
      // Filter out today's tasks if showTodayTasks is false
      if (task.taskDate != null) {
        final taskDateOnly = DateTime(task.taskDate!.year, task.taskDate!.month, task.taskDate!.day);
        if (!showTodayTasks && taskDateOnly.isAtSameMomentAs(todayDate)) {
          return false;
        }
      }

      switch (dateFilterState) {
        case DateFilterState.all:
          return true; // Show all tasks (except today if showTodayTasks is false)
        case DateFilterState.withDate:
          // Show tasks with dates (excluding today)
          if (task.taskDate == null) return false;
          final taskDateOnly = DateTime(task.taskDate!.year, task.taskDate!.month, task.taskDate!.day);
          return !taskDateOnly.isAtSameMomentAs(todayDate);
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
