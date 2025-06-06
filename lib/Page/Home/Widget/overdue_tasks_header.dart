import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Widget/task_item.dart';
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.overdueTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
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
                // Small dot indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),

                // Count text - simplified
                Expanded(
                  child: Text(
                    widget.overdueTasks.length == 1 ? LocaleKeys.OverdueTaskCount.tr(namedArgs: {'count': widget.overdueTasks.length.toString()}) : LocaleKeys.OverdueTaskCountPlural.tr(namedArgs: {'count': widget.overdueTasks.length.toString()}),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.orange.withValues(alpha: 0.9),
                    ),
                  ),
                ),

                // Simple expand/collapse icon
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
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
              const SizedBox(height: 8),
              // Overdue tasks list with minimal spacing
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.overdueTasks.length,
                padding: const EdgeInsets.all(0),
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  return TaskItem(taskModel: widget.overdueTasks[index]);
                },
              ),

              // Simple divider
              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.orange.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
