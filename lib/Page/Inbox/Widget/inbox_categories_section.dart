import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Page/Home/Widget/create_category_bottom_sheet.dart';
import 'package:next_level/Page/Inbox/Widget/date_filter_state.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/Provider/projects_provider.dart';
import 'package:next_level/Widgets/Common/category_filter_widget.dart';
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
    final categoryProvider = context.watch<CategoryProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final projectsProvider = context.watch<ProjectsProvider>();
    final categories = categoryProvider.getActiveCategories();

    // Group categories by type
    final taskCategories = categories.where((cat) => cat.categoryType == CategoryType.task).toList();
    final noteCategories = categories.where((cat) => cat.categoryType == CategoryType.note).toList();
    final projectCategories = categories.where((cat) => cat.categoryType == CategoryType.project).toList();

    // Calculate counts for each category by type
    final Map<dynamic, int> itemCounts = {};
    for (final category in categories) {
      int count = 0;

      switch (category.categoryType) {
        case CategoryType.task:
          final tasks = taskProvider.getTasksByCategoryId(category.id);
          final filteredTasks = _applyFilters(tasks, forCategory: category);
          count = filteredTasks.length;
          break;
        case CategoryType.note:
          final notes = notesProvider.notes.where((note) => note.categoryId == category.id).toList();
          count = notes.length;
          break;
        case CategoryType.project:
          final projects = projectsProvider.projects.where((project) => project.categoryId == category.id).toList();
          count = projects.length;
          break;
      }

      itemCounts[category.id] = count;
    }

    // Calculate total count for "All" option
    final allTasks = taskProvider.getAllTasks();
    final filteredAllTasks = _applyFilters(allTasks, forCategory: null);
    final totalTaskCount = filteredAllTasks.length;

    final allNotes = notesProvider.notes;
    final allProjects = projectsProvider.projects;

    final totalCount = totalTaskCount + allNotes.length + allProjects.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task Categories
        if (taskCategories.isNotEmpty) ...[
          _buildCategorySection(
            context,
            'Tasks',
            taskCategories,
            itemCounts,
            Icons.task,
            Colors.blue,
          ),
          const SizedBox(height: 16),
        ],

        // Note Categories
        if (noteCategories.isNotEmpty) ...[
          _buildCategorySection(
            context,
            'Notes',
            noteCategories,
            itemCounts,
            Icons.note,
            Colors.green,
          ),
          const SizedBox(height: 16),
        ],

        // Project Categories
        if (projectCategories.isNotEmpty) ...[
          _buildCategorySection(
            context,
            'Projects',
            projectCategories,
            itemCounts,
            Icons.folder,
            Colors.orange,
          ),
          const SizedBox(height: 16),
        ],

        // All Categories (fallback if no typed categories)
        if (taskCategories.isEmpty && noteCategories.isEmpty && projectCategories.isEmpty)
          CategoryFilterWidget(
            categories: categories,
            selectedCategoryId: selectedCategory?.id,
            onCategorySelected: (categoryId) {
              if (categoryId == null) {
                onCategorySelected(null);
              } else {
                final category = categories.firstWhere((cat) => cat.id == categoryId);
                onCategorySelected(category);
              }
            },
            showAllOption: true,
            itemCounts: {
              ...itemCounts,
              null: totalCount,
            },
            onCategoryLongPress: (context, category) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.transparent,
                builder: (context) => CreateCategoryBottomSheet(categoryModel: category),
              );
            },
            showIcons: false,
            showColors: true,
            showAddButton: true,
            onAddCategory: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.transparent,
                builder: (context) => const CreateCategoryBottomSheet(
                  initialCategoryType: CategoryType.task,
                ),
              );
            },
            showEmptyCategories: true,
          ),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    List<CategoryModel> categories,
    Map<dynamic, int> itemCounts,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),

        // Categories
        CategoryFilterWidget(
          categories: categories,
          selectedCategoryId: selectedCategory?.id,
          onCategorySelected: (categoryId) {
            if (categoryId == null) {
              onCategorySelected(null);
            } else {
              final category = categories.firstWhere((cat) => cat.id == categoryId);
              onCategorySelected(category);
            }
          },
          showAllOption: false,
          itemCounts: itemCounts,
          onCategoryLongPress: (context, category) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              barrierColor: Colors.transparent,
              builder: (context) => CreateCategoryBottomSheet(categoryModel: category),
            );
          },
          showIcons: false,
          showColors: true,
          showAddButton: false,
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
