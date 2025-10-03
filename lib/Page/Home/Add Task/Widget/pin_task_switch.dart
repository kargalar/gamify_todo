import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';

/// Pin task switch widget - only shown in edit mode for non-routine tasks
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon
          Icon(
            Icons.push_pin_rounded,
            color: provider.isPinned ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
            size: 22,
          ),
          const SizedBox(width: 12),

          // Label with tooltip
          Expanded(
            child: ClickableTooltip(
              title: LocaleKeys.PinTask.tr(),
              bulletPoints: [LocaleKeys.PinTaskTooltip.tr(), "Only non-routine tasks can be pinned", "Pinned tasks appear at the top on today's view"],
              child: Text(
                LocaleKeys.PinTask.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: provider.isPinned ? AppColors.main : AppColors.text,
                ),
              ),
            ),
          ),

          // Switch
          Switch(
            value: provider.isPinned,
            onChanged: (value) {
              context.read<AddTaskProvider>().updateIsPinned(value);
            },
            activeColor: AppColors.main,
          ),
        ],
      ),
    );
  }
}
