import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Task%20Detail%20Page/widget/add_manual_log_dialog.dart';
import 'package:gamify_todo/Page/Task%20Detail%20Page/widget/edit_log_dialog.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';
import 'package:provider/provider.dart';

class RecentLogsWidget extends StatefulWidget {
  final TaskDetailViewModel viewModel;

  const RecentLogsWidget({
    super.key,
    required this.viewModel,
  });

  @override
  State<RecentLogsWidget> createState() => _RecentLogsWidgetState();
}

class _RecentLogsWidgetState extends State<RecentLogsWidget> {
  @override
  void initState() {
    super.initState();
    // İlk yüklemede logları güncelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadRecentLogs();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider değiştiğinde logları güncelle
    Provider.of<TaskProvider>(context);

    // Seçili tarih değiştiğinde logları güncelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadRecentLogs();
      setState(() {}); // Widget'ı güncelle
    });
  }

  // Durum rengini döndürür
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.green;
      case 'Failed':
        return AppColors.red;
      case 'Cancelled':
        return AppColors.purple;
      case 'Archived':
        return AppColors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(LocaleKeys.RecentLogs.tr(), style: const TextStyle(color: Colors.grey)),
            // Manuel log ekleme butonu
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () async {
                // Manuel log ekleme dialogunu göster
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => AddManualLogDialog(taskModel: widget.viewModel.taskModel),
                );

                // Eğer log eklendiyse, logları yeniden yükle
                if (result == true) {
                  widget.viewModel.loadRecentLogs();
                }
              },
              tooltip: LocaleKeys.AddManualLog.tr(),
            ),
          ],
        ),
        if (widget.viewModel.recentLogs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                LocaleKeys.NoLogsYet.tr(),
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.viewModel.recentLogs.length,
            itemBuilder: (context, index) {
              final log = widget.viewModel.recentLogs[index];
              return ListTile(
                leading: const Icon(Icons.history, size: 16),
                title: Row(
                  children: [
                    Text(
                      log.dateTime,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(log.status),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.status,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                trailing: Text(log.duration),
                onTap: () async {
                  // Log düzenleme dialogunu göster
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => EditLogDialog(
                      taskModel: widget.viewModel.taskModel,
                      logId: log.logId,
                    ),
                  );

                  // Eğer log düzenlendiyse, logları yeniden yükle
                  if (result == true) {
                    widget.viewModel.loadRecentLogs();
                  }
                },
              );
            },
          ),
      ],
    );
  }
}
