import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Service/notification_services.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
      ),
      child: InkWell(
        borderRadius: AppColors.borderRadiusAll,
        onTap: () async {
          await changeNotificationStatus();
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 5),
              Icon(
                addTaskProvider.isNotificationOn
                    ? Icons.notifications_active
                    : addTaskProvider.isAlarmOn
                        ? Icons.alarm
                        : Icons.notifications_off,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future changeNotificationStatus() async {
    if (addTaskProvider.selectedTime == null) {
      final TimeOfDay? selectedTime = await Helper().selectTime(context, initialTime: addTaskProvider.selectedTime);

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
      } else if (addTaskProvider.isAlarmOn) {
        addTaskProvider.isAlarmOn = false;
      } else {
        if (!(await NotificationService().requestNotificationPermissions())) return;

        addTaskProvider.isNotificationOn = true;
      }
      setState(() {});
    }
  }
}
