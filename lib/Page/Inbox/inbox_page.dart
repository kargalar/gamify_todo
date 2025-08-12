import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Page/Home/Widget/create_category_bottom_sheet.dart';
import 'package:next_level/Page/Inbox/Widget/inbox_search_bar.dart';
import 'package:next_level/Page/Inbox/Widget/inbox_categories_section.dart';
import 'package:next_level/Page/Inbox/Widget/inbox_filter_dialog.dart';
import 'package:next_level/Page/Inbox/Widget/inbox_task_list.dart';
import 'package:next_level/Page/Inbox/Widget/date_filter_state.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  CategoryModel? _selectedCategory;
  int? _selectedCategoryId;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  // Filter states
  bool _showRoutines = true;
  bool _showTasks = true;
  DateFilterState _dateFilterState = DateFilterState.withoutDate;
  final Set<TaskTypeEnum> _selectedTaskTypes = {
    TaskTypeEnum.CHECKBOX,
    TaskTypeEnum.COUNTER,
    TaskTypeEnum.TIMER,
  };
  final Set<TaskStatusEnum> _selectedStatuses = {};
  bool _showEmptyStatus = true; // Show tasks with null status by default

  @override
  void initState() {
    super.initState();
    _loadFilterPreferences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      } // Load status filter preferences
      final hasCompleted = prefs.getBool('categories_show_completed') ?? true;
      final hasFailed = prefs.getBool('categories_show_failed') ?? true;
      final hasCancel = prefs.getBool('categories_show_cancel') ?? true;
      final hasArchived = prefs.getBool('categories_show_archived') ?? false;
      final hasOverdue = prefs.getBool('categories_show_overdue') ?? true;
      _showEmptyStatus = prefs.getBool('categories_show_empty_status') ?? true;

      // Clear and rebuild the status set based on saved preferences
      _selectedStatuses.clear();
      if (hasCompleted) _selectedStatuses.add(TaskStatusEnum.DONE);
      if (hasFailed) _selectedStatuses.add(TaskStatusEnum.FAILED);
      if (hasCancel) _selectedStatuses.add(TaskStatusEnum.CANCEL);
      if (hasArchived) _selectedStatuses.add(TaskStatusEnum.ARCHIVED);
      if (hasOverdue) _selectedStatuses.add(TaskStatusEnum.OVERDUE);

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

    // Save status filter preferences
    await prefs.setBool('categories_show_completed', _selectedStatuses.contains(TaskStatusEnum.DONE));
    await prefs.setBool('categories_show_failed', _selectedStatuses.contains(TaskStatusEnum.FAILED));
    await prefs.setBool('categories_show_cancel', _selectedStatuses.contains(TaskStatusEnum.CANCEL));
    await prefs.setBool('categories_show_archived', _selectedStatuses.contains(TaskStatusEnum.ARCHIVED));
    await prefs.setBool('categories_show_overdue', _selectedStatuses.contains(TaskStatusEnum.OVERDUE));
    await prefs.setBool('categories_show_empty_status', _showEmptyStatus);

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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          LocaleKeys.Tasks.tr(),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.search,
            size: 20,
            color: _isSearchActive ? AppColors.main : AppColors.text,
          ),
          tooltip: LocaleKeys.Search.tr(),
          onPressed: () {
            setState(() {
              _isSearchActive = !_isSearchActive;
              if (!_isSearchActive) {
                _searchController.clear();
              }
            });
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_rounded,
              size: 20,
              color: AppColors.text,
            ),
            tooltip: LocaleKeys.AddCategory.tr(),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.transparent,
                builder: (context) => const CreateCategoryBottomSheet(),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              size: 20,
              color: AppColors.text,
            ),
            tooltip: LocaleKeys.Filters.tr(),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchActive)
            InboxSearchBar(
              controller: _searchController,
              onChanged: () => setState(() {}),
            ),
          if (context.read<CategoryProvider>().getActiveCategories().isNotEmpty)
            InboxCategoriesSection(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
                _saveFilterPreferences();
              },
              searchQuery: _searchController.text,
              showRoutines: _showRoutines,
              showTasks: _showTasks,
              dateFilterState: _dateFilterState,
              selectedTaskTypes: _selectedTaskTypes,
              selectedStatuses: _selectedStatuses,
              showEmptyStatus: _showEmptyStatus,
            ),
          Divider(
            color: AppColors.text.withValues(alpha: 0.1),
            height: 1,
            thickness: 1,
          ),
          Expanded(
            child: InboxTaskList(
              selectedCategory: _selectedCategory,
              searchQuery: _searchController.text,
              showRoutines: _showRoutines,
              showTasks: _showTasks,
              dateFilterState: _dateFilterState,
              selectedTaskTypes: _selectedTaskTypes,
              selectedStatuses: _selectedStatuses,
              showEmptyStatus: _showEmptyStatus,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => InboxFilterDialog(
        showRoutines: _showRoutines,
        showTasks: _showTasks,
        dateFilterState: _dateFilterState,
        selectedTaskTypes: _selectedTaskTypes,
        selectedStatuses: _selectedStatuses,
        showEmptyStatus: _showEmptyStatus,
        onFiltersChanged: (showRoutines, showTasks, dateFilterState, taskTypes, statuses, showEmpty) {
          setState(() {
            _showRoutines = showRoutines;
            _showTasks = showTasks;
            _dateFilterState = dateFilterState;
            _selectedTaskTypes.clear();
            _selectedTaskTypes.addAll(taskTypes);
            _selectedStatuses.clear();
            _selectedStatuses.addAll(statuses);
            _showEmptyStatus = showEmpty;
          });
          _saveFilterPreferences();
        },
      ),
    );
  }
}
