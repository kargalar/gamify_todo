import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Repository/task_repository.dart';

class EditLogDialog extends StatefulWidget {
  final TaskModel taskModel;
  final int logId;

  const EditLogDialog({
    super.key,
    required this.taskModel,
    required this.logId,
  });

  @override
  State<EditLogDialog> createState() => _EditLogDialogState();
}

class _EditLogDialogState extends State<EditLogDialog> {
  late TaskLogModel logModel;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;

  // Progress değerleri
  int? count;
  int hours = 0;
  int minutes = 0;
  TaskStatusEnum? selectedStatus; // Null olabilir (In Progress/None)

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogData();
  }

  Future<void> _loadLogData() async {
    // Log verilerini yükle
    final logs = await HiveService().getTaskLogs();
    logModel = logs.firstWhere((log) => log.id == widget.logId);

    // Değerleri ayarla
    selectedDate = logModel.logDate;
    selectedTime = TimeOfDay(
      hour: logModel.logDate.hour,
      minute: logModel.logDate.minute,
    );

    if (logModel.duration != null) {
      hours = logModel.duration!.inHours;
      minutes = logModel.duration!.inMinutes.remainder(60);
    }

    if (logModel.count != null) {
      count = logModel.count;
    }

    selectedStatus = logModel.status;

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      title: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.main.withAlpha(38),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.edit_note_outlined, color: AppColors.main, size: 22),
          ),
          const SizedBox(width: 12),
          Text(LocaleKeys.EditLog.tr()),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarih ve Saat (yan yana kartlar)
            Row(
              children: [
                Expanded(
                  child: _CompactSection(
                    label: LocaleKeys.Date.tr(),
                    icon: Icons.calendar_today,
                    child: InkWell(
                      onTap: () async {
                        final date = await Helper().selectDate(
                          context: context,
                          initialDate: selectedDate,
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                      child: _Pill(value: DateFormat('d MMM yyyy').format(selectedDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CompactSection(
                    label: LocaleKeys.Time.tr(),
                    icon: Icons.access_time,
                    child: InkWell(
                      onTap: () async {
                        final result = await Helper().selectTime(context, initialTime: selectedTime);
                        if (result != null) {
                          final TimeOfDay time = result['time'] as TimeOfDay;
                          final bool dateChanged = result['dateChanged'] as bool;

                          setState(() {
                            selectedTime = time;
                            // Update date if needed
                            if (dateChanged) {
                              selectedDate = selectedDate.add(const Duration(days: 1));
                            }
                          });
                        }
                      },
                      child: _Pill(value: selectedTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress section based on task type
            if (widget.taskModel.type != TaskTypeEnum.CHECKBOX) const SizedBox(height: 0),
            if (widget.taskModel.type != TaskTypeEnum.CHECKBOX)
              _CompactSection(
                label: LocaleKeys.Progress.tr(),
                icon: Icons.trending_up_outlined,
                child: widget.taskModel.type == TaskTypeEnum.COUNTER
                    ? _CounterControl(
                        count: count ?? 0,
                        onChanged: (value) => setState(() => count = value),
                      )
                    : _DurationPicker(
                        hours: hours,
                        minutes: minutes,
                        onChanged: (h, m) => setState(() {
                          hours = h;
                          minutes = m;
                        }),
                      ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.Cancel.tr()),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: _deleteLogAndNavigate,
          icon: const Icon(Icons.delete_outline, size: 18),
          label: Text(LocaleKeys.Delete.tr()),
        ),
        ElevatedButton.icon(
          onPressed: _updateLogAndNavigate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.main,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: const Icon(Icons.save_outlined, size: 18),
          label: Text(LocaleKeys.Save.tr()),
        ),
      ],
    );
  }

  // Log güncelleme ve navigasyon işlemini birleştiren metod
  Future<void> _updateLogAndNavigate() async {
    await _updateLog();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  // Log silme ve navigasyon işlemini birleştiren metod
  Future<void> _deleteLogAndNavigate() async {
    await _deleteLog();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _updateLog() async {
    // Seçilen tarih ve saati birleştir (saniye ve milisaniye ekleyerek)
    final now = DateTime.now();
    final logDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
      now.second,
      now.millisecond,
    );

    // Task tipine göre ilerleme değerini ayarla
    Duration? duration;
    int? countValue;

    if (widget.taskModel.type == TaskTypeEnum.TIMER) {
      duration = Duration(hours: hours, minutes: minutes);
    } else if (widget.taskModel.type == TaskTypeEnum.COUNTER) {
      countValue = count;
    }

    // Log güncelle
    logModel.logDate = logDateTime;
    logModel.duration = duration;
    logModel.count = countValue;

    // selectedStatus null olabilir (In Progress/None)
    // ancak UI'da bu boş string olarak gösterilecek
    logModel.status = selectedStatus;

    await HiveService().addTaskLog(logModel);

    // Provider'ı güncelle
    await TaskLogProvider().loadTaskLogs();
  }

  Future<void> _deleteLog() async {
    // Log sil
    await HiveService().deleteTaskLog(logModel.id);

    // Check if this was the last log for this task
    final taskLogProvider = TaskLogProvider();
    await taskLogProvider.loadTaskLogs();

    // Get all logs for this task
    final remainingLogs = taskLogProvider.getLogsByTaskId(widget.taskModel.id);

    // If no logs remain, reset the task status to null
    if (remainingLogs.isEmpty) {
      // Find the task in TaskProvider
      final taskProvider = TaskProvider();
      final taskIndex = taskProvider.taskList.indexWhere((task) => task.id == widget.taskModel.id);

      if (taskIndex != -1) {
        // Reset task status to null
        taskProvider.taskList[taskIndex].status = null;
        // Update task in storage
        await TaskRepository().updateTask(taskProvider.taskList[taskIndex]);
        // Notify listeners
        taskProvider.updateItems();
      }
    }
  }
}

// Compact section wrapper for consistent styling
class _CompactSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  const _CompactSection({required this.label, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary.withAlpha(200)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

// Pill style display for date/time
class _Pill extends StatelessWidget {
  final String value;
  const _Pill({required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(77)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value),
          const Icon(Icons.expand_more, size: 18),
        ],
      ),
    );
  }
}

// Counter control with +/- buttons
class _CounterControl extends StatelessWidget {
  final int count;
  final ValueChanged<int> onChanged;

  const _CounterControl({required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(77)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decrease button
          IconButton(
            onPressed: () => onChanged(count - 1),
            icon: Icon(Icons.remove_circle_outline, color: AppColors.red),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(40, 40),
            ),
          ),
          // Count display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.main.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.main,
              ),
            ),
          ),
          // Increase button
          IconButton(
            onPressed: () => onChanged(count + 1),
            icon: Icon(Icons.add_circle_outline, color: AppColors.green),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(40, 40),
            ),
          ),
        ],
      ),
    );
  }
}

// Duration picker with scroll wheels
class _DurationPicker extends StatelessWidget {
  final int hours;
  final int minutes;
  final Function(int hours, int minutes) onChanged;

  const _DurationPicker({
    required this.hours,
    required this.minutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(77)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hours picker
          _TimeUnit(
            value: hours,
            label: LocaleKeys.Hours.tr(),
            maxValue: 23,
            onChanged: (value) => onChanged(value, minutes),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.main.withAlpha(150),
              ),
            ),
          ),
          // Minutes picker
          _TimeUnit(
            value: minutes,
            label: LocaleKeys.Minutes.tr(),
            maxValue: 59,
            onChanged: (value) => onChanged(hours, value),
          ),
        ],
      ),
    );
  }
}

// Time unit component (hours or minutes)
class _TimeUnit extends StatelessWidget {
  final int value;
  final String label;
  final int maxValue;
  final ValueChanged<int> onChanged;

  const _TimeUnit({
    required this.value,
    required this.label,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Increase button
        IconButton(
          onPressed: () {
            final newValue = value < maxValue ? value + 1 : 0;
            onChanged(newValue);
          },
          icon: Icon(Icons.keyboard_arrow_up, color: AppColors.main),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(4),
            minimumSize: const Size(40, 40),
          ),
        ),
        // Value display
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.main.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.main,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        // Decrease button
        IconButton(
          onPressed: () {
            final newValue = value > 0 ? value - 1 : maxValue;
            onChanged(newValue);
          },
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.main),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(4),
            minimumSize: const Size(40, 40),
          ),
        ),
      ],
    );
  }
}
