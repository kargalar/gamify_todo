import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Service/notification_services.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class TimeNotificationWidget extends StatefulWidget {
  const TimeNotificationWidget({
    super.key,
  });

  @override
  State<TimeNotificationWidget> createState() => _TimeNotificationWidgetState();
}

class _TimeNotificationWidgetState extends State<TimeNotificationWidget> {
  late final addTaskProvider = context.watch<AddTaskProvider>();

  @override
  Widget build(BuildContext context) {
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
                Icons.notifications_rounded,
                color: AppColors.main,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Time & Notifications",
                style: const TextStyle(
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
                    color: addTaskProvider.selectedTime != null 
                        ? AppColors.main.withValues(alpha: 0.3)
                        : AppColors.text.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 24,
                      color: addTaskProvider.selectedTime != null 
                          ? AppColors.main 
                          : AppColors.text.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      addTaskProvider.selectedTime?.to24Hours() ?? LocaleKeys.SelectTime.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: addTaskProvider.selectedTime != null 
                            ? AppColors.main 
                            : AppColors.text.withValues(alpha: 0.6),
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
          
          const SizedBox(height: 12),
          
          // Notification status selector (only if time is set)
          if (addTaskProvider.selectedTime != null)
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
          
          // Notification info
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
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
                    addTaskProvider.selectedTime == null
                        ? "Tap to select a time for this task"
                        : addTaskProvider.isNotificationOn
                            ? "Standard notification will appear at the set time"
                            : addTaskProvider.isAlarmOn
                                ? "Full-screen alarm will appear at the set time"
                                : "No notifications will be sent for this task",
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
          
          // Early reminder section (only show if alarm is on)
          if (addTaskProvider.isAlarmOn && addTaskProvider.selectedTime != null) ...[
            // Early reminder title
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12),
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
            
            // Early reminder options
            Container(
              decoration: BoxDecoration(
                color: AppColors.panelBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.red.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: _buildEarlyReminderOptions(),
            ),
            
            // Early reminder info
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
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
                      addTaskProvider.earlyReminderMinutes == null 
                          ? "No early reminder will be sent" 
                          : "A notification will be sent ${Duration(minutes: addTaskProvider.earlyReminderMinutes!).compactFormat()} before the alarm",
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
        ],
      ),
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
        if (addTaskProvider.isAlarmOn) return;
        addTaskProvider.isNotificationOn = true;
      } else {
        addTaskProvider.isNotificationOn = false;
        addTaskProvider.isAlarmOn = false;
      }
    } else {
      addTaskProvider.isNotificationOn = false;
      addTaskProvider.isAlarmOn = false;
    }

    addTaskProvider.updateTime(selectedTime);
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
          if (addTaskProvider.isAlarmOn) return;
          addTaskProvider.isNotificationOn = true;
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
      crossAxisCount: 4,
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
        _buildReminderOption(20),
        _buildReminderOption(30),
        _buildReminderOption(60),
        _buildReminderOption(120),
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
