import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'select_days.dart';

class DateTimeNotificationWidget extends StatefulWidget {
  const DateTimeNotificationWidget({
    super.key,
  });

  @override
  State<DateTimeNotificationWidget> createState() => _DateTimeNotificationWidgetState();
}

class _DateTimeNotificationWidgetState extends State<DateTimeNotificationWidget> {
  late DateTime _focusedDay = DateTime.now();
  bool _didInit = false;

  AddTaskProvider get addTaskProvider => Provider.of<AddTaskProvider>(context, listen: false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      final provider = Provider.of<AddTaskProvider>(context, listen: false);
      _focusedDay = provider.selectedDate ?? _focusedDay;
      _didInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the widget rebuilds when provider changes
    context.watch<AddTaskProvider>();

    // Notification status colors and icons
    final Color activeColor = addTaskProvider.isNotificationOn
        ? AppColors.main
        : addTaskProvider.isAlarmOn
            ? AppColors.red
            : AppColors.text.withValues(alpha: 0.5);

    final IconData notificationIcon = addTaskProvider.isNotificationOn
        ? Icons.notifications_active_rounded
        : addTaskProvider.isAlarmOn
            ? Icons.alarm_rounded
            : Icons.notifications_off_rounded;

    final String statusText = addTaskProvider.isNotificationOn
        ? "Notification"
        : addTaskProvider.isAlarmOn
            ? "Alarm"
            : "Off";

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title, icon and switch
          ClickableTooltip(
            titleKey: LocaleKeys.tooltip_date_time_notifications_title,
            bulletPoints: [
              LocaleKeys.tooltip_date_time_notifications_bullet_1.tr(),
              LocaleKeys.tooltip_date_time_notifications_bullet_2.tr(),
              LocaleKeys.tooltip_date_time_notifications_bullet_3.tr(),
              LocaleKeys.tooltip_date_time_notifications_bullet_4.tr(),
              LocaleKeys.tooltip_date_time_notifications_bullet_5.tr(),
              LocaleKeys.tooltip_date_time_notifications_bullet_6.tr(),
            ],
            child: Container(
              color: AppColors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event_note_rounded,
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
                  // Task/Routine Switch
                  Row(
                    children: [
                      Text(
                        "Task",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: !addTaskProvider.isRoutine ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: addTaskProvider.isRoutine,
                        onChanged: (value) {
                          setState(() {
                            addTaskProvider.isRoutine = value;
                            if (value) {
                              // Routine seçildiğinde tarihi today olarak ayarla
                              addTaskProvider.selectedDate = DateTime.now();
                            } else {
                              // Task seçildiğinde selectedDays'ı temizle
                              addTaskProvider.selectedDays = [];
                            }
                          });
                        },
                        activeThumbColor: AppColors.main,
                        activeTrackColor: AppColors.main.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Routine",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: addTaskProvider.isRoutine ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

          // Calendar or Select Days section based on task/routine mode
          if (!addTaskProvider.isRoutine) _buildCalendarSection() else SelectDaysWidget(addTaskProvider: addTaskProvider),

          const SizedBox(height: 12),

          // Time selector
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Unfocus any text fields before showing time picker
                addTaskProvider.unfocusAll();

                // Select time
                _selectTime();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: addTaskProvider.selectedTime != null ? AppColors.main.withValues(alpha: 0.3) : AppColors.text.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 24,
                      color: addTaskProvider.selectedTime != null ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      addTaskProvider.selectedTime?.to24Hours() ?? LocaleKeys.SelectTime.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: addTaskProvider.selectedTime != null ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    if (addTaskProvider.selectedTime != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.main.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Set",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.main,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Notification status selector (only if time is set)
          if (addTaskProvider.selectedTime != null) ...[
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppColors.panelBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    // Unfocus any text fields when changing notification status
                    addTaskProvider.unfocusAll();
                    await _changeNotificationStatus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        // Notification icon
                        Icon(
                          notificationIcon,
                          size: 24,
                          color: activeColor,
                        ),
                        const SizedBox(width: 12),
                        // Notification status text
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: activeColor,
                          ),
                        ),
                        const Spacer(),
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: activeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            addTaskProvider.isNotificationOn
                                ? "On"
                                : addTaskProvider.isAlarmOn
                                    ? "On"
                                    : "Off",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: activeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Early reminder section (show for both notifications and alarms)
            if ((addTaskProvider.isNotificationOn || addTaskProvider.isAlarmOn) && addTaskProvider.selectedTime != null) ...[
              // Early reminder title
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: ClickableTooltip(
                  titleKey: LocaleKeys.tooltip_early_reminder_title,
                  bulletPoints: [
                    LocaleKeys.tooltip_early_reminder_bullet_1.tr(),
                    LocaleKeys.tooltip_early_reminder_bullet_2.tr(),
                    LocaleKeys.tooltip_early_reminder_bullet_3.tr(),
                    LocaleKeys.tooltip_early_reminder_bullet_4.tr(),
                  ],
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_rounded,
                        size: 18,
                        color: AppColors.red.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Early Reminder",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Early reminder options
              Container(
                decoration: BoxDecoration(
                  color: AppColors.panelBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: _buildEarlyReminderOptions(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Build calendar section with quick date buttons
  Widget _buildCalendarSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calendar (reduced width)
        Expanded(
          flex: 4,
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
              locale: context.locale.toLanguageTag(),
              rowHeight: 36,
              firstDay: DateTime(1950),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarBuilders: CalendarBuilders(
                headerTitleBuilder: (context, day) {
                  final selectedDate = addTaskProvider.selectedDate;
                  final visibleMonth = DateFormat('MMMM yyyy', context.locale.toLanguageTag()).format(_focusedDay);

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.main.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            visibleMonth,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.main,
                            ),
                          ),
                          if (selectedDate != null)
                            Text(
                              DateFormat('d MMMM yyyy', context.locale.toLanguageTag()).format(selectedDate),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.main.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              selectedDayPredicate: (day) => addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableGestures: AvailableGestures.horizontalSwipe,
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
                  color: addTaskProvider.selectedDate == null ? AppColors.main.withValues(alpha: 0.2) : AppColors.main.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: addTaskProvider.selectedDate == null ? Border.all(color: AppColors.main, width: 1) : null,
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
                  _focusedDay = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
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
                    final now = DateTime.now();
                    setState(() {
                      addTaskProvider.selectedDate = now;
                      _focusedDay = DateTime(now.year, now.month, now.day);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day
                          ? AppColors.main.withValues(alpha: 0.15)
                          : AppColors.panelBackground.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day
                            ? AppColors.main
                            : AppColors.text.withValues(alpha: 0.1),
                        width: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day || addTaskProvider.selectedDate == null ? 2 : 1,
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
                              : AppColors.main.withValues(alpha: 0.7),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LocaleKeys.Today.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day ? AppColors.main : AppColors.text,
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
                    final t = DateTime.now().add(const Duration(days: 1));
                    setState(() {
                      addTaskProvider.selectedDate = t;
                      _focusedDay = DateTime(t.year, t.month, t.day);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1))) ? AppColors.green.withValues(alpha: 0.15) : AppColors.panelBackground.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1))) ? AppColors.green : AppColors.text.withValues(alpha: 0.1),
                        width: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1))) || addTaskProvider.selectedDate == null ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    width: double.infinity,
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_rounded,
                          color: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1))) ? AppColors.green : AppColors.green.withValues(alpha: 0.7),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LocaleKeys.Tomorrow.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1))) ? AppColors.green : AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Only show clear date button if no repeat days are selected
              if (addTaskProvider.selectedDays.isEmpty) ...[
                const SizedBox(height: 10),

                // No Date button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Rutin günü seçiliyken tarihsiz seçilmeye çalışıldığında uyarı
                      if (addTaskProvider.selectedDays.isNotEmpty) {
                        Helper().getMessage(
                          message: LocaleKeys.RoutineCannotBeDateless.tr(),
                          status: StatusEnum.WARNING,
                        );
                        return;
                      }

                      setState(() {
                        addTaskProvider.selectedDate = null;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: addTaskProvider.selectedDate == null ? AppColors.red.withValues(alpha: 0.15) : AppColors.panelBackground.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: addTaskProvider.selectedDate == null ? AppColors.red : AppColors.text.withValues(alpha: 0.1),
                          width: addTaskProvider.selectedDate == null ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      width: double.infinity,
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            color: addTaskProvider.selectedDate == null ? AppColors.red : AppColors.red.withValues(alpha: 0.7),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            LocaleKeys.NoDate.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: addTaskProvider.selectedDate == null ? AppColors.red : AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Method to handle time selection with proper async handling
  Future<void> _selectTime() async {
    // Add a small delay to ensure keyboard is fully dismissed
    await Future.delayed(const Duration(milliseconds: 100));

    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    final TimeOfDay? selectedTime = await Helper().selectTime(context, initialTime: addTaskProvider.selectedTime);

    // Check again if widget is still mounted
    if (!mounted) return;

    if (selectedTime != null) {
      if (await NotificationService().requestNotificationPermissions()) {
        if (!addTaskProvider.isAlarmOn) {
          addTaskProvider.isNotificationOn = true;
        }
      } else {
        addTaskProvider.isNotificationOn = false;
        addTaskProvider.isAlarmOn = false;
      }
    } else {
      addTaskProvider.isNotificationOn = false;
      addTaskProvider.isAlarmOn = false;
    }

    addTaskProvider.updateTime(selectedTime);

    // Force UI update
    setState(() {});
  }

  // Method to change notification status
  Future<void> _changeNotificationStatus() async {
    if (addTaskProvider.selectedTime == null) {
      // Add a small delay to ensure keyboard is fully dismissed
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      final TimeOfDay? selectedTime = await Helper().selectTime(context, initialTime: addTaskProvider.selectedTime);

      // Check again if widget is still mounted
      if (!mounted) return;

      if (selectedTime != null) {
        if (await NotificationService().requestNotificationPermissions()) {
          if (!addTaskProvider.isAlarmOn) {
            addTaskProvider.isNotificationOn = true;
          }
        } else {
          addTaskProvider.isNotificationOn = false;
          addTaskProvider.isAlarmOn = false;
        }
      } else {
        addTaskProvider.isNotificationOn = false;
        addTaskProvider.isAlarmOn = false;
      }

      addTaskProvider.updateTime(selectedTime);

      setState(() {});
    } else {
      if (addTaskProvider.isNotificationOn) {
        addTaskProvider.isNotificationOn = false;

        if (!(await NotificationService().requestAlarmPermission())) return;

        addTaskProvider.isAlarmOn = true;
        // Reset early reminder when alarm is turned on
        addTaskProvider.updateEarlyReminderMinutes(null);
      } else if (addTaskProvider.isAlarmOn) {
        addTaskProvider.isAlarmOn = false;
        // Reset early reminder when alarm is turned off
        addTaskProvider.updateEarlyReminderMinutes(null);
      } else {
        if (!(await NotificationService().requestNotificationPermissions())) return;

        addTaskProvider.isNotificationOn = true;
      }
      // Update state and rebuild widget
      setState(() {});
      // Update provider and rebuild dependent widgets
      addTaskProvider.refreshNotificationStatus();
    }
  }

  // Build early reminder options grid
  Widget _buildEarlyReminderOptions() {
    // Use a grid layout for better organization
    return GridView.count(
      crossAxisCount: 5, // Changed from 4 to 5 to accommodate 10 options
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.5, // Increased for better text fitting
      children: [
        _buildReminderOption(null),
        _buildReminderOption(5),
        _buildReminderOption(10),
        _buildReminderOption(15),
        _buildReminderOption(30),
        _buildReminderOption(60),
        _buildReminderOption(120),
        _buildReminderOption(300),
        _buildReminderOption(600),
        _buildReminderOption(1440),
      ],
    );
  }

  // Build early reminder option button
  Widget _buildReminderOption(int? minutes) {
    final bool isSelected = addTaskProvider.earlyReminderMinutes == minutes;
    final Color optionColor = isSelected ? AppColors.red : AppColors.text.withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          addTaskProvider.updateEarlyReminderMinutes(minutes);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? optionColor.withValues(alpha: 0.15) : AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? optionColor : AppColors.text.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: optionColor.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              Duration(minutes: minutes ?? 0).compactFormat(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? optionColor : AppColors.text.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
