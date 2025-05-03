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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: AppColors.main,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Date",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Selected date display
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.main.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.main.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_rounded,
                  color: AppColors.main,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(addTaskProvider.selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.main,
                  ),
                ),
              ],
            ),
          ),

          // Calendar
          Container(
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.text.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: TableCalendar(
              rowHeight: 36,
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: addTaskProvider.selectedDate,
              selectedDayPredicate: (day) => isSameDay(addTaskProvider.selectedDate, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.main,
                ),
                leftChevronIcon: Icon(Icons.chevron_left_rounded, size: 24, color: AppColors.main),
                rightChevronIcon: Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.main),
                headerPadding: const EdgeInsets.symmetric(vertical: 8),
                headerMargin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.main.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
                weekendStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: AppColors.main,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.main.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: TextStyle(fontSize: 14, color: AppColors.text),
                weekendTextStyle: TextStyle(fontSize: 14, color: AppColors.text),
                selectedTextStyle: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                todayTextStyle: TextStyle(fontSize: 14, color: AppColors.main, fontWeight: FontWeight.bold),
                outsideTextStyle: TextStyle(fontSize: 14, color: AppColors.text.withValues(alpha: 0.4)),
                cellMargin: const EdgeInsets.all(2),
                cellPadding: EdgeInsets.zero,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                // Unfocus any text fields when selecting a date
                addTaskProvider.unfocusAll();
                setState(() {
                  addTaskProvider.selectedDate = selectedDay;
                });
              },
            ),
          ),

          // Date info
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.text.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Select the date when this task should be completed",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate == today) {
      return "Today";
    } else if (selectedDate == tomorrow) {
      return "Tomorrow";
    } else if (selectedDate == yesterday) {
      return "Yesterday";
    } else {
      // Format as "Mon, Jan 1, 2023"
      return "${_getDayOfWeek(date.weekday)}, ${_getMonth(date.month)} ${date.day}, ${date.year}";
    }
  }

  String _getDayOfWeek(int day) {
    switch (day) {
      case 1:
        return "Mon";
      case 2:
        return "Tue";
      case 3:
        return "Wed";
      case 4:
        return "Thu";
      case 5:
        return "Fri";
      case 6:
        return "Sat";
      case 7:
        return "Sun";
      default:
        return "";
    }
  }

  String _getMonth(int month) {
    switch (month) {
      case 1:
        return "Jan";
      case 2:
        return "Feb";
      case 3:
        return "Mar";
      case 4:
        return "Apr";
      case 5:
        return "May";
      case 6:
        return "Jun";
      case 7:
        return "Jul";
      case 8:
        return "Aug";
      case 9:
        return "Sep";
      case 10:
        return "Oct";
      case 11:
        return "Nov";
      case 12:
        return "Dec";
      default:
        return "";
    }
  }
}
