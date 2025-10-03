import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Widget/task_item.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class PinnedTasksHeader extends StatefulWidget {
  final List<TaskModel> pinnedTasks;

  const PinnedTasksHeader({
    super.key,
    required this.pinnedTasks,
  });

  @override
  State<PinnedTasksHeader> createState() => _PinnedTasksHeaderState();
}

class _PinnedTasksHeaderState extends State<PinnedTasksHeader> with SingleTickerProviderStateMixin {
  bool _isExpanded = true; // Default to expanded
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  static const String _prefsKey = 'pinned_tasks_expanded';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadExpandedState();
  }

  Future<void> _loadExpandedState() async {
    final prefs = await SharedPreferences.getInstance();
    final isExpanded = prefs.getBool(_prefsKey) ?? true; // Default to expanded

    if (mounted) {
      setState(() {
        _isExpanded = isExpanded;
      });

      if (_isExpanded) {
        // Set animation to completed state immediately without animation
        _animationController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleExpanded() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });

    // Save state to SharedPreferences
    await prefs.setBool(_prefsKey, _isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pinnedTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.main.withValues(alpha: 0.06), // Light purple/main color background
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count and expand/collapse button - Minimalist design
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Pin icon indicator
                  Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: AppColors.main,
                  ),
                  const SizedBox(width: 8),

                  // Title
                  Text(
                    LocaleKeys.PinnedTasks.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.main,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.main.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.pinnedTasks.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.main,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Expand/collapse icon
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.main.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable task list
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: Column(
              children: [
                _buildGroupedTaskList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedTaskList() {
    // Group tasks by date
    final Map<String, List<TaskModel>> groupedTasks = {};

    for (final task in widget.pinnedTasks) {
      String dateKey;
      if (task.taskDate == null) {
        dateKey = 'no_date';
      } else {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dateOnly = DateTime(task.taskDate!.year, task.taskDate!.month, task.taskDate!.day);

        if (dateOnly.isAtSameMomentAs(today)) {
          dateKey = 'today';
        } else if (dateOnly.isBefore(today)) {
          dateKey = 'past_${DateFormat('yyyy-MM-dd').format(task.taskDate!)}';
        } else {
          dateKey = 'future_${DateFormat('yyyy-MM-dd').format(task.taskDate!)}';
        }
      }

      if (!groupedTasks.containsKey(dateKey)) {
        groupedTasks[dateKey] = [];
      }
      groupedTasks[dateKey]!.add(task);
    }

    // Sort groups: no_date -> today -> past (newest first) -> future (oldest first)
    final sortedKeys = groupedTasks.keys.toList()
      ..sort((a, b) {
        if (a == 'no_date') return -1;
        if (b == 'no_date') return 1;
        if (a == 'today') return -1;
        if (b == 'today') return 1;
        if (a.startsWith('past_') && b.startsWith('past_')) {
          return b.compareTo(a); // Newer dates first for past
        }
        if (a.startsWith('past_')) return -1;
        if (b.startsWith('past_')) return 1;
        return a.compareTo(b); // Older dates first for future
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final dateKey in sortedKeys) ...[
          _buildDateHeader(dateKey, groupedTasks[dateKey]!.first),
          ...groupedTasks[dateKey]!.map((task) => TaskItem(taskModel: task)),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDateHeader(String dateKey, TaskModel sampleTask) {
    Color dateColor;
    String dateText;
    IconData icon;

    if (dateKey == 'no_date') {
      dateColor = Colors.grey;
      dateText = LocaleKeys.NoDate.tr();
      icon = Icons.event_busy;
    } else if (dateKey == 'today') {
      dateColor = Colors.green;
      dateText = LocaleKeys.Today.tr();
      icon = Icons.calendar_today;
    } else if (dateKey.startsWith('past_')) {
      dateColor = Colors.red;
      dateText = DateFormat('dd MMM yyyy').format(sampleTask.taskDate!);
      icon = Icons.calendar_today;
    } else {
      // Future
      dateColor = Colors.blue;
      dateText = DateFormat('dd MMM yyyy').format(sampleTask.taskDate!);
      icon = Icons.calendar_today;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 13,
            color: dateColor,
          ),
          const SizedBox(width: 6),
          Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: dateColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
