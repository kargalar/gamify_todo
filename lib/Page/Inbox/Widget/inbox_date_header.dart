import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class InboxDateHeader extends StatelessWidget {
  final DateTime date;

  const InboxDateHeader({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    String dateText;
    if (date.year == 1970 && date.month == 1 && date.day == 1) {
      dateText = "Inbox"; // Special case for tasks without dates
    } else if (date.isAtSameMomentAs(today)) {
      dateText = LocaleKeys.Today.tr();
    } else if (date.isAtSameMomentAs(tomorrow)) {
      dateText = LocaleKeys.Tomorrow.tr();
    } else if (date.isAtSameMomentAs(yesterday)) {
      dateText = LocaleKeys.Yesterday.tr();
    } else {
      dateText = "${date.day}/${date.month}/${date.year}";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        dateText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.text.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
