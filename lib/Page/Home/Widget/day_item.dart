// hanig gün olduğunu gösterecek tıkalyınca selected date o tarih oalcak. listede şimdiki günün 1 gün öncesi, şimdiki gün, sonraki gün ve ondan sonraki gün oalcak.
import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:intl/intl.dart';

class DayItem extends StatefulWidget {
  const DayItem({
    super.key,
    required this.date,
  });

  final DateTime date;

  @override
  State<DayItem> createState() => _DayItemState();
}

class _DayItemState extends State<DayItem> {
  late Locale locale = Localizations.localeOf(context);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppColors.borderRadiusAll,
      onTap: () {
        TaskProvider().changeSelectedDate(widget.date);
      },
      child: Container(
        width: 50,
        height: 50,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: TaskProvider().selectedDate.isSameDay(widget.date) ? AppColors.main : AppColors.transparent,
          borderRadius: AppColors.borderRadiusAll,
        ),
        child: Column(
          children: [
            Text(DateFormat('EEE', locale.languageCode).format(widget.date)),
            Text(widget.date.day.toString()),
          ],
        ),
      ),
    );
  }
}
