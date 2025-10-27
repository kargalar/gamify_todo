import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Widget/task_item.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class OverdueTasksHeader extends StatefulWidget {
  final List<TaskModel> overdueTasks;

  const OverdueTasksHeader({
    super.key,
    required this.overdueTasks,
  });

  @override
  State<OverdueTasksHeader> createState() => _OverdueTasksHeaderState();
}

class _OverdueTasksHeaderState extends State<OverdueTasksHeader> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  static const String _prefsKey = 'overdue_tasks_expanded';

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
    final isExpanded = prefs.getBool(_prefsKey) ?? false;

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
    if (widget.overdueTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.01), // Light orange background - matching pinned style
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count and expand/collapse button - Minimalist design matching pinned
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Icon indicator - matching pinned style
                  const Icon(
                    Icons.warning_rounded,
                    size: 16,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 8),

                  // Title - matching pinned style
                  Text(
                    LocaleKeys.OverdueTasks.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Count badge - matching pinned style
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.overdueTasks.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Expand/collapse icon - matching pinned style
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.orange.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ), // Expandable content - simplified
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                // Overdue tasks list with reordering support
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.overdueTasks.length,
                  padding: EdgeInsets.zero,
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (BuildContext context, Widget? child) {
                        final double animValue = Curves.easeInOut.transform(animation.value);
                        final double elevation = lerpDouble(0, 6, animValue)!;
                        final double scale = lerpDouble(1.0, 1.02, animValue)!;
                        return Transform.scale(
                          scale: scale,
                          child: Material(
                            elevation: elevation,
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: child,
                          ),
                        );
                      },
                      child: child,
                    );
                  },
                  onReorder: (int oldIndex, int newIndex) {
                    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                    taskProvider.reorderTasks(
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                      isPinnedList: false,
                      isRoutineList: false,
                      isOverdueList: true,
                    );
                  },
                  itemBuilder: (context, index) {
                    final task = widget.overdueTasks[index];
                    return ReorderableDragStartListener(
                      key: ValueKey(task.key),
                      index: index,
                      child: TaskItem(taskModel: task),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
