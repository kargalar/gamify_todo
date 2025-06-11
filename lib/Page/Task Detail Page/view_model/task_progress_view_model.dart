import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/store_item_log_model.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/notification_helper.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/app_helper.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskProgressViewModel extends ChangeNotifier {
  final TaskModel? taskModel;
  final ItemModel? itemModel;
  final TaskLogProvider taskLogProvider;
  // Store item logları için basit in-memory storage (gerçek uygulamada database kullanılmalı)
  static final List<StoreItemLog> _storeItemLogs = [];
  // Store item log ekleme metodu (public static)
  static void addStoreItemLog({
    required int itemId,
    required String action,
    required dynamic value,
    required TaskTypeEnum type,
  }) {
    _addStoreItemLog(
      itemId: itemId,
      action: action,
      value: value,
      type: type,
    );
  }

  // Store item log ekleme metodu (private)
  static void _addStoreItemLog({
    required int itemId,
    required String action,
    required dynamic value,
    required TaskTypeEnum type,
  }) {
    final log = StoreItemLog(
      itemId: itemId,
      logDate: DateTime.now(),
      action: action,
      value: value,
      type: type,
    );
    _storeItemLogs.add(log);

    // En fazla 50 log tut (memory management için)
    if (_storeItemLogs.length > 50) {
      _storeItemLogs.removeRange(0, _storeItemLogs.length - 50);
    }
  }

  // Store item loglarını getirme metodu
  static List<StoreItemLog> getStoreItemLogs(int itemId) {
    // Sadece o item'a ait logları filtrele
    return _storeItemLogs.where((log) => log.itemId == itemId).toList().reversed.toList(); // En yeni log en üstte
  }

  // Store item log düzenleme metodu
  static void editStoreItemLog(int index, dynamic newValue) {
    if (index >= 0 && index < _storeItemLogs.length) {
      // Ters çevrilmiş listede index'i düzelt
      int actualIndex = _storeItemLogs.length - 1 - index;
      _storeItemLogs[actualIndex] = StoreItemLog(
        itemId: _storeItemLogs[actualIndex].itemId,
        logDate: _storeItemLogs[actualIndex].logDate,
        action: _storeItemLogs[actualIndex].action,
        value: newValue,
        type: _storeItemLogs[actualIndex].type,
      );
    }
  }

  // Store item log silme metodu
  static void deleteStoreItemLog(int index) {
    if (index >= 0 && index < _storeItemLogs.length) {
      // Ters çevrilmiş listede index'i düzelt
      int actualIndex = _storeItemLogs.length - 1 - index;
      _storeItemLogs.removeAt(actualIndex);
    }
  }

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
  int get currentCount => isTask ? (taskModel!.currentCount ?? 0) : (itemModel!.currentCount ?? 0);
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
        int newCount = value as int;
        taskModel!.currentCount = newCount;

        // Calculate progress difference for credit adjustment
        int difference = newCount - previousCount;
        progressDifference = taskModel!.remainingDuration! * difference ~/ taskModel!.targetCount!;
      } else {
        Duration previousDuration = taskModel!.currentDuration ?? Duration.zero;
        Duration newDuration = value as Duration;
        taskModel!.currentDuration = newDuration;

        // Calculate progress difference for credit adjustment
        progressDifference = newDuration - previousDuration;
      }

      // Sunucuya güncelleme gönder
      ServerManager().updateTask(taskModel: taskModel!);

      // Kredi ekle
      AppHelper().addCreditByProgress(progressDifference);

      // Ana sayfadaki görev sayısını güncelle
      HomeWidgetService.updateTaskCount(); // TaskProvider'ı güncelle (ana sayfadaki görev ilerlemesini güncellemek için)
      TaskProvider().updateItems();
    } else {
      // Store item için tip kontrolü yap (log artık setCount/setDuration'da kaydediliyor)
      if (itemModel!.type == TaskTypeEnum.COUNTER) {
        itemModel!.currentCount = (value as num).toInt();
      } else {
        itemModel!.currentDuration = value as Duration;
      }
      ServerManager().updateItem(itemModel: itemModel!);
    }

    notifyListeners();
  }

  void setDuration(Duration value, {bool skipLogging = false}) {
    // Önceki değeri kaydet
    Duration previousDuration = isTask ? (taskModel!.currentDuration ?? Duration.zero) : (itemModel!.currentDuration ?? Duration.zero);

    // Timer durumunu kontrol et
    bool isTimerActive = isTask && taskModel!.isTimerActive == true;

    // Timer aktifse, güncel değeri almak için SharedPreferences'dan timer başlangıç zamanını ve süresini al
    if (isTimerActive && isTask) {
      // Asenkron işlemi senkron hale getir
      _updateTimerDuration(value, previousDuration, skipLogging: skipLogging);
    } else {
      // Timer aktif değilse normal işlemi yap
      if (isTask) {
        // Kullanıcının yaptığı değişikliği hesapla
        Duration userChange = value - previousDuration;

        if (value >= taskModel!.remainingDuration! && taskModel!.status != TaskStatusEnum.COMPLETED) {
          // Clear any existing status before setting to COMPLETED
          taskModel!.status = TaskStatusEnum.COMPLETED;
        } else if (value < taskModel!.remainingDuration! && taskModel!.status == TaskStatusEnum.COMPLETED) {
          taskModel!.status = null;
        }

        // Kullanıcı gerçekten bir değişiklik yaptıysa ve logging atlanmayacaksa log oluştur
        if (userChange.inSeconds != 0 && !skipLogging) {
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
        // Store item için
        Duration userChange = value - previousDuration;

        // Store item için log oluştur (sadece değişiklik varsa ve logging atlanmıyorsa)
        if (userChange.inSeconds != 0 && !skipLogging) {
          _addStoreItemLog(
            itemId: itemModel!.id,
            action: "Manual Entry",
            value: userChange, // Değişiklik miktarını kaydet
            type: itemModel!.type,
          );
        }

        itemModel!.currentDuration = value;
        NotificationHelper.checkAndUpdateNotificationStatusForStoreItem(itemModel!);
      }
    }

    // taskModel'in değerini updateProgress metodunda güncelleyeceğiz
    updateProgress(value);
  }

  // Timer aktifken süre güncellemesi için yardımcı metot
  Future<void> _updateTimerDuration(Duration value, Duration previousDuration, {bool skipLogging = false}) async {
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

      if (userChange.inSeconds != 0 && !skipLogging) {
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
      } else if (userChange.inSeconds != 0 && skipLogging) {
        // Logging atlanıyorsa sadece timer değerini güncelle
        await prefs.setString('timer_start_duration_${taskModel!.id}', (timerStartDuration + userChange).inSeconds.toString());

        // UI'ı güncelle
        notifyListeners();
      }
    }
  }

  void setCount(int value, {bool skipLogging = false}) {
    // Önceki değeri kaydet
    int previousCount = isTask ? (taskModel!.currentCount ?? 0) : (itemModel!.currentCount ?? 0);

    if (isTask) {
      // Kullanıcının yaptığı değişikliği hesapla
      int userChange = value - previousCount;

      if (value >= taskModel!.targetCount! && taskModel!.status != TaskStatusEnum.COMPLETED) {
        // Clear any existing status before setting to COMPLETED
        taskModel!.status = TaskStatusEnum.COMPLETED;
      } else if (value < taskModel!.targetCount! && taskModel!.status == TaskStatusEnum.COMPLETED) {
        taskModel!.status = null;
      }

      // Kullanıcı gerçekten bir değişiklik yaptıysa ve logging atlanmayacaksa log oluştur
      if (userChange != 0 && !skipLogging) {
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
      // Store item için
      int userChange = value - previousCount;

      // Store item için log oluştur (sadece değişiklik varsa ve logging atlanmıyorsa)
      if (userChange != 0 && !skipLogging) {
        _addStoreItemLog(
          itemId: itemModel!.id,
          action: "Manual Entry",
          value: userChange, // Değişiklik miktarını kaydet
          type: itemModel!.type,
        );
      }

      itemModel!.currentCount = value;
      ServerManager().updateItem(itemModel: itemModel!);
    }

    updateProgress(value);
  }

  void setBatchCount(int totalChange) {
    if (totalChange == 0) return;

    if (isTask) {
      // Task için mevcut batch logging mantığı
      // Önceki değeri hesapla
      int previousCount = taskModel!.currentCount ?? 0;
      int newValue = previousCount + totalChange;

      // Yeni değeri ayarla
      taskModel!.currentCount = newValue;

      // Status kontrolü
      if (newValue >= taskModel!.targetCount! && taskModel!.status != TaskStatusEnum.COMPLETED) {
        taskModel!.status = TaskStatusEnum.COMPLETED;
      } else if (newValue < taskModel!.targetCount! && taskModel!.status == TaskStatusEnum.COMPLETED) {
        taskModel!.status = null;
      }

      // Kredi hesapla ve ekle - batch değişiklik için
      Duration creditPerIncrement = taskModel!.remainingDuration! ~/ taskModel!.targetCount!;
      AppHelper().addCreditByProgress(creditPerIncrement * totalChange);

      // Tek bir batch log oluştur
      final selectedDate = TaskProvider().selectedDate;
      final now = DateTime.now();

      taskLogProvider.addTaskLog(
        taskModel!,
        customLogDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, now.hour, now.minute, now.second, now.millisecond),
        customCount: totalChange, // Toplam değişikliği logla
        customStatus: newValue >= taskModel!.targetCount! ? TaskStatusEnum.COMPLETED : null,
      );

      updateProgress(newValue);
    } else {
      // Store item için basit güncelleme (logging yok)
      int previousCount = itemModel!.currentCount ?? 0;
      int newValue = previousCount + totalChange;

      itemModel!.currentCount = newValue;
      ServerManager().updateItem(itemModel: itemModel!);
      updateProgress(newValue);
    }
  }

  void setBatchDuration(Duration totalChange) {
    if (totalChange == Duration.zero) return;

    if (isTask) {
      // Task için mevcut batch logging mantığı
      // Önceki değeri hesapla
      Duration previousDuration = taskModel!.currentDuration ?? Duration.zero;
      Duration newValue = previousDuration + totalChange;

      // Yeni değeri ayarla
      taskModel!.currentDuration = newValue;

      // Status kontrolü
      if (newValue >= taskModel!.remainingDuration! && taskModel!.status != TaskStatusEnum.COMPLETED) {
        taskModel!.status = TaskStatusEnum.COMPLETED;
      } else if (newValue < taskModel!.remainingDuration! && taskModel!.status == TaskStatusEnum.COMPLETED) {
        taskModel!.status = null;
      }

      // Kredi ekle - batch değişiklik için
      AppHelper().addCreditByProgress(totalChange);

      // Tek bir batch log oluştur
      final selectedDate = TaskProvider().selectedDate;
      final now = DateTime.now();

      taskLogProvider.addTaskLog(
        taskModel!,
        customLogDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, now.hour, now.minute, now.second, now.millisecond),
        customDuration: totalChange, // Toplam değişikliği logla
        customStatus: newValue >= taskModel!.remainingDuration! ? TaskStatusEnum.COMPLETED : null,
      );

      updateProgress(newValue);
    } else {
      // Store item için basit güncelleme (logging yok)
      Duration previousDuration = itemModel!.currentDuration ?? Duration.zero;
      Duration newValue = previousDuration + totalChange;

      itemModel!.currentDuration = newValue;
      ServerManager().updateItem(itemModel: itemModel!);
      updateProgress(newValue);
    }
  }
}
