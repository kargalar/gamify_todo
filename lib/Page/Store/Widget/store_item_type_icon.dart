import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Enum/task_type_enum.dart';

/// Glassmorphic icon badge representing the store item's type.
class StoreItemTypeIcon extends StatelessWidget {
  final TaskTypeEnum type;
  final bool isTimerActive;

  const StoreItemTypeIcon({
    super.key,
    required this.type,
    this.isTimerActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final IconData iconData;
    switch (type) {
      case TaskTypeEnum.TIMER:
        iconData = isTimerActive ? Icons.pause_rounded : Icons.play_arrow_rounded;
      case TaskTypeEnum.COUNTER:
        iconData = Icons.add_rounded;
      case TaskTypeEnum.CHECKBOX:
        iconData = Icons.check_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.main.withValues(alpha: 0.25),
            AppColors.main.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.main.withValues(alpha: 0.3),
        ),
      ),
      child: Icon(
        iconData,
        size: 22,
        color: isTimerActive ? AppColors.main : AppColors.text.withValues(alpha: 0.8),
      ),
    );
  }
}
