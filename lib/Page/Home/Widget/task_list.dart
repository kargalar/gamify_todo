import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Widget/task_item.dart';
import 'package:next_level/Page/Home/Widget/overdue_tasks_header.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:provider/provider.dart';

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

        // Get tasks for this date
        final selectedDateTaskList = vm.getTasksForDate(pageDate);
        final selectedDateRutinTaskList = vm.getRoutineTasksForDate(pageDate);
        final selectedDateGhostRutinTaskList = vm.getGhostRoutineTasksForDate(pageDate); // Build the content for this page
        return _buildPageContent(
          pageDate,
          selectedDateTaskList,
          selectedDateRutinTaskList,
          selectedDateGhostRutinTaskList,
        );
      },
    );
  }

  Widget _buildPageContent(
    DateTime pageDate,
    List<dynamic> selectedDateTaskList,
    List<dynamic> selectedDateRutinTaskList,
    List<dynamic> selectedDateGhostRutinTaskList,
  ) {
    final vm = context.read<HomeViewModel>();
    final isToday = vm.isToday(pageDate);
    // Get overdue tasks only for today's view
    final List<TaskModel> overdueTasks = isToday ? vm.getOverdueTasks() : <TaskModel>[];

    // Check if there are any tasks to display
    final hasAnyTasks = selectedDateTaskList.isNotEmpty || selectedDateGhostRutinTaskList.isNotEmpty || selectedDateRutinTaskList.isNotEmpty || overdueTasks.isNotEmpty;
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
                // Overdue tasks section (only on today's view) - minimalist spacing
                if (isToday && overdueTasks.isNotEmpty) ...[
                  OverdueTasksHeader(overdueTasks: overdueTasks),
                ],
                // Normal tasks
                if (selectedDateTaskList.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selectedDateTaskList.length,
                    padding: const EdgeInsets.all(0),
                    itemBuilder: (context, index) {
                      return TaskItem(taskModel: selectedDateTaskList[index]);
                    },
                  ),

                // Routine Tasks
                if (selectedDateRutinTaskList.isNotEmpty) ...[
                  if (selectedDateTaskList.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.text.withAlpha(100),
                    ),
                    const SizedBox(height: 2),
                  ],
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selectedDateRutinTaskList.length,
                    padding: const EdgeInsets.all(0),
                    itemBuilder: (context, index) {
                      return TaskItem(
                        taskModel: selectedDateRutinTaskList[index],
                        isRoutine: true,
                      );
                    },
                  ),
                ],

                // Future routines ghosts
                if (selectedDateGhostRutinTaskList.isNotEmpty) ...[
                  if (selectedDateTaskList.isNotEmpty || selectedDateRutinTaskList.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 15),
                  ],
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selectedDateGhostRutinTaskList.length,
                    padding: const EdgeInsets.all(0),
                    itemBuilder: (context, index) {
                      return TaskItem(
                        taskModel: selectedDateGhostRutinTaskList[index],
                        isRoutine: true,
                      );
                    },
                  ),
                ],

                // navbar space
                const SizedBox(height: 100),
              ],
            ),
          );
  }
}
