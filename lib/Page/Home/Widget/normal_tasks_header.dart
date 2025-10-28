import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/task_item.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class NormalTasksHeader extends StatefulWidget {
  final List<dynamic> tasks;

  const NormalTasksHeader({
    super.key,
    required this.tasks,
  });

  @override
  State<NormalTasksHeader> createState() => _NormalTasksHeaderState();
}

class _NormalTasksHeaderState extends State<NormalTasksHeader> with SingleTickerProviderStateMixin {
  bool _isExpanded = true; // Default to expanded
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  static const String _prefsKey = 'normal_tasks_expanded';

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
    if (widget.tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.01), // Light green background for normal tasks
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count and expand/collapse button
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Task icon
                  Icon(
                    Icons.task_alt,
                    size: 16,
                    color: AppColors.deepGreen.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),

                  // Title
                  Text(
                    LocaleKeys.Tasks.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepGreen,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.deepGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.tasks.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepGreen,
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
                      color: AppColors.deepGreen.withValues(alpha: 0.5),
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
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.tasks.length,
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
                  isOverdueList: false,
                );
              },
              itemBuilder: (context, index) {
                final task = widget.tasks[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(task.key),
                  index: index,
                  child: TaskItem(taskModel: task),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
