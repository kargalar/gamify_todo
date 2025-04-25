import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/task_log_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Provider/task_log_provider.dart';
import 'package:gamify_todo/Service/hive_service.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';

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
  TaskStatusEnum? selectedStatus = TaskStatusEnum.COMPLETED;

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
      title: Text(LocaleKeys.EditLog.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarih seçimi
            Text(LocaleKeys.Date.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await Helper().selectDate(
                  context: context,
                  initialDate: selectedDate,
                );
                if (date != null) {
                  setState(() {
                    selectedDate = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground,
                  borderRadius: AppColors.borderRadiusAll,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('d MMMM yyyy').format(selectedDate)),
                    const Icon(Icons.calendar_today, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Saat seçimi
            Text(LocaleKeys.Time.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final time = await Helper().selectTime(
                  context,
                  initialTime: selectedTime,
                );
                if (time != null) {
                  setState(() {
                    selectedTime = time;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground,
                  borderRadius: AppColors.borderRadiusAll,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedTime.format(context)),
                    const Icon(Icons.access_time, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Durum seçimi
            Text(LocaleKeys.Status.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskStatusEnum>(
              value: selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: TaskStatusEnum.COMPLETED,
                  child: Text(LocaleKeys.Completed.tr()),
                ),
                DropdownMenuItem(
                  value: TaskStatusEnum.FAILED,
                  child: Text(LocaleKeys.Failed.tr()),
                ),
                DropdownMenuItem(
                  value: TaskStatusEnum.CANCEL,
                  child: Text(LocaleKeys.Cancelled.tr()),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedStatus = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // İlerleme girişi (task tipine göre)
            if (widget.taskModel.type != TaskTypeEnum.CHECKBOX) Text(LocaleKeys.Progress.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (widget.taskModel.type == TaskTypeEnum.COUNTER)
              // Counter için sayı girişi
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: LocaleKeys.EnterCount.tr(),
                  border: const OutlineInputBorder(),
                ),
                controller: TextEditingController(text: count?.toString() ?? ""),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      count = int.tryParse(value);
                    });
                  }
                },
              )
            else if (widget.taskModel.type == TaskTypeEnum.TIMER)
              // Timer için saat ve dakika girişi
              Row(
                children: [
                  // Saat
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: LocaleKeys.Hours.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: hours.toString()),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            hours = int.tryParse(value) ?? 0;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Dakika
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: LocaleKeys.Minutes.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: minutes.toString()),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            minutes = int.tryParse(value) ?? 0;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.Cancel.tr()),
        ),
        ElevatedButton(
          onPressed: () async {
            // Log güncelle
            await _updateLog();
            if (mounted) {
              Navigator.of(context).pop(true); // true döndürerek başarılı olduğunu belirtelim
            }
          },
          child: Text(LocaleKeys.Save.tr()),
        ),
        TextButton(
          onPressed: () async {
            // Log sil
            await _deleteLog();
            if (mounted) {
              Navigator.of(context).pop(true); // true döndürerek başarılı olduğunu belirtelim
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(LocaleKeys.Delete.tr()),
        ),
      ],
    );
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
    logModel.status = selectedStatus;

    await HiveService().addTaskLog(logModel);

    // Provider'ı güncelle
    await TaskLogProvider().loadTaskLogs();
  }

  Future<void> _deleteLog() async {
    // Log sil
    await HiveService().deleteTaskLog(logModel.id);

    // Provider'ı güncelle
    await TaskLogProvider().loadTaskLogs();
  }
}
