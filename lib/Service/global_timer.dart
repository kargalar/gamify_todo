import 'dart:async';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/Service/app_helper.dart';
import 'package:gamify_todo/Service/home_widget_service.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Service/notification_services.dart';
import 'package:gamify_todo/Service/server_manager.dart';
import 'package:gamify_todo/Provider/store_provider.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Provider/task_log_provider.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Model/store_item_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class GlobalTimer {
  static final GlobalTimer _instance = GlobalTimer._internal();
  factory GlobalTimer() => _instance;
  GlobalTimer._internal();

  Timer? _timer;

  void startStopTimer({
    TaskModel? taskModel,
    ItemModel? storeItemModel,
  }) async {
    if (taskModel != null) {
      // Timer durumunu değiştir
      bool newTimerState = !taskModel.isTimerActive!;
      taskModel.isTimerActive = newTimerState;

      // Timer başlatıldığında zamanı kaydet
      final prefs = await SharedPreferences.getInstance();
      if (newTimerState) {
        // Önce mevcut timer bildirimini iptal et
        NotificationService().cancelNotificationOrAlarm(-taskModel.id);

        // Timer başlatılıyor
        NotificationService().showTimerNotification(
          id: taskModel.id,
          currentDuration: taskModel.currentDuration!,
          remainingDuration: taskModel.remainingDuration!,
          title: taskModel.title,
          isCountDown: false,
        );

        // Timer başlangıç zamanını kaydet
        prefs.setString('timer_start_time_${taskModel.id}', DateTime.now().millisecondsSinceEpoch.toString());
        prefs.setString('timer_start_duration_${taskModel.id}', taskModel.currentDuration!.inSeconds.toString());

        // Son güncelleme zamanını kaydet
        prefs.setString('task_last_update_${taskModel.id}', DateTime.now().toIso8601String());
        prefs.setString('task_last_progress_${taskModel.id}', taskModel.currentDuration!.inSeconds.toString());

        // Bildirim ayarla
        if (taskModel.status != TaskStatusEnum.COMPLETED) {
          // Tamamlanma zamanı için bildirim planla
          final scheduledDate = DateTime.now().add(taskModel.remainingDuration! - taskModel.currentDuration!);
          NotificationService().scheduleNotification(
            id: taskModel.id + 100000,
            title: LocaleKeys.task_completed_title.tr(args: [taskModel.title]),
            desc: LocaleKeys.task_completed_desc.tr(args: [taskModel.remainingDuration!.textLongDynamicWithoutZero()]),
            scheduledDate: scheduledDate,
            isAlarm: true,
          );
        } else {
          // Task zaten tamamlanmış, ancak timer hala çalışabilir
          // Bildirim gösterme, sadece timer'ı çalıştır
        }
      } else {
        // Timer durduruluyor
        // Timer çalışma süresini hesapla ve log oluştur
        String? timerStartTimeStr = prefs.getString('timer_start_time_${taskModel.id}');
        String? timerStartDurationStr = prefs.getString('timer_start_duration_${taskModel.id}');

        if (timerStartTimeStr != null && timerStartDurationStr != null) {
          // Timer başlangıç zamanını hesapla
          DateTime timerStartTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timerStartTimeStr));

          // Timer çalışma süresini hesapla (şu anki zaman - başlangıç zamanı)
          Duration timerRunDuration = DateTime.now().difference(timerStartTime);

          // Timer başlangıç değerini al
          Duration timerStartDuration = Duration(seconds: int.parse(timerStartDurationStr));

          // Sadece pozitif değişimleri logla
          if (timerRunDuration.inSeconds > 0) {
            // Timer çalışma süresini taskModel'e kaydet
            taskModel.currentDuration = timerStartDuration + timerRunDuration;

            // Timer durdurulduğunda log oluştur
            // Tam zamanı kaydet
            final now = DateTime.now();
            TaskLogProvider().addTaskLog(
              taskModel,
              customLogDate: DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second, now.millisecond),
              customDuration: timerRunDuration, // Sadece timer çalışma süresini logla
            );
          }

          // Timer bilgilerini temizle
          prefs.remove('timer_start_time_${taskModel.id}');
          prefs.remove('timer_start_duration_${taskModel.id}');
          prefs.remove('task_last_update_${taskModel.id}');
          prefs.remove('task_last_progress_${taskModel.id}');
        }

        // Bildirimleri iptal et
        NotificationService().cancelNotificationOrAlarm(-taskModel.id);
        NotificationService().cancelNotificationOrAlarm(taskModel.id + 100000);
        NotificationService().cancelNotificationOrAlarm(taskModel.id + 200000); // Tamamlanma bildirimini de iptal et
      }

      // Sunucuya güncelleme gönder
      ServerManager().updateTask(taskModel: taskModel);
    } else if (storeItemModel != null) {
      // Store item timer durumunu değiştir
      bool newTimerState = !storeItemModel.isTimerActive!;
      storeItemModel.isTimerActive = newTimerState;

      // Timer başlatıldığında zamanı kaydet
      final prefs = await SharedPreferences.getInstance();
      if (newTimerState) {
        // Önce mevcut timer bildirimini iptal et
        NotificationService().cancelNotificationOrAlarm(-storeItemModel.id);

        // Timer başlatılıyor
        NotificationService().showTimerNotification(
          id: storeItemModel.id,
          currentDuration: storeItemModel.currentDuration!,
          remainingDuration: null,
          title: storeItemModel.title,
          isCountDown: true,
        );

        // Timer başlangıç zamanını kaydet
        final now = DateTime.now();
        prefs.setString('item_last_update_${storeItemModel.id}', now.toIso8601String());
        prefs.setString('item_last_progress_${storeItemModel.id}', storeItemModel.currentDuration!.inSeconds.toString());

        if (storeItemModel.currentDuration!.inSeconds > 0) {
          // Süre dolduğunda bildirim planla
          final scheduledDate = now.add(storeItemModel.currentDuration!);
          NotificationService().scheduleNotification(
            id: storeItemModel.id + 100000,
            title: LocaleKeys.item_expired_title.tr(args: [storeItemModel.title]),
            desc: LocaleKeys.item_expired_desc.tr(),
            scheduledDate: scheduledDate,
            isAlarm: true,
          );
        }
      } else {
        // Timer durduruluyor
        // Timer bilgilerini temizle
        prefs.remove('item_last_update_${storeItemModel.id}');
        prefs.remove('item_last_progress_${storeItemModel.id}');

        // Bildirimleri iptal et
        NotificationService().cancelNotificationOrAlarm(-storeItemModel.id);
        NotificationService().cancelNotificationOrAlarm(storeItemModel.id + 100000);
        NotificationService().cancelNotificationOrAlarm(storeItemModel.id + 200000); // Tamamlanma bildirimini de iptal et
      }

      // Sunucuya güncelleme gönder
      ServerManager().updateItem(itemModel: storeItemModel);
    }

    // Global timer'ı başlat/durdur
    startStopGlobalTimer();
  }

  void startStopGlobalTimer() {
    final bool isAllTimersOff = !TaskProvider().taskList.any((element) => element.isTimerActive != null && element.isTimerActive!) && !StoreProvider().storeItemList.any((element) => element.isTimerActive != null && element.isTimerActive!);

    if (_timer != null && _timer!.isActive && isAllTimersOff) {
      _timer!.cancel();
    } else if (_timer == null || !_timer!.isActive) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) async {
          // SharedPreferences'ı bir kez al
          final prefs = await SharedPreferences.getInstance();

          for (var task in TaskProvider().taskList) {
            if (task.isTimerActive != null && task.isTimerActive == true) {
              // Timer başlangıç zamanını kontrol et
              String? timerStartTimeStr = prefs.getString('timer_start_time_${task.id}');

              if (timerStartTimeStr != null) {
                // Timer başlangıç zamanını hesapla
                DateTime timerStartTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timerStartTimeStr));

                // Timer çalışma süresini hesapla (şu anki zaman - başlangıç zamanı)
                Duration timerRunDuration = DateTime.now().difference(timerStartTime);

                // Timer başlangıç değerini al
                String? timerStartDurationStr = prefs.getString('timer_start_duration_${task.id}');
                Duration timerStartDuration = Duration.zero;
                if (timerStartDurationStr != null) {
                  timerStartDuration = Duration(seconds: int.parse(timerStartDurationStr));
                }

                // Toplam süreyi hesapla
                task.currentDuration = timerStartDuration + timerRunDuration;

                // Her 5 saniyede bir SharedPreferences'ı güncelle
                if (timerRunDuration.inSeconds % 5 == 0) {
                  prefs.setString('task_last_update_${task.id}', DateTime.now().toIso8601String());
                  prefs.setString('task_last_progress_${task.id}', task.currentDuration!.inSeconds.toString());
                }
              } else {
                // Timer başlangıç zamanı yoksa, şimdi oluştur
                prefs.setString('timer_start_time_${task.id}', DateTime.now().millisecondsSinceEpoch.toString());
                prefs.setString('timer_start_duration_${task.id}', task.currentDuration!.inSeconds.toString());

                // Bir saniye ekle
                task.currentDuration = task.currentDuration! + const Duration(seconds: 1);
              }

              // Hedef süreye ulaşıldığında task'ı tamamla ama timer'ı durdurma
              if (task.status != TaskStatusEnum.COMPLETED && task.currentDuration! >= task.remainingDuration!) {
                // Clear any existing status before setting to COMPLETED
                task.status = TaskStatusEnum.COMPLETED;
                HomeWidgetService.updateTaskCount();

                // Timer tamamlandığında bildirim gönder
                NotificationService().showTimerNotification(
                  id: task.id + 200000, // Farklı bir ID kullan
                  title: LocaleKeys.task_completed_title.tr(args: [task.title]),
                  currentDuration: task.currentDuration!,
                  remainingDuration: task.remainingDuration!,
                  isCountDown: false,
                  isCompleted: true, // Mark as completed so it can be dismissed
                );

                // Timer tamamlandığında log oluşturma - sadece timer durdurulduğunda log oluşturulacak
                // Burada log oluşturmuyoruz, çünkü timer durdurulduğunda zaten log oluşturulacak

                // Timer'ı durdurma - kullanıcı isterse durdurabilir
                // task.isTimerActive = false;

                // Zamanlanmış bildirimleri iptal et
                NotificationService().cancelNotificationOrAlarm(task.id + 100000); // Zamanlanmış tamamlanma bildirimi
                // Tamamlanma bildirimini 10 saniye sonra otomatik olarak kaldır
                Future.delayed(const Duration(seconds: 10), () {
                  NotificationService().cancelNotificationOrAlarm(task.id + 200000); // Tamamlanma bildirimi
                });

                // Veritabanını güncelle
                ServerManager().updateTask(taskModel: task);

                // Task Provider'a bildir
                TaskProvider().checkTaskStatusForNotifications(task);
              }

              if (task.currentDuration!.inSeconds % 60 == 0) {
                ServerManager().updateTask(taskModel: task);
                AppHelper().addCreditByProgress(const Duration(seconds: 60));
              }
            }
          }

          for (var storeItem in StoreProvider().storeItemList) {
            if (storeItem.isTimerActive != null && storeItem.isTimerActive == true) {
              storeItem.currentDuration = storeItem.currentDuration! - const Duration(seconds: 1);

              if (storeItem.currentDuration!.inSeconds % 5 == 0) {
                prefs.setString('item_last_update_${storeItem.id}', DateTime.now().toIso8601String());
                prefs.setString('item_last_progress_${storeItem.id}', storeItem.currentDuration!.inSeconds.toString());
              }

              if (storeItem.currentDuration!.inSeconds % 60 == 0) {
                ServerManager().updateItem(itemModel: storeItem);
              }
            }
          }

          // UI'ı güncelle
          TaskProvider().updateItems();
          StoreProvider().setStateItems();
        },
      );
    }
  }

  Future<void> checkSavedTimers() async {
    // Check if any task has an active timer
    final bool hasActiveTimer = TaskProvider().taskList.any((task) => task.isTimerActive == true) || StoreProvider().storeItemList.any((item) => item.isTimerActive == true);

    if (hasActiveTimer) {
      await checkActiveTimerPref();
      startStopGlobalTimer();
    }
  }

  // checkactibvetimerpref
  Future<void> checkActiveTimerPref() async {
    final prefs = await SharedPreferences.getInstance();

    for (var task in TaskProvider().taskList) {
      if (task.isTimerActive == true) {
        final lastUpdateStr = prefs.getString('task_last_update_${task.id}');
        final lastProgressStr = prefs.getString('task_last_progress_${task.id}');

        if (lastUpdateStr != null && lastProgressStr != null) {
          final lastUpdate = DateTime.parse(lastUpdateStr);
          final lastProgress = Duration(seconds: int.parse(lastProgressStr));

          final now = DateTime.now();
          final difference = now.difference(lastUpdate);

          // Ensure we don't add negative time differences
          if (difference.inSeconds > 0) {
            // Son güncelleme ile şimdiki zaman arasındaki farkı ekle
            task.currentDuration = lastProgress + difference;

            // Son güncelleme zamanını güncelle
            await prefs.setString('task_last_update_${task.id}', now.toIso8601String());
            await prefs.setString('task_last_progress_${task.id}', task.currentDuration!.inSeconds.toString());

            // Store the last known foreground timestamp
            await prefs.setString('last_foreground_time', now.toIso8601String());

            ServerManager().updateTask(taskModel: task);
            AppHelper().addCreditByProgress(difference);
          }
        }
      }
      TaskProvider().updateItems();
    }

    for (var storeItem in StoreProvider().storeItemList) {
      if (storeItem.isTimerActive == true) {
        final lastUpdateStr = prefs.getString('item_last_update_${storeItem.id}');
        final lastProgressStr = prefs.getString('item_last_progress_${storeItem.id}');
        if (lastUpdateStr != null && lastProgressStr != null) {
          final lastUpdate = DateTime.parse(lastUpdateStr);
          final lastProgress = Duration(seconds: int.parse(lastProgressStr));

          final now = DateTime.now();
          final difference = now.difference(lastUpdate);

          storeItem.currentDuration = lastProgress - difference;

          ServerManager().updateItem(itemModel: storeItem);
        }
      }
      StoreProvider().setStateItems();
    }
  }
}
