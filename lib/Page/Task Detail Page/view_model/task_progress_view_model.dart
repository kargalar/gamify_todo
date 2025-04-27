import 'package:flutter/material.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/store_item_model.dart';
import 'package:gamify_todo/Model/task_log_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Page/Task%20Detail%20Page/widget/notification_helper.dart';
import 'package:gamify_todo/Provider/task_log_provider.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Service/app_helper.dart';
import 'package:gamify_todo/Service/home_widget_service.dart';
import 'package:gamify_todo/Service/server_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskProgressViewModel extends ChangeNotifier {
  final TaskModel? taskModel;
  final ItemModel? itemModel;
  final TaskLogProvider taskLogProvider;

  TaskProgressViewModel({
    this.taskModel,
    this.itemModel,
    required this.taskLogProvider,
  }) {
    if (isTask) {
      // Widget oluşturulduğunda loglardan ilerleme değerlerini al
      updateProgressFromLogs();

      // TaskLogProvider'ı dinle
      taskLogProvider.addListener(_onTaskLogChanged);
    }
  }

  @override
  void dispose() {
    if (isTask) {
      // Listener'ı kaldır
      taskLogProvider.removeListener(_onTaskLogChanged);
    }
    super.dispose();
  }

  // Yardımcı getter'lar
  bool get isTask => taskModel != null;
  TaskTypeEnum get type => isTask ? taskModel!.type : itemModel!.type;
  int get currentCount => isTask ? taskModel!.currentCount! : itemModel!.currentCount!;
  Duration? get currentDuration => isTask ? taskModel!.currentDuration : itemModel!.currentDuration;
  Duration? get targetDuration => isTask ? taskModel!.remainingDuration : itemModel!.addDuration;

  void _onTaskLogChanged() {
    // TaskLogProvider değiştiğinde ilerleme değerlerini güncelle
    updateProgressFromLogs();
  }

  Future<void> updateProgressFromLogs() async {
    if (!isTask) return;

    // Task için logları al
    List<TaskLogModel> logs = taskLogProvider.getLogsByTaskId(taskModel!.id);

    // TaskProvider'dan seçili tarihi al
    final selectedDate = TaskProvider().selectedDate;
    final selectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    // Sadece seçili tarihe ait logları filtrele
    List<TaskLogModel> filteredLogs = logs.where((log) {
      final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
      return logDate.isAtSameMomentAs(selectedDay); // Sadece seçili tarih
    }).toList();

    // Toplam ilerlemeyi hesapla
    int totalCount = 0;
    Duration totalDuration = Duration.zero;

    // Checkbox için en son durumu al (en yeni log)
    if (taskModel!.type == TaskTypeEnum.CHECKBOX && filteredLogs.isNotEmpty) {
      // Logları tarihe göre sırala (en yenisi en üstte)
      filteredLogs.sort((a, b) => b.logDate.compareTo(a.logDate));

      // En yeni log (ilk eleman)
      TaskLogModel latestLog = filteredLogs.first;

      // Task durumunu güncelle
      taskModel!.status = latestLog.status;
    }

    // Tüm logları işle ve toplam değeri hesapla
    for (var log in filteredLogs) {
      if (taskModel!.type == TaskTypeEnum.TIMER && log.duration != null) {
        // Her log kendi başına bir artış olarak değerlendirilir
        totalDuration += log.duration!;
      } else if (taskModel!.type == TaskTypeEnum.COUNTER && log.count != null) {
        // Her log kendi başına bir artış olarak değerlendirilir
        totalCount += log.count!;
      }
    }

    // Aktif timer varsa, şu anki timer değerini de ekle
    if (taskModel!.type == TaskTypeEnum.TIMER && taskModel!.isTimerActive == true) {
      // SharedPreferences'dan timer başlangıç zamanını al
      final prefs = await SharedPreferences.getInstance();
      String? timerStartTimeStr = prefs.getString('timer_start_time_${taskModel!.id}');
      String? timerStartDurationStr = prefs.getString('timer_start_duration_${taskModel!.id}');

      if (timerStartTimeStr != null && timerStartDurationStr != null) {
        // Timer başlangıç zamanını hesapla
        DateTime timerStartTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timerStartTimeStr));
        Duration timerStartDuration = Duration(seconds: int.parse(timerStartDurationStr));

        // Timer çalışma süresini hesapla (şu anki zaman - başlangıç zamanı)
        Duration timerRunDuration = DateTime.now().difference(timerStartTime);

        // Toplam süreyi hesapla (başlangıç değeri + geçen süre)
        totalDuration = timerStartDuration + timerRunDuration;
      }
    }

    // Task tipine göre ilerleme değerini güncelle
    if (taskModel!.type == TaskTypeEnum.TIMER) {
      taskModel!.currentDuration = totalDuration;
    } else if (taskModel!.type == TaskTypeEnum.COUNTER) {
      taskModel!.currentCount = totalCount;
    }

    // Sunucuya güncelleme gönder
    ServerManager().updateTask(taskModel: taskModel!);

    // TaskProvider'ı güncelle (ana sayfadaki görev ilerlemesini güncellemek için)
    TaskProvider().updateItems();

    // ViewModel'i güncelle
    notifyListeners();
  }

  void updateProgress(dynamic value) {
    if (isTask) {
      late Duration progressDifference;
      if (taskModel!.type == TaskTypeEnum.COUNTER) {
        int previousCount = taskModel!.currentCount ?? 0;
        taskModel!.currentCount = value;

        // Calculate progress difference for credit adjustment
        int difference = value - previousCount;
        progressDifference = taskModel!.remainingDuration! * difference ~/ taskModel!.targetCount!;
      } else {
        Duration previousDuration = taskModel!.currentDuration ?? Duration.zero;
        taskModel!.currentDuration = value;

        // Calculate progress difference for credit adjustment
        progressDifference = value - previousDuration;
      }

      // Sunucuya güncelleme gönder
      ServerManager().updateTask(taskModel: taskModel!);

      // Kredi ekle
      AppHelper().addCreditByProgress(progressDifference);

      // Ana sayfadaki görev sayısını güncelle
      HomeWidgetService.updateTaskCount();

      // TaskProvider'ı güncelle (ana sayfadaki görev ilerlemesini güncellemek için)
      TaskProvider().updateItems();
    } else {
      itemModel!.currentCount = value;
      ServerManager().updateItem(itemModel: itemModel!);
    }

    notifyListeners();
  }

  void setDuration(Duration value) {
    // Önceki değeri kaydet
    Duration previousDuration = isTask ? (taskModel!.currentDuration ?? Duration.zero) : Duration.zero;

    // Timer durumunu kontrol et
    bool isTimerActive = isTask && taskModel!.isTimerActive == true;

    // Timer aktifse, güncel değeri almak için SharedPreferences'dan timer başlangıç zamanını ve süresini al
    if (isTimerActive && isTask) {
      // Asenkron işlemi senkron hale getir
      _updateTimerDuration(value, previousDuration);
    } else {
      // Timer aktif değilse normal işlemi yap
      if (isTask) {
        // Kullanıcının yaptığı değişikliği hesapla
        Duration userChange = value - previousDuration;

        if (value >= taskModel!.remainingDuration! && taskModel!.status != TaskStatusEnum.COMPLETED) {
          taskModel!.status = TaskStatusEnum.COMPLETED;
        } else if (value < taskModel!.remainingDuration! && taskModel!.status == TaskStatusEnum.COMPLETED) {
          taskModel!.status = null;
        }

        // Kullanıcı gerçekten bir değişiklik yaptıysa log oluştur
        if (userChange.inSeconds != 0) {
          // TaskProvider'dan seçili tarihi al
          final selectedDate = TaskProvider().selectedDate;

          // Sadece kullanıcının yaptığı değişikliği logla
          taskLogProvider.addTaskLog(
            taskModel!,
            customLogDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, DateTime.now().hour, DateTime.now().minute, DateTime.now().second, DateTime.now().millisecond),
            customDuration: userChange,
            customStatus: value >= taskModel!.remainingDuration! ? TaskStatusEnum.COMPLETED : null,
          );

          // Son loglanan süreyi SharedPreferences'a kaydet
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('last_logged_duration_${taskModel!.id}', value.inSeconds.toString());
          });
        }

        NotificationHelper.checkAndUpdateNotificationStatusForTask(taskModel!);
      } else {
        itemModel!.currentDuration = value;
        NotificationHelper.checkAndUpdateNotificationStatusForStoreItem(itemModel!);
      }
    }

    // taskModel'in değerini updateProgress metodunda güncelleyeceğiz
    updateProgress(value);
  }

  // Timer aktifken süre güncellemesi için yardımcı metot
  Future<void> _updateTimerDuration(Duration value, Duration previousDuration) async {
    // SharedPreferences'ı al
    final prefs = await SharedPreferences.getInstance();

    // Timer başlangıç zamanı ve süresini al
    String? timerStartTimeStr = prefs.getString('timer_start_time_${taskModel!.id}');
    String? timerStartDurationStr = prefs.getString('timer_start_duration_${taskModel!.id}');

    if (timerStartTimeStr != null && timerStartDurationStr != null) {
      // Timer başlangıç zamanını hesapla
      DateTime timerStartTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timerStartTimeStr));

      // Timer çalışma süresini hesapla (şu anki zaman - başlangıç zamanı)
      Duration timerRunDuration = DateTime.now().difference(timerStartTime);

      // Timer başlangıç değerini al
      Duration timerStartDuration = Duration(seconds: int.parse(timerStartDurationStr));

      // Toplam süreyi hesapla
      Duration currentDuration = timerStartDuration + timerRunDuration;

      // Kullanıcının yaptığı değişikliği hesapla
      Duration userChange = value - currentDuration;

      // eğer pozitif veya 0 ise bir saniye ekle
      if (userChange.inSeconds > 0 || userChange.inSeconds == 0) {
        userChange += const Duration(seconds: 1);
      }

      if (userChange.inSeconds != 0) {
        // Timer başlangıç değerini güncelle (yeni değer = eski başlangıç değeri + kullanıcının yaptığı değişiklik)
        await prefs.setString('timer_start_duration_${taskModel!.id}', (timerStartDuration + userChange).inSeconds.toString());

        // Timer aktifken de log oluştur
        final selectedDate = TaskProvider().selectedDate;
        final now = DateTime.now();

        // Sadece kullanıcının yaptığı değişikliği logla
        await taskLogProvider.addTaskLog(
          taskModel!,
          customLogDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, now.hour, now.minute, now.second, now.millisecond),
          customDuration: userChange,
          customStatus: null, // Timer aktifken status değişmez
        );

        // UI'ı güncelle
        notifyListeners();
      }
    }
  }

  void setCount(int value) {
    // Önceki değeri kaydet
    int previousCount = isTask ? (taskModel!.currentCount ?? 0) : 0;

    if (isTask) {
      // Kullanıcının yaptığı değişikliği hesapla
      int userChange = value - previousCount;

      if (value >= taskModel!.targetCount! && taskModel!.status != TaskStatusEnum.COMPLETED) {
        taskModel!.status = TaskStatusEnum.COMPLETED;
      } else if (value < taskModel!.targetCount! && taskModel!.status == TaskStatusEnum.COMPLETED) {
        taskModel!.status = null;
      }

      // Kullanıcı gerçekten bir değişiklik yaptıysa log oluştur
      if (userChange != 0) {
        // TaskProvider'dan seçili tarihi al
        final selectedDate = TaskProvider().selectedDate;
        final now = DateTime.now();

        taskLogProvider.addTaskLog(
          taskModel!,
          customLogDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, now.hour, now.minute, now.second, now.millisecond),
          customCount: userChange, // Sadece kullanıcının yaptığı değişikliği logla
          customStatus: value >= taskModel!.targetCount! ? TaskStatusEnum.COMPLETED : null,
        );
      }
    } else {
      itemModel!.currentCount = value;
    }

    updateProgress(value);
  }
}
