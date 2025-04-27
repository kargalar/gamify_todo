import 'package:flutter/material.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Model/task_log_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Provider/task_log_provider.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Service/server_manager.dart';

class CheckboxStatusViewModel extends ChangeNotifier {
  final TaskModel taskModel;
  final TaskLogProvider taskLogProvider;

  CheckboxStatusViewModel({
    required this.taskModel,
    required this.taskLogProvider,
  });

  TaskStatusEnum? get currentStatus => taskModel.status;

  void updateStatus(TaskStatusEnum? newStatus) {
    // TaskProvider'dan seçili tarihi al
    final selectedDate = TaskProvider().selectedDate;
    final now = DateTime.now();

    // Eğer zaten seçili durum tıklanırsa, durumu sıfırla (null yap)
    if (taskModel.status == newStatus) {
      taskModel.status = null;

      // Son logları kontrol et
      List<TaskLogModel> logs = taskLogProvider.getLogsByTaskId(taskModel.id);

      // Bugüne ait logları filtrele
      logs = logs.where((log) {
        final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
        final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        return logDate.isAtSameMomentAs(today);
      }).toList();

      // Logları tarihe göre sırala (en yenisi en üstte)
      logs.sort((a, b) => b.logDate.compareTo(a.logDate));

      // Son log'un durumu kontrol et
      bool shouldCreateLog = true;
      if (logs.isNotEmpty) {
        TaskLogModel lastLog = logs.first;
        // Eğer son log'un durumu null ise ve şimdi de null yapıyorsak, log oluşturma
        if (lastLog.status == null) {
          shouldCreateLog = false;
        }
      }

      // Log oluştur (durumu null olarak)
      if (shouldCreateLog) {
        taskLogProvider.addTaskLog(
          taskModel,
          customLogDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, now.hour, now.minute, now.second, now.millisecond),
          // Burada null olarak gönderiyoruz - bu, checkbox'ın hiçbir durumunun seçili olmadığını gösterir
          customStatus: null,
        );
      }
    } else {
      // Yeni durum
      taskModel.status = newStatus;

      // Son logları kontrol et
      List<TaskLogModel> logs = taskLogProvider.getLogsByTaskId(taskModel.id);

      // Bugüne ait logları filtrele
      logs = logs.where((log) {
        final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
        final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        return logDate.isAtSameMomentAs(today);
      }).toList();

      // Logları tarihe göre sırala (en yenisi en üstte)
      logs.sort((a, b) => b.logDate.compareTo(a.logDate));

      // Son log'un durumu kontrol et
      bool shouldCreateLog = true;
      if (logs.isNotEmpty) {
        TaskLogModel lastLog = logs.first;
        // Eğer son log'un durumu yeni durum ile aynıysa, log oluşturma
        if (lastLog.status == newStatus) {
          shouldCreateLog = false;
        }
      }

      // Log oluştur
      if (shouldCreateLog) {
        taskLogProvider.addTaskLog(
          taskModel,
          customLogDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, now.hour, now.minute, now.second, now.millisecond),
          customStatus: newStatus,
        );
      }
    }

    // Sunucuya güncelleme gönder
    ServerManager().updateTask(taskModel: taskModel);

    // TaskProvider'ı güncelle (ana sayfadaki görev durumunu güncellemek için)
    TaskProvider().updateItems();

    // ViewModel'i güncelle
    notifyListeners();
  }
}
