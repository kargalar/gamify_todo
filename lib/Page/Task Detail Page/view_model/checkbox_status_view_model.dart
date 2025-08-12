import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/app_helper.dart';
import 'package:next_level/Service/server_manager.dart';

class CheckboxStatusViewModel extends ChangeNotifier {
  final TaskModel taskModel;
  final TaskLogProvider taskLogProvider;

  CheckboxStatusViewModel({
    required this.taskModel,
    required this.taskLogProvider,
  });

  TaskStatusEnum? get currentStatus => taskModel.status;

  void updateStatus(TaskStatusEnum? newStatus) {
    // Store the previous status for credit calculation
    final TaskStatusEnum? previousStatus = taskModel.status;

    // TaskProvider'dan seçili tarihi al
    final selectedDate = TaskProvider().selectedDate;
    final now = DateTime.now();
    final customLogDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, now.hour, now.minute, now.second, now.millisecond);

    // Eğer zaten seçili durum tıklanırsa, durumu kontrol et
    if (taskModel.status == newStatus) {
      // Check if task should be overdue based on date when toggling status
      if (taskModel.taskDate != null) {
        final now = DateTime.now();
        final taskDateTime = taskModel.taskDate!.copyWith(
          hour: taskModel.time?.hour ?? 23,
          minute: taskModel.time?.minute ?? 59,
          second: 59,
        );

        if (taskDateTime.isBefore(now)) {
          // Task date is in the past, mark as overdue
          taskModel.status = TaskStatusEnum.OVERDUE;

          // Log oluştur (overdue durumu olarak)
          taskLogProvider.addTaskLog(
            taskModel,
            customLogDate: customLogDate,
            customStatus: TaskStatusEnum.OVERDUE,
          );
        } else {
          // Task date is in the future or today, set to null (in progress)
          taskModel.status = null;

          // Log oluştur (durumu null olarak)
          taskLogProvider.addTaskLog(
            taskModel,
            customLogDate: customLogDate,
            customStatus: null,
          );
        }
      } else {
        // Dateless task, set to null (in progress)
        taskModel.status = null;

        // Log oluştur (durumu null olarak)
        taskLogProvider.addTaskLog(
          taskModel,
          customLogDate: customLogDate,
          customStatus: null,
        );
      }

      // Credit adjustment: if task was completed before, subtract credit
      if (previousStatus == TaskStatusEnum.DONE && taskModel.remainingDuration != null) {
        AppHelper().addCreditByProgress(-taskModel.remainingDuration!);
      }
    } else {
      // Set new status, clearing any previous status
      taskModel.status = newStatus;

      // Credit adjustment based on status change
      if (taskModel.remainingDuration != null) {
        // If previously completed, subtract the credit first
        if (previousStatus == TaskStatusEnum.DONE) {
          AppHelper().addCreditByProgress(-taskModel.remainingDuration!);
        }

        // If new status is completed, add credit
        if (newStatus == TaskStatusEnum.DONE) {
          // Add haptic feedback when completing a checkbox task
          HapticFeedback.lightImpact();

          AppHelper().addCreditByProgress(taskModel.remainingDuration!);
        }
      }

      // Log oluştur (yeni durumu kaydeder veya mevcut logu günceller)
      taskLogProvider.addTaskLog(
        taskModel,
        customLogDate: customLogDate,
        customStatus: newStatus,
      );
    }

    // Sunucuya güncelleme gönder
    ServerManager().updateTask(taskModel: taskModel);

    // TaskProvider'ı güncelle (ana sayfadaki görev durumunu güncellemek için)
    TaskProvider().updateItems();

    // ViewModel'i güncelle
    notifyListeners();
  }
}
