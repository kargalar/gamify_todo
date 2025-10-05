import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';

/// Compact pin task switch widget - only shown in edit mode for non-routine tasks
class PinTaskSwitch extends StatelessWidget {
  const PinTaskSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddTaskProvider>();

    // Only show for edit mode and non-routine tasks
    if (provider.editTask == null || provider.editTask!.routineID != null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Icon
          Icon(
            Icons.push_pin_rounded,
            color: provider.isPinned ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
            size: 20,
          ),
          const SizedBox(width: 10),

          // Label - simplified without tooltip
          Expanded(
            child: Text(
              LocaleKeys.PinTask.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: provider.isPinned ? AppColors.main : AppColors.text,
              ),
            ),
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
      ),
    );
  }
}
