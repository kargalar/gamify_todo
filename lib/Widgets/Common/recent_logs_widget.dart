import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/store_item_log_model.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_progress_view_model.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/edit_log_dialog.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class RecentLogsWidget extends StatefulWidget {
  // For tasks
  final TaskDetailViewModel? taskViewModelForTask;

  // For store items
  final int? storeItemId;
  final TaskTypeEnum? storeItemType;
  final VoidCallback? onLogUpdated;

  const RecentLogsWidget({
    super.key,
    this.taskViewModelForTask,
    this.storeItemId,
    this.storeItemType,
    this.onLogUpdated,
  });

  @override
  State<RecentLogsWidget> createState() => _RecentLogsWidgetState();
}

class _RecentLogsWidgetState extends State<RecentLogsWidget> {
  late Future<List<StoreItemLog>>? _storeItemLogsFuture;

  @override
  void initState() {
    super.initState();
    if (widget.storeItemId != null) {
      _loadStoreItemLogs();
    } else {
      // For tasks, load in didChangeDependencies
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.taskViewModelForTask?.loadRecentLogs();
        setState(() {});
      });
    }
  }

  void _loadStoreItemLogs() {
    setState(() {
      _storeItemLogsFuture = TaskProgressViewModel.getStoreItemLogs(widget.storeItemId!);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.taskViewModelForTask != null) {
      // For tasks
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.taskViewModelForTask?.loadRecentLogs();
        setState(() {});
      });
    }
  }

  // Get status color for task logs
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

  Duration _parseDuration(String text) {
    text = text.replaceAll('+', '').trim();
    bool isNegative = text.startsWith('-');
    if (isNegative) {
      text = text.substring(1);
    }

    int totalSeconds = 0;
    final hoursMatch = RegExp(r'(\d+)h').firstMatch(text);
    if (hoursMatch != null) {
      totalSeconds += int.parse(hoursMatch.group(1)!) * 3600;
    }

    final minutesMatch = RegExp(r'(\d+)m').firstMatch(text);
    if (minutesMatch != null) {
      totalSeconds += int.parse(minutesMatch.group(1)!) * 60;
    }

    final secondsMatch = RegExp(r'(\d+)s').firstMatch(text);
    if (secondsMatch != null) {
      totalSeconds += int.parse(secondsMatch.group(1)!);
    }

    if (hoursMatch == null && minutesMatch == null && secondsMatch == null) {
      final number = int.tryParse(text);
      if (number != null) {
        totalSeconds = number * 60;
      }
    }

    return Duration(seconds: isNegative ? -totalSeconds : totalSeconds);
  }

  void _showAddLogDialog() {
    final TextEditingController valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Manual Log'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              keyboardType: widget.storeItemType == TaskTypeEnum.COUNTER ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                labelText: widget.storeItemType == TaskTypeEnum.COUNTER ? 'Count Change (e.g., +5 or -3)' : 'Duration Change (e.g., +30m or -1h)',
                hintText: widget.storeItemType == TaskTypeEnum.COUNTER ? '+1' : '+30m',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _addManualLog(valueController.text);
              Navigator.pop(context);
              _loadStoreItemLogs();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditLogDialog(StoreItemLog log, int index) {
    final TextEditingController valueController = TextEditingController(
      text: log.formattedValue,
    );

    String? errorText;
    String? previewText = log.formattedValue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          void updatePreview(String txt) {
            if (txt.trim().isEmpty) {
              setState(() {
                errorText = null;
                previewText = null;
              });
              return;
            }
            try {
              dynamic value;
              if (widget.storeItemType == TaskTypeEnum.COUNTER) {
                value = int.parse(txt.replaceAll('+', ''));
                setState(() {
                  errorText = null;
                  previewText = '→ $value';
                });
              } else {
                final d = _parseDuration(txt);
                setState(() {
                  errorText = null;
                  previewText = '→ ${d.isNegative ? '-' : ''}${d.abs().inHours.toString().padLeft(2, '0')}:${(d.abs().inMinutes % 60).toString().padLeft(2, '0')}:${(d.abs().inSeconds % 60).toString().padLeft(2, '0')}';
                });
              }
            } catch (_) {
              setState(() {
                errorText = 'Invalid format';
                previewText = null;
              });
            }
          }

          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.main.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.edit, color: AppColors.main, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Edit Log'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: valueController,
                  autofocus: true,
                  onChanged: updatePreview,
                  keyboardType: widget.storeItemType == TaskTypeEnum.COUNTER ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: widget.storeItemType == TaskTypeEnum.COUNTER ? 'Count Change' : 'Duration Change',
                    hintText: widget.storeItemType == TaskTypeEnum.COUNTER ? '+5  |  -3  |  2' : '+30m  |  -1h  |  45s  |  25 (min)',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    errorText: errorText,
                    suffixIcon: valueController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              valueController.clear();
                              updatePreview('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedOpacity(
                  opacity: previewText == null ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: previewText == null
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.main.withAlpha(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility, size: 16, color: AppColors.main),
                              const SizedBox(width: 6),
                              Text(
                                previewText!,
                                style: TextStyle(color: AppColors.main, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.storeItemType == TaskTypeEnum.COUNTER ? 'Use + / - prefix (optional). Example: +5, -3, 2.' : 'Formats: 1h30m, +45m, -1h, 30s, 25 (min). Multiple units allowed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  _deleteLog(index);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.main,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onPressed: () {
                  try {
                    if (widget.storeItemType == TaskTypeEnum.COUNTER) {
                      int.parse(valueController.text.replaceAll('+', ''));
                    } else {
                      _parseDuration(valueController.text);
                    }
                    _editLog(index, valueController.text);
                    Navigator.pop(context);
                  } catch (_) {
                    setState(() => errorText = 'Invalid format');
                  }
                },
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addManualLog(String valueText) {
    if (valueText.trim().isEmpty) return;

    try {
      dynamic value;
      if (widget.storeItemType == TaskTypeEnum.COUNTER) {
        value = int.parse(valueText.replaceAll('+', ''));
      } else {
        value = _parseDuration(valueText);
      }

      TaskProgressViewModel.addStoreItemLog(
        itemId: widget.storeItemId!,
        action: "Manual Entry",
        value: value,
        type: widget.storeItemType!,
        affectsProgress: true,
      );

      if (widget.onLogUpdated != null) {
        widget.onLogUpdated!();
      }
    } catch (e) {
      debugPrint('[Recent Logs Widget] Error adding manual log: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid format. Please use correct format.')),
      );
    }
  }

  void _editLog(int index, String valueText) {
    if (valueText.trim().isEmpty) return;

    try {
      dynamic value;
      if (widget.storeItemType == TaskTypeEnum.COUNTER) {
        value = int.parse(valueText.replaceAll('+', ''));
      } else {
        value = _parseDuration(valueText);
      }

      TaskProgressViewModel.editStoreItemLog(index, value);

      if (widget.onLogUpdated != null) {
        widget.onLogUpdated!();
      }

      _loadStoreItemLogs();
    } catch (e) {
      debugPrint('[Recent Logs Widget] Error editing log: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid format. Please use correct format.')),
      );
    }
  }

  void _deleteLog(int index) {
    TaskProgressViewModel.deleteStoreItemLog(index);

    if (widget.onLogUpdated != null) {
      widget.onLogUpdated!();
    }

    _loadStoreItemLogs();
  }

  @override
  Widget build(BuildContext context) {
    // For tasks
    if (widget.taskViewModelForTask != null) {
      return _buildTaskLogsWidget();
    }

    // For store items
    return _buildStoreItemLogsWidget();
  }

  Widget _buildTaskLogsWidget() {
    final viewModel = widget.taskViewModelForTask!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${LocaleKeys.RecentLogs.tr()} (${viewModel.recentLogs.length})',
                style: const TextStyle(color: Colors.grey),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.clear_all, size: 20, color: Colors.red),
                    onPressed: () async {
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
                        await viewModel.clearLogsForTask();
                        viewModel.loadRecentLogs();
                        setState(() {});
                      }
                    },
                    tooltip: LocaleKeys.ClearAllLogs.tr(),
                  ),
                ],
              ),
            ],
          ),
          if (viewModel.recentLogs.isEmpty)
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
              height: 200,
              child: ListView.builder(
                shrinkWrap: false,
                physics: const ClampingScrollPhysics(),
                itemCount: viewModel.recentLogs.length,
                itemBuilder: (context, index) {
                  final log = viewModel.recentLogs[index];
                  return ListTile(
                    onTap: () async {
                      // Task logs edit/delete functionality
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => EditLogDialog(
                          taskModel: viewModel.taskModel,
                          logId: log.logId,
                        ),
                      );

                      // Reload logs if log was edited
                      if (result == true) {
                        viewModel.loadRecentLogs();
                        setState(() {});
                      }
                    },
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
                                      text: log.datePart.tr(),
                                      style: TextStyle(color: Colors.blue[700], fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: ' ${log.dateTime.substring(log.dateTime.indexOf(' ') + 1, log.dateTime.lastIndexOf(':'))}',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                    ),
                                    TextSpan(
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
                  );
                },
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStoreItemLogsWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleKeys.RecentLogs.tr(),
                style: const TextStyle(color: Colors.grey),
              ),
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: AppColors.main,
                  size: 20,
                ),
                onPressed: () => _showAddLogDialog(),
              ),
            ],
          ),
          FutureBuilder<List<StoreItemLog>>(
            future: _storeItemLogsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                debugPrint('[Recent Logs Widget Error] ${snapshot.error}');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'Error loading logs',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ),
                );
              }

              final logs = snapshot.data ?? [];

              if (logs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      LocaleKeys.NoLogsYet.tr(),
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return ListTile(
                    onTap: () => _showEditLogDialog(log, index),
                    leading: log.isPurchase ? Icon(Icons.shopping_cart, size: 16, color: AppColors.main) : const Icon(Icons.history, size: 16),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: log.formattedDate.substring(0, log.formattedDate.lastIndexOf(':')),
                                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                    ),
                                    TextSpan(
                                      text: log.formattedDate.substring(log.formattedDate.lastIndexOf(':')),
                                      style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (log.isPurchase)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.main.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '🛒 Purchase',
                                  style: TextStyle(
                                    color: AppColors.main,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Text(log.formattedValue),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
