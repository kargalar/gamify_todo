import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';

class TopItem extends StatelessWidget {
  const TopItem({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Duration workHour = Duration.zero;

    // TODO: galiba şu tarz yerler daha iyi bir yöntem ile yapılabilir. 1000 task olduğu zaman sayfaya her giriğinde birçok yerde böyle bir döngünün çalışması iyi olmaz
    for (var task in TaskProvider().taskList) {
      if (task.taskDate.isAfter(DateTime.now().subtract(const Duration(days: 7))) && task.remainingDuration != null) {
        if (task.type == TaskTypeEnum.CHECKBOX && task.status != TaskStatusEnum.COMPLETED) {
          continue;
        } else {
          workHour += task.type == TaskTypeEnum.CHECKBOX
              ? task.remainingDuration!
              : task.type == TaskTypeEnum.COUNTER
                  ? task.remainingDuration! * task.currentCount!
                  : task.currentDuration!;
        }
      }
    }

    return Column(
      children: [
        Text(
          LocaleKeys.WeeklyWorkHour.tr(),
          style: TextStyle(
            color: AppColors.main,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          workHour.textShort2hour(),
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
