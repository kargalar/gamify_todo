import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Service/notification_services.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class SelectTime extends StatefulWidget {
  const SelectTime({
    super.key,
  });

  @override
  State<SelectTime> createState() => _SelectTimeState();
}

class _SelectTimeState extends State<SelectTime> {
  late final addTaskProvider = context.read<AddTaskProvider>();

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
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.watch<AddTaskProvider>().selectedTime?.to24Hours() ?? LocaleKeys.SelectTime.tr(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        onTap: () async {
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
        },
      ),
    );
  }
}
