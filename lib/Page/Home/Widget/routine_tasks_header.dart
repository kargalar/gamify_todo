import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/task_item.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class RoutineTasksHeader extends StatefulWidget {
  final List<dynamic> routineTasks;
  final List<dynamic> ghostRoutineTasks;

  const RoutineTasksHeader({
    super.key,
    required this.routineTasks,
    required this.ghostRoutineTasks,
  });

  @override
  State<RoutineTasksHeader> createState() => _RoutineTasksHeaderState();
}

class _RoutineTasksHeaderState extends State<RoutineTasksHeader> with SingleTickerProviderStateMixin {
  bool _isExpanded = true; // Default to expanded
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  static const String _prefsKey = 'routine_tasks_expanded';

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
    final totalCount = widget.routineTasks.length + widget.ghostRoutineTasks.length;

    if (totalCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.01), // Light purple background for routine tasks
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
                  // Routine icon
                  Icon(
                    Icons.repeat_rounded,
                    size: 16,
                    color: AppColors.blue.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),

                  // Title
                  Text(
                    LocaleKeys.Routines.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
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
                      '$totalCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue,
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
                      color: AppColors.blue.withValues(alpha: 0.5),
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
                // Ghost routine tasks
                if (widget.ghostRoutineTasks.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.ghostRoutineTasks.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      return TaskItem(
                        taskModel: widget.ghostRoutineTasks[index],
                        isRoutine: true,
                      );
                    },
                  ),

                // Regular routine tasks
                if (widget.routineTasks.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.routineTasks.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      return TaskItem(
                        taskModel: widget.routineTasks[index],
                        isRoutine: true,
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
