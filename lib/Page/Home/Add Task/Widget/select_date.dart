import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Widgets/clickable_tooltip.dart';
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
    // Listen to changes in selectedDays to rebuild the widget
    context.watch<AddTaskProvider>();

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
          ClickableTooltip(
            title: "Date",
            bulletPoints: const ["Select a date for your task", "Tasks without dates go to inbox", "Routines require a start date", "Use today/tomorrow buttons for quick selection"],
            child: Row(
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
                const Spacer(),
                // Clear date button - only show if no repeat days are selected
                if (addTaskProvider.selectedDate != null && addTaskProvider.selectedDays.isEmpty)
                  InkWell(
                    onTap: () {
                      setState(() {
                        addTaskProvider.selectedDate = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        color: AppColors.text.withValues(alpha: 0.5),
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Quick date buttons and Calendar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar (reduced width)
              Expanded(
                flex: 3,
                child: Container(
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
                    focusedDay: addTaskProvider.selectedDate ?? DateTime.now(),
                    selectedDayPredicate: (day) => addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, day),
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
                        color: addTaskProvider.selectedDate == null ? Colors.transparent : AppColors.main,
                        shape: BoxShape.circle,
                        border: addTaskProvider.selectedDate == null ? Border.all(color: AppColors.main, width: 1) : null,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.main.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: TextStyle(fontSize: 14, color: AppColors.text),
                      weekendTextStyle: TextStyle(fontSize: 14, color: AppColors.text),
                      selectedTextStyle: TextStyle(fontSize: 14, color: addTaskProvider.selectedDate == null ? AppColors.main : Colors.white, fontWeight: FontWeight.bold),
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
              ),

              // Quick date buttons column
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // Today button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            addTaskProvider.selectedDate = DateTime.now();
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day
                                ? AppColors.main.withValues(alpha: 0.15)
                                : addTaskProvider.selectedDate == null
                                    ? AppColors.blue.withValues(alpha: 0.1)
                                    : AppColors.panelBackground.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day
                                  ? AppColors.main
                                  : addTaskProvider.selectedDate == null
                                      ? AppColors.blue
                                      : AppColors.text.withValues(alpha: 0.1),
                              width: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day || addTaskProvider.selectedDate == null
                                  ? 2
                                  : 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          width: double.infinity,
                          child: Column(
                            children: [
                              Icon(
                                Icons.today_rounded,
                                color: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day
                                    ? AppColors.main
                                    : addTaskProvider.selectedDate == null
                                        ? AppColors.blue
                                        : AppColors.main.withValues(alpha: 0.7),
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Bugün",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day
                                      ? AppColors.main
                                      : addTaskProvider.selectedDate == null
                                          ? AppColors.blue
                                          : AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tomorrow button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            addTaskProvider.selectedDate = DateTime.now().add(const Duration(days: 1));
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1)))
                                ? AppColors.main.withValues(alpha: 0.15)
                                : addTaskProvider.selectedDate == null
                                    ? AppColors.blue.withValues(alpha: 0.1)
                                    : AppColors.panelBackground.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1)))
                                  ? AppColors.main
                                  : addTaskProvider.selectedDate == null
                                      ? AppColors.blue
                                      : AppColors.text.withValues(alpha: 0.1),
                              width: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1))) || addTaskProvider.selectedDate == null ? 2 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          width: double.infinity,
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_rounded,
                                color: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1)))
                                    ? AppColors.main
                                    : addTaskProvider.selectedDate == null
                                        ? AppColors.blue
                                        : AppColors.main.withValues(alpha: 0.7),
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Yarın",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1)))
                                      ? AppColors.main
                                      : addTaskProvider.selectedDate == null
                                          ? AppColors.blue
                                          : AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Warning message for routines without date
          if (addTaskProvider.selectedDate == null && addTaskProvider.selectedDays.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.dirtyRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.dirtyRed,
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      "Rutin oluşturmak için başlangıç tarihi seçmelisiniz.",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.dirtyRed,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
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
}
