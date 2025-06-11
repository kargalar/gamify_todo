import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/store_item_log_model.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_progress_view_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Enum/task_type_enum.dart';

class StoreItemRecentLogsWidget extends StatefulWidget {
  final List<StoreItemLog> logs;
  final int itemId;
  final TaskTypeEnum itemType;
  final VoidCallback? onLogUpdated;

  const StoreItemRecentLogsWidget({
    super.key,
    required this.logs,
    required this.itemId,
    required this.itemType,
    this.onLogUpdated,
  });

  @override
  State<StoreItemRecentLogsWidget> createState() => _StoreItemRecentLogsWidgetState();
}

class _StoreItemRecentLogsWidgetState extends State<StoreItemRecentLogsWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LocaleKeys.RecentLogs.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
            // + butonu ekle
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
        if (widget.logs.isEmpty)
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
            itemCount: widget.logs.length,
            itemBuilder: (context, index) {
              final log = widget.logs[index];
              return ListTile(
                onTap: () => _showEditLogDialog(log, index),
                leading: const Icon(Icons.history, size: 16),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            // Tarih ve saat kısmını ayır
                            text: log.formattedDate.substring(0, log.formattedDate.lastIndexOf(':')),
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                          TextSpan(
                            // Saniye kısmını vurgula
                            text: log.formattedDate.substring(log.formattedDate.lastIndexOf(':')),
                            style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Text(log.formattedValue),
              );
            },
          ),
      ],
    );
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
              keyboardType: widget.itemType == TaskTypeEnum.COUNTER ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                labelText: widget.itemType == TaskTypeEnum.COUNTER ? 'Count Change (e.g., +5 or -3)' : 'Duration Change (e.g., +30m or -1h)',
                hintText: widget.itemType == TaskTypeEnum.COUNTER ? '+1' : '+30m',
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Log'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              keyboardType: widget.itemType == TaskTypeEnum.COUNTER ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                labelText: widget.itemType == TaskTypeEnum.COUNTER ? 'Count Change' : 'Duration Change',
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
              _deleteLog(index);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () {
              _editLog(index, valueController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addManualLog(String valueText) {
    if (valueText.trim().isEmpty) return;

    try {
      dynamic value;
      if (widget.itemType == TaskTypeEnum.COUNTER) {
        // Parse counter value (e.g., "+5", "-3", "2")
        value = int.parse(valueText.replaceAll('+', ''));
      } else {
        // Parse duration value (e.g., "+30m", "-1h", "45s")
        value = _parseDuration(valueText);
      }

      TaskProgressViewModel.addStoreItemLog(
        itemId: widget.itemId,
        action: "Manual Entry",
        value: value,
        type: widget.itemType,
      );

      if (widget.onLogUpdated != null) {
        widget.onLogUpdated!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid format. Please use correct format.')),
      );
    }
  }

  void _editLog(int index, String valueText) {
    if (valueText.trim().isEmpty) return;

    try {
      dynamic value;
      if (widget.itemType == TaskTypeEnum.COUNTER) {
        value = int.parse(valueText.replaceAll('+', ''));
      } else {
        value = _parseDuration(valueText);
      }

      TaskProgressViewModel.editStoreItemLog(index, value);

      if (widget.onLogUpdated != null) {
        widget.onLogUpdated!();
      }
    } catch (e) {
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
  }

  Duration _parseDuration(String text) {
    // Remove + sign if present
    text = text.replaceAll('+', '').trim();

    // Check if it's negative
    bool isNegative = text.startsWith('-');
    if (isNegative) {
      text = text.substring(1);
    }

    int totalSeconds = 0;

    // Parse hours (e.g., "2h")
    final hoursMatch = RegExp(r'(\d+)h').firstMatch(text);
    if (hoursMatch != null) {
      totalSeconds += int.parse(hoursMatch.group(1)!) * 3600;
    }

    // Parse minutes (e.g., "30m")
    final minutesMatch = RegExp(r'(\d+)m').firstMatch(text);
    if (minutesMatch != null) {
      totalSeconds += int.parse(minutesMatch.group(1)!) * 60;
    }

    // Parse seconds (e.g., "45s")
    final secondsMatch = RegExp(r'(\d+)s').firstMatch(text);
    if (secondsMatch != null) {
      totalSeconds += int.parse(secondsMatch.group(1)!);
    }

    // If no unit found, assume minutes
    if (hoursMatch == null && minutesMatch == null && secondsMatch == null) {
      final number = int.tryParse(text);
      if (number != null) {
        totalSeconds = number * 60; // Assume minutes
      }
    }

    return Duration(seconds: isNegative ? -totalSeconds : totalSeconds);
  }
}
