import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';

class NotificationStatus extends StatefulWidget {
  const NotificationStatus({
    super.key,
  });

  @override
  State<NotificationStatus> createState() => _NotificationStatusState();
}

class _NotificationStatusState extends State<NotificationStatus> {
  late final addTaskProvider = context.watch<AddTaskProvider>();

  @override
  Widget build(BuildContext context) {
    // Bildirim durumuna göre renk ve simge belirle
    final Color activeColor = addTaskProvider.isNotificationOn
        ? AppColors.main
        : addTaskProvider.isAlarmOn
            ? AppColors.red
            : AppColors.text.withValues(alpha: 0.5);

    final IconData notificationIcon = addTaskProvider.isNotificationOn
        ? Icons.notifications_active
        : addTaskProvider.isAlarmOn
            ? Icons.alarm
            : Icons.notifications_off;

    final String statusText = addTaskProvider.isNotificationOn
        ? "Bildirim"
        : addTaskProvider.isAlarmOn
            ? "Alarm"
            : "Kapalı";

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
              const Text(
                "Notifications",
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

          // Notification status selector
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
                  await changeNotificationStatus();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    children: [
                      // Main notification row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                        ],
                      ),

                      // Time display if set (in a separate row to avoid overflow)
                      if (addTaskProvider.selectedTime != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: activeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: activeColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${addTaskProvider.selectedTime!.hour.toString().padLeft(2, '0')}:${addTaskProvider.selectedTime!.minute.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: activeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Notification status info
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
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
                        ? "Tap to set a notification time for this task"
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
          ), // Early reminder section (show if notification or alarm is on)
          if ((addTaskProvider.isNotificationOn || addTaskProvider.isAlarmOn) && addTaskProvider.selectedTime != null) ...[
            // Early reminder title
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
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
                      addTaskProvider.earlyReminderMinutes == null ? "No early reminder will be sent" : "A notification will be sent ${Duration(minutes: addTaskProvider.earlyReminderMinutes!).compactFormat()} before the ${addTaskProvider.isAlarmOn ? 'alarm' : 'notification'}",
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

  // Build early reminder options grid
  Widget _buildEarlyReminderOptions() {
    // Use a grid layout for better organization
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
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

  Future changeNotificationStatus() async {
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
        // Alarm açıldığında earlyReminderMinutes'ı null olarak ayarla
        addTaskProvider.updateEarlyReminderMinutes(null);
      } else if (addTaskProvider.isAlarmOn) {
        addTaskProvider.isAlarmOn = false;
        // Alarm kapatıldığında earlyReminderMinutes'ı null olarak ayarla
        addTaskProvider.updateEarlyReminderMinutes(null);
      } else {
        if (!(await NotificationService().requestNotificationPermissions())) return;

        addTaskProvider.isNotificationOn = true;
      }
      // State'i güncelle ve widget'ı yeniden oluştur
      setState(() {});
      // Provider'ı güncelle ve bağımlı widget'ları yeniden oluştur
      addTaskProvider.refreshNotificationStatus();
    }
  }
}
