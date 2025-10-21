import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';

/// Compact pin task switch widget - only shown in edit mode for non-routine tasks
class PinTaskSwitch extends StatelessWidget {
  const PinTaskSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddTaskProvider>();

    // Only show for edit mode and non-routine tasks
    if (provider.editTask!.routineID != null && provider.editTask == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        // Icon
        Icon(
          Icons.push_pin_rounded,
          color: provider.isPinned ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
          size: 20,
        ),
        // Compact Switch
        Transform.scale(
          scale: 0.9,
          child: Switch(
            value: provider.isPinned,
            onChanged: (value) {
              context.read<AddTaskProvider>().updateIsPinned(value);
            },
            activeColor: AppColors.main,
          ),
        ),
      ],
    );
  }
}
