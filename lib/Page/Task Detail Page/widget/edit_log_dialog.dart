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
import 'package:next_level/Service/server_manager.dart';

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
                        final time = await Helper().selectTime(context, initialTime: selectedTime);
                        if (time != null) {
                          setState(() => selectedTime = time);
                        }
                      },
                      child: _Pill(value: selectedTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Status kaldırıldı - kullanıcı status'u değiştiremesin
            if (widget.taskModel.type != TaskTypeEnum.CHECKBOX) const SizedBox(height: 0),
            if (widget.taskModel.type != TaskTypeEnum.CHECKBOX)
              _CompactSection(
                label: LocaleKeys.Progress.tr(),
                icon: Icons.trending_up_outlined,
                child: widget.taskModel.type == TaskTypeEnum.COUNTER
                    ? TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: LocaleKeys.EnterCount.tr(),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        controller: TextEditingController(text: count?.toString() ?? ''),
                        onChanged: (v) => setState(() => count = int.tryParse(v)),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: LocaleKeys.Hours.tr(),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              controller: TextEditingController(text: hours.toString()),
                              onChanged: (v) => setState(() => hours = int.tryParse(v) ?? 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: LocaleKeys.Minutes.tr(),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              controller: TextEditingController(text: minutes.toString()),
                              onChanged: (v) => setState(() => minutes = int.tryParse(v) ?? 0),
                            ),
                          ),
                        ],
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
        await ServerManager().updateTask(taskModel: taskProvider.taskList[taskIndex]);
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
