import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';

class AllTimeStatsWidget extends StatelessWidget {
  final TaskDetailViewModel viewModel;
  final TaskTypeEnum taskType;

  const AllTimeStatsWidget({
    super.key,
    required this.viewModel,
    required this.taskType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "${LocaleKeys.AllTime.tr()} ${taskType == TaskTypeEnum.TIMER ? viewModel.allTimeDuration.textShort3() : viewModel.allTimeCount}",
          style: const TextStyle(fontSize: 20),
        ),
        Text(
          "${viewModel.daysInProgress} ${LocaleKeys.DaysInProgress.tr()}",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        Text(
          "${LocaleKeys.Average.tr()}: ${viewModel.averagePerDay} ${LocaleKeys.InADay.tr()}",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
