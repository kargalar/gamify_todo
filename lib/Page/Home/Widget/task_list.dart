import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Widget/overdue_tasks_header.dart';
import 'package:next_level/Page/Home/Widget/pinned_tasks_header.dart';
import 'package:next_level/Page/Home/Widget/normal_tasks_header.dart';
import 'package:next_level/Page/Home/Widget/routine_tasks_header.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Widgets/Common/category_filter_widget.dart';

class TaskList extends StatefulWidget {
  const TaskList({super.key});

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  // Controller for handling swipe gestures
  late PageController _pageController;
  // Reference page number
  final int _referencePage = 1000;
  // Store the last known selected date to detect changes
  DateTime? _lastSelectedDate;
  // Store the base date for calculations
  late DateTime _baseDate; // Flag to track if we're handling a programmatic page change
  bool _isHandlingPageChange = false;

  @override
  void initState() {
    super.initState();
    // Initialize base date to today
    _baseDate = DateTime.now();
    // Start with a large initial page to allow swiping in both directions
    _pageController = PageController(initialPage: _referencePage);

    // Listen for changes to the TaskProvider's selectedDate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<HomeViewModel>(context, listen: false);
      _lastSelectedDate = vm.selectedDate;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Calculate the difference in days between two dates
  int _daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  // Jump to a specific date
  void _jumpToDate(DateTime targetDate) {
    if (_isHandlingPageChange) return;

    _isHandlingPageChange = true;

    // Calculate how many days to move from the base date
    final int dayDiff = _daysBetween(_baseDate, targetDate);
    final int targetPage = _referencePage + dayDiff;

    // Animate to the calculated page with a smooth animation
    if (_pageController.hasClients) {
      _pageController
          .animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        _isHandlingPageChange = false;
      });
    } else {
      _isHandlingPageChange = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    context.watch<AddTaskProvider>();

    // Check if the selected date has changed from outside (e.g., from AppBar)
    if (_lastSelectedDate != null && !_lastSelectedDate!.isSameDay(vm.selectedDate) && !_isHandlingPageChange) {
      // Jump to the new date
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpToDate(vm.selectedDate);
      });
    }

    // Update the last known selected date
    _lastSelectedDate = vm.selectedDate;

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      pageSnapping: true,
      padEnds: true,
      onPageChanged: (index) {
        if (_isHandlingPageChange) return;

        // Delegate to ViewModel
        vm.onPageChanged(pageIndex: index, baseDate: _baseDate, referencePage: _referencePage);
      },
      itemBuilder: (context, index) {
        // Calculate the date for this page via ViewModel helper
        final DateTime pageDate = vm.dateForPage(baseDate: _baseDate, pageIndex: index, referencePage: _referencePage);

        // If showing archived, show archived tasks and routines
        if (vm.showArchived) {
          final archivedTasks = vm.getArchivedTasks();
          final archivedRoutines = vm.getArchivedRoutines();

          return _buildArchivedContent(archivedTasks, archivedRoutines);
        }

        // Get tasks for this date
        final selectedDateTaskList = vm.getTasksForDate(pageDate);
        final selectedDateRutinTaskList = vm.getRoutineTasksForDate(pageDate);
        final selectedDateGhostRutinTaskList = vm.getGhostRoutineTasksForDate(pageDate);

        // Get pinned tasks only for today
        final isToday = vm.isToday(pageDate);
        final pinnedTasks = isToday ? vm.getPinnedTasksForToday() : <TaskModel>[];

        // Build the content for this page
        return _buildPageContent(
          pageDate,
          selectedDateTaskList,
          selectedDateRutinTaskList,
          selectedDateGhostRutinTaskList,
          pinnedTasks,
        );
      },
    );
  }

  Widget _buildPageContent(
    DateTime pageDate,
    List<dynamic> selectedDateTaskList,
    List<dynamic> selectedDateRutinTaskList,
    List<dynamic> selectedDateGhostRutinTaskList,
    List<TaskModel> pinnedTasks,
  ) {
    final vm = context.read<HomeViewModel>();
    final isToday = vm.isToday(pageDate);
    // Get overdue tasks only for today's view
    final List<TaskModel> overdueTasks = isToday ? vm.getOverdueTasks() : <TaskModel>[];

    // Check if there are any tasks to display
    final hasAnyTasks = selectedDateTaskList.isNotEmpty || selectedDateGhostRutinTaskList.isNotEmpty || selectedDateRutinTaskList.isNotEmpty || overdueTasks.isNotEmpty || pinnedTasks.isNotEmpty;
    return !hasAnyTasks
        ? Center(
            child: Text(
              LocaleKeys.NoTaskForToday.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                // Category filter
                CategoryFilterWidget(
                  categories: vm.taskCategories,
                  selectedCategoryId: vm.selectedCategoryId,
                  onCategorySelected: (categoryId) => vm.setSelectedCategory(categoryId as int?),
                ),

                // Overdue tasks section (only on today's view) - minimalist spacing
                if (isToday && overdueTasks.isNotEmpty) ...[
                  OverdueTasksHeader(overdueTasks: overdueTasks),
                ],

                // Pinned tasks section (only on today's view) - collapsible like overdue
                if (isToday && pinnedTasks.isNotEmpty) ...[
                  PinnedTasksHeader(pinnedTasks: pinnedTasks),
                ],

                // Normal tasks - now collapsible
                if (selectedDateTaskList.isNotEmpty) ...[
                  NormalTasksHeader(tasks: selectedDateTaskList),
                ],

                // Routine Tasks - now collapsible (includes both regular and ghost routines)
                if (selectedDateRutinTaskList.isNotEmpty || selectedDateGhostRutinTaskList.isNotEmpty) ...[
                  RoutineTasksHeader(
                    routineTasks: selectedDateRutinTaskList,
                    ghostRoutineTasks: selectedDateGhostRutinTaskList,
                  ),
                ],

                // navbar space
                const SizedBox(height: 100),
              ],
            ),
          );
  }

  Widget _buildArchivedContent(List<TaskModel> archivedTasks, List<dynamic> archivedRoutines) {
    final hasAnyArchivedItems = archivedTasks.isNotEmpty || archivedRoutines.isNotEmpty;

    return !hasAnyArchivedItems
        ? Center(
            child: Text(
              LocaleKeys.NoArchivedTasksOrRoutines.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                // Archived routines section - routines first since they are recurring
                if (archivedRoutines.isNotEmpty) ...[
                  RoutineTasksHeader(
                    routineTasks: archivedRoutines,
                    ghostRoutineTasks: const [],
                  ),
                ],

                // Archived tasks section
                if (archivedTasks.isNotEmpty) ...[
                  NormalTasksHeader(tasks: archivedTasks),
                ],

                // navbar space
                const SizedBox(height: 100),
              ],
            ),
          );
  }
}
