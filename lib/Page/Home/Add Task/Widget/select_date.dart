import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class SelectDate extends StatefulWidget {
  const SelectDate({
    super.key,
  });

  @override
  State<SelectDate> createState() => _SelectDateState();
}

class _SelectDateState extends State<SelectDate> {
  late final addTaskProvider = context.read<AddTaskProvider>();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
      ),
      child: TableCalendar(
        rowHeight: 30,
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: addTaskProvider.selectedDate,
        selectedDayPredicate: (day) => isSameDay(addTaskProvider.selectedDate, day),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 14),
          leftChevronIcon: Icon(Icons.chevron_left, size: 20),
          rightChevronIcon: Icon(Icons.chevron_right, size: 20),
          headerPadding: EdgeInsets.all(0),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: 12, color: AppColors.text.withAlpha(100)),
          weekendStyle: TextStyle(fontSize: 12, color: AppColors.text.withAlpha(100)),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: AppColors.main,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.main.withAlpha(50),
            shape: BoxShape.circle,
          ),
          defaultTextStyle: TextStyle(fontSize: 12, color: AppColors.text),
          weekendTextStyle: TextStyle(fontSize: 12, color: AppColors.text),
          selectedTextStyle: TextStyle(fontSize: 12, color: AppColors.text),
          todayTextStyle: TextStyle(fontSize: 12, color: AppColors.text),
          outsideTextStyle: TextStyle(fontSize: 12, color: AppColors.text.withAlpha(100)),
          cellMargin: const EdgeInsets.all(1),
          cellPadding: EdgeInsets.zero,
          rowDecoration: const BoxDecoration(
            color: AppColors.transparent,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          // Unfocus any text fields when selecting a date
          addTaskProvider.unfocusAll();
          setState(() {
            addTaskProvider.selectedDate = selectedDay;
          });
        },
      ),
    );
  }
}
