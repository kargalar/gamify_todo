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
              if (widget.itemType == TaskTypeEnum.COUNTER) {
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
                    color: AppColors.main.withAlpha(38), // was withOpacity(.15)
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
                  keyboardType: widget.itemType == TaskTypeEnum.COUNTER ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: widget.itemType == TaskTypeEnum.COUNTER ? 'Count Change' : 'Duration Change',
                    hintText: widget.itemType == TaskTypeEnum.COUNTER ? '+5  |  -3  |  2' : '+30m  |  -1h  |  45s  |  25 (min)',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77), // was .withOpacity(.3)
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
                            color: AppColors.main.withAlpha(20), // was withOpacity(.08)
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
                  widget.itemType == TaskTypeEnum.COUNTER ? 'Use + / - prefix (optional). Example: +5, -3, 2.' : 'Formats: 1h30m, +45m, -1h, 30s, 25 (min). Multiple units allowed.',
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
                  // validate before save
                  try {
                    if (widget.itemType == TaskTypeEnum.COUNTER) {
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
      if (widget.itemType == TaskTypeEnum.COUNTER) {
        // Parse counter value (e.g., "+5", "-3", "2")
        value = int.parse(valueText.replaceAll('+', ''));
      } else {
        // Parse duration value (e.g., "+30m", "-1h", "45s")
        value = _parseDuration(valueText);
      }

      // Manual logs should affect the item's progress
      TaskProgressViewModel.addStoreItemLog(
        itemId: widget.itemId,
        action: "Manual Entry",
        value: value,
        type: widget.itemType,
        affectsProgress: true,
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
