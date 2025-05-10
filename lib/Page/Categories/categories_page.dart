import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/category_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Page/Home/Widget/create_category_dialog.dart';
import 'package:gamify_todo/Page/Home/Widget/task_item.dart';
import 'package:gamify_todo/Provider/category_provider.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  CategoryModel? _selectedCategory;

  // Filter states
  bool _showRoutines = true;
  bool _showTasks = true;
  final Set<TaskTypeEnum> _selectedTaskTypes = {
    TaskTypeEnum.CHECKBOX,
    TaskTypeEnum.COUNTER,
    TaskTypeEnum.TIMER,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocaleKeys.Tasks.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Filter menu button
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              size: 20,
              color: AppColors.text,
            ),
            tooltip: "Filters",
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories section only
          _buildCategoriesSection(),

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
          // for navbbar
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 30),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(CategoryModel? category, {required bool isSelected}) {
    final color = category?.color ?? AppColors.main;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
        },
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
                category?.title ?? LocaleKeys.AllTasks,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppColors.text.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
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

    // Apply routine/task filter
    tasks = tasks.where((task) {
      bool isRoutine = task.routineID != null;
      return (isRoutine && _showRoutines) || (!isRoutine && _showTasks);
    }).toList();

    // Apply task type filter
    tasks = tasks.where((task) => _selectedTaskTypes.contains(task.type)).toList();

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

  // Method to build only the categories section
  Widget _buildCategoriesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories title with icon
          Row(
            children: [
              Icon(
                Icons.category_rounded,
                size: 20,
                color: AppColors.main,
              ),
              const SizedBox(width: 8),
              Text(
                "Categories",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Categories content
          _buildCategoryContent(),
        ],
      ),
    );
  }

  // Method to show the filter dialog
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Filters",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.text,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Task/Routine filter section
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "Task Type",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Row(
                  children: [
                    // Task filter
                    _buildFilterChip(
                      label: "Tasks",
                      icon: Icons.task_alt_rounded,
                      isSelected: _showTasks,
                      onTap: () {
                        setState(() {
                          _showTasks = !_showTasks;
                          // Ensure at least one filter is selected
                          if (!_showTasks && !_showRoutines) {
                            _showRoutines = true;
                          }
                        });
                        // Update the parent state
                        this.setState(() {});
                      },
                    ),
                    const SizedBox(width: 8),

                    // Routine filter
                    _buildFilterChip(
                      label: "Routines",
                      icon: Icons.repeat_rounded,
                      isSelected: _showRoutines,
                      onTap: () {
                        setState(() {
                          _showRoutines = !_showRoutines;
                          // Ensure at least one filter is selected
                          if (!_showRoutines && !_showTasks) {
                            _showTasks = true;
                          }
                        });
                        // Update the parent state
                        this.setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Task format filter section
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "Task Format",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Checkbox filter
                    _buildFilterChip(
                      label: "Checkbox",
                      icon: Icons.check_box_rounded,
                      isSelected: _selectedTaskTypes.contains(TaskTypeEnum.CHECKBOX),
                      onTap: () {
                        setState(() {
                          if (_selectedTaskTypes.contains(TaskTypeEnum.CHECKBOX)) {
                            _selectedTaskTypes.remove(TaskTypeEnum.CHECKBOX);
                            // Ensure at least one type is selected
                            if (_selectedTaskTypes.isEmpty) {
                              _selectedTaskTypes.add(TaskTypeEnum.CHECKBOX);
                            }
                          } else {
                            _selectedTaskTypes.add(TaskTypeEnum.CHECKBOX);
                          }
                        });
                        // Update the parent state
                        this.setState(() {});
                      },
                    ),

                    // Counter filter
                    _buildFilterChip(
                      label: "Counter",
                      icon: Icons.add_circle_outline_rounded,
                      isSelected: _selectedTaskTypes.contains(TaskTypeEnum.COUNTER),
                      onTap: () {
                        setState(() {
                          if (_selectedTaskTypes.contains(TaskTypeEnum.COUNTER)) {
                            _selectedTaskTypes.remove(TaskTypeEnum.COUNTER);
                            // Ensure at least one type is selected
                            if (_selectedTaskTypes.isEmpty) {
                              _selectedTaskTypes.add(TaskTypeEnum.COUNTER);
                            }
                          } else {
                            _selectedTaskTypes.add(TaskTypeEnum.COUNTER);
                          }
                        });
                        // Update the parent state
                        this.setState(() {});
                      },
                    ),

                    // Timer filter
                    _buildFilterChip(
                      label: "Timer",
                      icon: Icons.timer_rounded,
                      isSelected: _selectedTaskTypes.contains(TaskTypeEnum.TIMER),
                      onTap: () {
                        setState(() {
                          if (_selectedTaskTypes.contains(TaskTypeEnum.TIMER)) {
                            _selectedTaskTypes.remove(TaskTypeEnum.TIMER);
                            // Ensure at least one type is selected
                            if (_selectedTaskTypes.isEmpty) {
                              _selectedTaskTypes.add(TaskTypeEnum.TIMER);
                            }
                          } else {
                            _selectedTaskTypes.add(TaskTypeEnum.TIMER);
                          }
                        });
                        // Update the parent state
                        this.setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Add extra space at the bottom for devices with notches
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.main.withValues(alpha: 0.15) : AppColors.panelBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.text : AppColors.text.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryContent() {
    final categoryProvider = context.watch<CategoryProvider>();
    final activeCategories = categoryProvider.getActiveCategories();

    // Category title
    // Widget categoryTitle = Container(
    //   margin: const EdgeInsets.only(bottom: 8),
    //   child: Text(
    //     "Categories",
    //     style: TextStyle(
    //       fontSize: 14,
    //       fontWeight: FontWeight.w500,
    //       color: AppColors.text.withValues(alpha: 0.6),
    //     ),
    //   ),
    // );

    if (activeCategories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // categoryTitle,
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
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
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // categoryTitle,
        Wrap(
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

            // Add category button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Get.dialog(const CreateCategoryDialog());
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppColors.main,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
