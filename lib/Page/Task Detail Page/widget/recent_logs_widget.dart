import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/add_manual_log_dialog.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/all_routine_logs_dialog.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/edit_log_dialog.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';

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
    // Load logs only once during initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadRecentLogs();
    });
  }

  // Durum rengini döndürür
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Done':
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
            Text('${LocaleKeys.RecentLogs.tr()} (${widget.viewModel.recentLogs.length})', style: const TextStyle(color: Colors.grey)),
            Row(
              children: [
                // Clear all logs butonu
                IconButton(
                  icon: const Icon(Icons.clear_all, size: 20, color: Colors.red),
                  onPressed: () async {
                    // Onay dialogu göster
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(LocaleKeys.ConfirmationTitle.tr()),
                        content: Text(LocaleKeys.ClearAllLogsConfirmation.tr()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(LocaleKeys.Cancel.tr()),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(LocaleKeys.Delete.tr(), style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await widget.viewModel.clearLogsForTask();
                      widget.viewModel.loadRecentLogs();
                      setState(() {});
                    }
                  },
                  tooltip: LocaleKeys.ClearAllLogs.tr(),
                ),
                // Rutin görevler için "Tüm Rutin Kayıtları" butonu
                if (widget.viewModel.taskModel.routineID != null)
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted, size: 20),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AllRoutineLogsDialog(
                          taskModel: widget.viewModel.taskModel,
                        ),
                      );
                    },
                    tooltip: LocaleKeys.ShowAllRoutineLogs.tr(),
                  ),
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
          SizedBox(
            height: 200, // Sabit yükseklik, kaydırılabilir yapar
            child: ListView.builder(
              shrinkWrap: false,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.viewModel.recentLogs.length,
              itemBuilder: (context, index) {
                final log = widget.viewModel.recentLogs[index];
                return ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    // Tarih kısmını çevir, renkli ve kalın
                                    text: log.datePart.tr(),
                                    style: TextStyle(color: Colors.blue[700], fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    // Saat kısmını ayır (saniye hariç)
                                    text: ' ${log.dateTime.substring(log.dateTime.indexOf(' ') + 1, log.dateTime.lastIndexOf(':'))}',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                  ),
                                  TextSpan(
                                    // Saniye kısmını vurgula
                                    text: log.dateTime.substring(log.dateTime.lastIndexOf(':')),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(log.status),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.status == "" ? "In Progress" : log.status,
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ],
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
          )
      ],
    );
  }
}
