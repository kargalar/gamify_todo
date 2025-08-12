import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddManualLogDialog extends StatefulWidget {
  final TaskModel taskModel;

  const AddManualLogDialog({
    super.key,
    required this.taskModel,
  });

  @override
  State<AddManualLogDialog> createState() => _AddManualLogDialogState();
}

class _AddManualLogDialogState extends State<AddManualLogDialog> {
  late DateTime selectedDate = DateTime.now();
  late TimeOfDay selectedTime = TimeOfDay.now();

  // Progress değerleri
  int? count;
  int hours = 0;
  int minutes = 0;

  // Durum değeri
  TaskStatusEnum selectedStatus = TaskStatusEnum.DONE;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocaleKeys.AddManualLog.tr()),
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

            // Durum seçimi (sadece checkbox için)
            if (widget.taskModel.type == TaskTypeEnum.CHECKBOX) Text(LocaleKeys.Status.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            if (widget.taskModel.type == TaskTypeEnum.CHECKBOX) const SizedBox(height: 8),
            if (widget.taskModel.type == TaskTypeEnum.CHECKBOX)
              DropdownButtonFormField<TaskStatusEnum>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: TaskStatusEnum.DONE,
                    child: Text(LocaleKeys.Done.tr()),
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

            if (widget.taskModel.type == TaskTypeEnum.CHECKBOX) const SizedBox(height: 16),

            const SizedBox(height: 16),

            // İlerleme girişi (task tipine göre)
            if (widget.taskModel.type != TaskTypeEnum.CHECKBOX) Text(LocaleKeys.Progress.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            if (widget.taskModel.type != TaskTypeEnum.CHECKBOX) const SizedBox(height: 8),

            if (widget.taskModel.type == TaskTypeEnum.COUNTER)
              // Counter için sayı girişi
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: LocaleKeys.EnterCount.tr(),
                  border: const OutlineInputBorder(),
                ),
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
            // Log oluştur
            await _addManualLog();
            if (context.mounted) {
              Navigator.of(context).pop(true); // true döndürerek başarılı olduğunu belirtelim
            }
          },
          child: Text(LocaleKeys.Add.tr()),
        ),
      ],
    );
  }

  Future<void> _addManualLog() async {
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

      // Timer için son loglanan süreyi SharedPreferences'a kaydet
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('last_logged_duration_${widget.taskModel.id}', duration.inSeconds.toString());
    } else if (widget.taskModel.type == TaskTypeEnum.COUNTER) {
      countValue = count;
    }

    // Log oluştur - manuel girilen değer doğrudan log olarak kaydedilir
    // Status sadece checkbox için kullanılır, timer ve counter için otomatik COMPLETED
    TaskStatusEnum logStatus = widget.taskModel.type == TaskTypeEnum.CHECKBOX ? selectedStatus : TaskStatusEnum.DONE;

    await TaskLogProvider().addTaskLog(
      widget.taskModel,
      customLogDate: logDateTime,
      customDuration: duration, // Manuel girilen süre doğrudan log olarak kaydedilir
      customCount: countValue, // Manuel girilen sayı doğrudan log olarak kaydedilir
      customStatus: logStatus,
    );
  }
}
