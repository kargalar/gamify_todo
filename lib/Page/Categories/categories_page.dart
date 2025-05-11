import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/category_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Page/Home/Widget/create_category_bottom_sheet.dart';
import 'package:gamify_todo/Page/Home/Widget/task_item.dart';
import 'package:gamify_todo/Provider/category_provider.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

// Enum for date filter states
enum DateFilterState {
  all, // Show all tasks
  withDate, // Show only tasks with dates
  withoutDate // Show only tasks without dates
}

class _CategoriesPageState extends State<CategoriesPage> {
  CategoryModel? _selectedCategory;
  int? _selectedCategoryId;
  String _searchQuery = ''; // Arama sorgusu için değişken

  // Filter states
  bool _showRoutines = true;
  bool _showTasks = true;
  DateFilterState _dateFilterState = DateFilterState.withoutDate; // Default to showing tasks without dates
  final Set<TaskTypeEnum> _selectedTaskTypes = {
    TaskTypeEnum.CHECKBOX,
    TaskTypeEnum.COUNTER,
    TaskTypeEnum.TIMER,
  };

  @override
  void initState() {
    super.initState();
    _loadFilterPreferences();
  }

  // Load saved filter preferences from SharedPreferences
  Future<void> _loadFilterPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Load task/routine filter preferences
      _showTasks = prefs.getBool('categories_show_tasks') ?? true;
      _showRoutines = prefs.getBool('categories_show_routines') ?? true;

      // Load date filter preference
      final dateFilterIndex = prefs.getInt('categories_date_filter');
      if (dateFilterIndex != null && dateFilterIndex >= 0 && dateFilterIndex < DateFilterState.values.length) {
        _dateFilterState = DateFilterState.values[dateFilterIndex];
      } else {
        _dateFilterState = DateFilterState.withoutDate; // Default to withoutDate if no valid preference is found
      }
      debugPrint('Loaded date filter: $_dateFilterState (index: $dateFilterIndex)');

      // Load task type filter preferences
      final hasCheckbox = prefs.getBool('categories_show_checkbox') ?? true;
      final hasCounter = prefs.getBool('categories_show_counter') ?? true;
      final hasTimer = prefs.getBool('categories_show_timer') ?? true;

      // Clear and rebuild the set based on saved preferences
      _selectedTaskTypes.clear();
      if (hasCheckbox) _selectedTaskTypes.add(TaskTypeEnum.CHECKBOX);
      if (hasCounter) _selectedTaskTypes.add(TaskTypeEnum.COUNTER);
      if (hasTimer) _selectedTaskTypes.add(TaskTypeEnum.TIMER);

      // Ensure at least one task type is selected
      if (_selectedTaskTypes.isEmpty) {
        _selectedTaskTypes.add(TaskTypeEnum.CHECKBOX);
      }

      // Load selected category
      _selectedCategoryId = prefs.getInt('categories_selected_category_id');
    });

    // Load the selected category if there's a saved ID
    if (_selectedCategoryId != null) {
      // Use a mounted check to avoid using BuildContext across async gaps
      if (!mounted) return;

      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final categories = categoryProvider.getActiveCategories();
      for (var category in categories) {
        if (category.id == _selectedCategoryId) {
          setState(() {
            _selectedCategory = category;
          });
          break;
        }
      }
    }
  }

  // Save filter preferences to SharedPreferences
  Future<void> _saveFilterPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Save task/routine filter preferences
    await prefs.setBool('categories_show_tasks', _showTasks);
    await prefs.setBool('categories_show_routines', _showRoutines);

    // Save date filter preference
    await prefs.setInt('categories_date_filter', _dateFilterState.index);
    debugPrint('Saved date filter: $_dateFilterState (index: ${_dateFilterState.index})');

    // Save task type filter preferences
    await prefs.setBool('categories_show_checkbox', _selectedTaskTypes.contains(TaskTypeEnum.CHECKBOX));
    await prefs.setBool('categories_show_counter', _selectedTaskTypes.contains(TaskTypeEnum.COUNTER));
    await prefs.setBool('categories_show_timer', _selectedTaskTypes.contains(TaskTypeEnum.TIMER));

    // Save selected category
    if (_selectedCategory != null) {
      await prefs.setInt('categories_selected_category_id', _selectedCategory!.id);
    } else {
      await prefs.remove('categories_selected_category_id');
    }
  }

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
          // Date filter button
          IconButton(
            icon: Icon(
              _getDateFilterIcon(),
              size: 20,
              color: AppColors.text,
            ),
            tooltip: "Date Filter",
            onPressed: _cycleDateFilter,
          ),
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
          // Search bar
          _buildSearchBar(),

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

  // Get the appropriate icon for the current date filter state
  IconData _getDateFilterIcon() {
    switch (_dateFilterState) {
      case DateFilterState.all:
        return Icons.calendar_view_month_rounded;
      case DateFilterState.withDate:
        return Icons.event_rounded;
      case DateFilterState.withoutDate:
        return Icons.event_busy_rounded;
    }
  }

  // Cycle through date filter states
  void _cycleDateFilter() {
    setState(() {
      switch (_dateFilterState) {
        case DateFilterState.all:
          _dateFilterState = DateFilterState.withDate;
          break;
        case DateFilterState.withDate:
          _dateFilterState = DateFilterState.withoutDate;
          break;
        case DateFilterState.withoutDate:
          _dateFilterState = DateFilterState.all;
          break;
      }
      debugPrint('Cycled date filter to: $_dateFilterState');
    });
    _saveFilterPreferences();
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
          _saveFilterPreferences();
        },
        // Add onLongPress to open the edit dialog as a bottom sheet
        onLongPress: category != null
            ? () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
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

    // Apply date filter
    tasks = tasks.where((task) {
      switch (_dateFilterState) {
        case DateFilterState.all:
          return true; // Show all tasks
        case DateFilterState.withDate:
          return task.taskDate != null; // Show only tasks with dates
        case DateFilterState.withoutDate:
          return task.taskDate == null; // Show only tasks without dates
      }
    }).toList();

    // Apply search filter if search query is not empty
    if (_searchQuery.isNotEmpty) {
      tasks = tasks.where((task) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) || (task.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
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
      padding: const EdgeInsets.all(10),
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
    if (date.year == 1970 && date.month == 1 && date.day == 1) {
      dateText = "Inbox"; // Special case for tasks without dates
    } else if (date.isAtSameMomentAs(today)) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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

              // Date filter indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.main.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getDateFilterIcon(),
                      size: 14,
                      color: AppColors.main,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getDateFilterText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.main,
                      ),
                    ),
                  ],
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

  // Get text description for current date filter state
  String _getDateFilterText() {
    switch (_dateFilterState) {
      case DateFilterState.all:
        return "All Tasks";
      case DateFilterState.withDate:
        return "With Date";
      case DateFilterState.withoutDate:
        return "No Date";
    }
  }

  // Arama çubuğunu oluşturan metod
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: "Search tasks...", // TODO: Add to locale keys
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: AppColors.panelBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  // Method to build the category content
  Widget _buildCategoryContent() {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.getActiveCategories();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All tasks option
          _buildCategoryTag(
            null,
            isSelected: _selectedCategory == null,
          ),
          const SizedBox(width: 8),

          // Category tags
          ...categories.map((category) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildCategoryTag(
                  category,
                  isSelected: _selectedCategory?.id == category.id,
                ),
              )),

          // Add category button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const CreateCategoryBottomSheet(),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.text.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
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

                // Date filter section
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "Date Filter",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Row(
                  children: [
                    // All tasks filter
                    _buildFilterChip(
                      label: "All Tasks",
                      icon: Icons.calendar_view_month_rounded,
                      isSelected: _dateFilterState == DateFilterState.all,
                      onTap: () {
                        setState(() {
                          _dateFilterState = DateFilterState.all;
                          debugPrint('Selected date filter: $_dateFilterState');
                        });
                        // Update the parent state and save preferences
                        this.setState(() {});
                        _saveFilterPreferences();
                      },
                    ),
                    const SizedBox(width: 8),

                    // With date filter
                    _buildFilterChip(
                      label: "With Date",
                      icon: Icons.event_rounded,
                      isSelected: _dateFilterState == DateFilterState.withDate,
                      onTap: () {
                        setState(() {
                          _dateFilterState = DateFilterState.withDate;
                          debugPrint('Selected date filter: $_dateFilterState');
                        });
                        // Update the parent state and save preferences
                        this.setState(() {});
                        _saveFilterPreferences();
                      },
                    ),
                    const SizedBox(width: 8),

                    // Without date filter
                    _buildFilterChip(
                      label: "No Date",
                      icon: Icons.event_busy_rounded,
                      isSelected: _dateFilterState == DateFilterState.withoutDate,
                      onTap: () {
                        setState(() {
                          _dateFilterState = DateFilterState.withoutDate;
                          debugPrint('Selected date filter: $_dateFilterState');
                        });
                        // Update the parent state and save preferences
                        this.setState(() {});
                        _saveFilterPreferences();
                      },
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
                        // Update the parent state and save preferences
                        this.setState(() {});
                        _saveFilterPreferences();
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
                        // Update the parent state and save preferences
                        this.setState(() {});
                        _saveFilterPreferences();
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
                        // Update the parent state and save preferences
                        this.setState(() {});
                        _saveFilterPreferences();
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
                        // Update the parent state and save preferences
                        this.setState(() {});
                        _saveFilterPreferences();
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
                        // Update the parent state and save preferences
                        this.setState(() {});
                        _saveFilterPreferences();
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
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.main : AppColors.text.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
