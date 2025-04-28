// hanig gün olduğunu gösterecek tıkalyınca selected date o tarih oalcak. listede şimdiki günün 1 gün öncesi, şimdiki gün, sonraki gün ve ondan sonraki gün oalcak.
import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
        // Provider üzerinden erişim sağlayarak tarihi değiştir
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        taskProvider.changeSelectedDate(widget.date);
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: context.watch<TaskProvider>().selectedDate.isSameDay(widget.date) ? AppColors.main : AppColors.transparent,
          borderRadius: AppColors.borderRadiusAll,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('EEE', locale.languageCode).format(widget.date),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
            Text(
              widget.date.day.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
