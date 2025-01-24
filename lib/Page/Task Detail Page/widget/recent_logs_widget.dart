import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';

class RecentLogsWidget extends StatelessWidget {
  final TaskDetailViewModel viewModel;

  const RecentLogsWidget({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleKeys.RecentLogs.tr(), style: const TextStyle(color: Colors.grey)),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: viewModel.recentLogs.length,
          itemBuilder: (context, index) {
            final log = viewModel.recentLogs[index];
            return ListTile(
              leading: const Icon(Icons.edit, size: 16),
              contentPadding: EdgeInsets.zero,
              title: Text(
                log.dateTime,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              trailing: Text(log.duration),
            );
          },
        ),
      ],
    );
  }
}
