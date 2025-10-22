import 'dart:async';
import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Service/app_helper.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class GlobalTimer {
  static final GlobalTimer _instance = GlobalTimer._internal();
  factory GlobalTimer() => _instance;
  GlobalTimer._internal();

  // Bellek içi guard: Aynı oturumda (app çalışırken) aynı item için alarmı tekrar tetiklemeyi engeller
  static final Set<int> _storeItemAlarmTriggeredMemory = <int>{};

  Timer? _timer;

  void startStopTimer({
    TaskModel? taskModel,
    ItemModel? storeItemModel,
    bool suppressStopLog = false, // when stopping due to manual log, don't create extra stop log
  }) async {
    if (taskModel != null) {
      // Timer durumunu değiştir
      bool newTimerState = !(taskModel.isTimerActive ?? false);
      taskModel.isTimerActive = newTimerState;

      // Timer başlatıldığında zamanı kaydet
      final prefs = await SharedPreferences.getInstance();
      if (newTimerState) {
        // Önce mevcut timer bildirimini iptal et
        NotificationService().stopTimerTask(-taskModel.id);

        // Timer başlatılıyor
        NotificationService().showTimerNotification(
          id: taskModel.id,
          currentDuration: taskModel.currentDuration!,
          remainingDuration: taskModel.remainingDuration!,
          title: taskModel.title,
          isCountDown: false,
        );

        // Eski tamamlanma/alarm bildirimlerini temizle (stale kalmasın)
        NotificationService().cancelNotificationOrAlarm(taskModel.id + 100000);
        NotificationService().cancelNotificationOrAlarm(taskModel.id + 200000);

        // Timer başlangıç zamanını kaydet
        prefs.setString('timer_start_time_${taskModel.id}', DateTime.now().millisecondsSinceEpoch.toString());
        prefs.setString('timer_start_duration_${taskModel.id}', taskModel.currentDuration!.inSeconds.toString());

        // Son güncelleme zamanını kaydet
        prefs.setString('task_last_update_${taskModel.id}', DateTime.now().toIso8601String());
        prefs.setString('task_last_progress_${taskModel.id}', taskModel.currentDuration!.inSeconds.toString());

        // Bildirim ayarla (hedef > 0 ve henüz ulaşılmamışsa)
        if (taskModel.status != TaskStatusEnum.DONE) {
          final Duration target = taskModel.remainingDuration ?? Duration.zero;
          final Duration progress = taskModel.currentDuration ?? Duration.zero;
          final Duration delta = target - progress;
          if (target.inSeconds > 0 && delta.inSeconds > 0) {
            // Tamamlanma zamanı için bildirim planla
            final scheduledDate = DateTime.now().add(delta);
            NotificationService().scheduleNotification(
              id: taskModel.id + 100000,
              title: LocaleKeys.task_completed_title.tr(args: [taskModel.title]),
              desc: LocaleKeys.task_completed_desc.tr(args: [target.textLongDynamicWithoutZero()]),
              scheduledDate: scheduledDate,
              isAlarm: true,
            );
          }
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

            // Timer durdurulduğunda log oluştur (isteğe bağlı)
            if (!suppressStopLog) {
              final now = DateTime.now();
              TaskLogProvider().addTaskLog(
                taskModel,
                customLogDate: DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second, now.millisecond),
                customDuration: timerRunDuration, // Sadece timer çalışma süresini logla
              );
            }
          }

          // Timer bilgilerini temizle
          prefs.remove('timer_start_time_${taskModel.id}');
          prefs.remove('timer_start_duration_${taskModel.id}');
          prefs.remove('task_last_update_${taskModel.id}');
          prefs.remove('task_last_progress_${taskModel.id}');
        }

        // Bildirimleri iptal et
        NotificationService().stopTimerTask(-taskModel.id);
        NotificationService().cancelNotificationOrAlarm(taskModel.id + 100000);
        NotificationService().cancelNotificationOrAlarm(taskModel.id + 200000); // Tamamlanma bildirimini de iptal et
      }

      // Sunucuya güncelleme gönder
      ServerManager().updateTask(taskModel: taskModel);

      // Widget'ı güncelle
      HomeWidgetService.updateTaskCount();
    } else if (storeItemModel != null) {
      // Store item timer durumunu değiştir
      bool newTimerState = !(storeItemModel.isTimerActive ?? false);
      storeItemModel.isTimerActive = newTimerState;

      // Timer başlatıldığında zamanı kaydet
      final prefs = await SharedPreferences.getInstance();
      if (newTimerState) {
        // Önce mevcut timer bildirimini iptal et
        NotificationService().stopTimerTask(-storeItemModel.id);

        // Timer başlatılıyor
        NotificationService().showTimerNotification(
          id: storeItemModel.id,
          currentDuration: storeItemModel.currentDuration!,
          remainingDuration: null,
          title: storeItemModel.title,
          isCountDown: true,
        ); // Timer başlangıç zamanını kaydet (task'larla aynı format)
        prefs.setString('item_timer_start_time_${storeItemModel.id}', DateTime.now().millisecondsSinceEpoch.toString());
        prefs.setString('item_timer_start_duration_${storeItemModel.id}', storeItemModel.currentDuration!.inSeconds.toString());

        // Ayrıca güncel update sistemini de koru
        final now = DateTime.now();
        prefs.setString('item_last_update_${storeItemModel.id}', now.toIso8601String());
        prefs.setString('item_last_progress_${storeItemModel.id}', storeItemModel.currentDuration!.inSeconds.toString());

        // Reset alarm triggered flag when timer starts
        prefs.remove('store_item_alarm_triggered_${storeItemModel.id}');

        if (storeItemModel.currentDuration!.inSeconds > 0) {
          // Süre dolduğunda alarm çalsın
          final scheduledDate = now.add(storeItemModel.currentDuration!);
          NotificationService().scheduleNotification(
            id: storeItemModel.id + 100000,
            title: LocaleKeys.item_expired_title.tr(args: [storeItemModel.title]),
            desc: LocaleKeys.item_expired_desc.tr(),
            scheduledDate: scheduledDate,
            isAlarm: true, // Her zaman alarm çalsın
          );
        }
      } else {
        // Timer durduruluyor
        // NOT: Alarm tetiklendikten sonra (süre bittikten sonra) tekrar tekrar çalmasın diye
        // alarm flag'ini SILMIYORUZ. Flag sadece yeni bir başlangıçta temizlenecek.
        prefs.remove('item_timer_start_time_${storeItemModel.id}');
        prefs.remove('item_timer_start_duration_${storeItemModel.id}');
        prefs.remove('item_last_update_${storeItemModel.id}');
        prefs.remove('item_last_progress_${storeItemModel.id}');

        // Bildirimleri iptal et
        NotificationService().stopTimerTask(-storeItemModel.id);
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
    final bool isAllTimersOff = !TaskProvider().taskList.any((element) => element.isTimerActive != null && (element.isTimerActive ?? false)) && !StoreProvider().storeItemList.any((element) => element.isTimerActive != null && (element.isTimerActive ?? false));

    if (_timer != null && _timer!.isActive && isAllTimersOff) {
      _timer!.cancel();
    } else if (_timer == null || !_timer!.isActive) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) async {
          // SharedPreferences'ı bir kez al
          final prefs = await SharedPreferences.getInstance();

          // Widget güncellemesi için flag
          bool shouldUpdateWidget = false;

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
                  shouldUpdateWidget = true;
                }
              } else {
                // Timer başlangıç zamanı yoksa, şimdi oluştur
                prefs.setString('timer_start_time_${task.id}', DateTime.now().millisecondsSinceEpoch.toString());
                prefs.setString('timer_start_duration_${task.id}', task.currentDuration!.inSeconds.toString());

                // Bir saniye ekle
                task.currentDuration = task.currentDuration! + const Duration(seconds: 1);
                shouldUpdateWidget = true;
              }

              // Hedef süreye ulaşıldığında task'ı tamamla ama timer'ı durdurma (hedef >= 0 ise)
              if (task.status != TaskStatusEnum.DONE && task.remainingDuration != null && task.remainingDuration!.inSeconds >= 0 && task.currentDuration! >= task.remainingDuration!) {
                // Clear any existing status before setting to COMPLETED
                task.status = TaskStatusEnum.DONE;
                shouldUpdateWidget = true;

                // Zamanlanmış alarmı iptal etme; yalnızca alarm çalsın istiyoruz

                // Timer tamamlandığında log oluşturma - sadece timer durdurulduğunda log oluşturulacak
                // Burada log oluşturmuyoruz, çünkü timer durdurulduğunda zaten log oluşturulacak

                // Timer'ı durdurma - kullanıcı isterse durdurabilir
                // task.isTimerActive = false;

                // Veritabanını güncelle
                ServerManager().updateTask(taskModel: task);

                // Task Provider'a otomatik bildirim kontrolü çağırma
                // (Tamamlandı durumunda planlı alarmın iptal edilmesini istemiyoruz)
              }

              if (task.currentDuration!.inSeconds % 60 == 0) {
                ServerManager().updateTask(taskModel: task);
                AppHelper().addCreditByProgress(const Duration(seconds: 60));
              }
            }
          }

          for (var storeItem in StoreProvider().storeItemList) {
            if (storeItem.isTimerActive != null && storeItem.isTimerActive == true) {
              // Store previous duration to check if it crosses zero
              Duration previousDuration = storeItem.currentDuration!;

              // Decrease timer by 1 second
              storeItem.currentDuration = storeItem.currentDuration! - const Duration(seconds: 1);

              // Check if timer just crossed zero (from positive to zero or negative)
              if (previousDuration.inSeconds > 0 && storeItem.currentDuration!.inSeconds <= 0) {
                // Check if alarm has already been triggered for this item
                String? alarmTriggeredStr = prefs.getString('store_item_alarm_triggered_${storeItem.id}');
                bool alarmTriggered = alarmTriggeredStr != null && alarmTriggeredStr == 'true';

                debugPrint('🔥 STORE ITEM ALARM CHECK: ${storeItem.title} (ID: ${storeItem.id})');
                debugPrint('🔥 Previous duration: ${previousDuration.inSeconds}s');
                debugPrint('🔥 Current duration: ${storeItem.currentDuration!.inSeconds}s');
                debugPrint('🔥 Alarm triggered flag: $alarmTriggered');
                debugPrint('🔥 Memory flag: ${_storeItemAlarmTriggeredMemory.contains(storeItem.id)}');

                if (!alarmTriggered && !_storeItemAlarmTriggeredMemory.contains(storeItem.id)) {
                  debugPrint('🔥 TRIGGERING ALARM FOR STORE ITEM: ${storeItem.title}');

                  // Cancel the scheduled notification first
                  NotificationService().cancelNotificationOrAlarm(storeItem.id + 100000);

                  // Show timer completion alarm (only once when timer reaches zero)
                  NotificationService().scheduleNotification(
                    id: storeItem.id + 200000, // Different ID for completion notification
                    title: LocaleKeys.item_expired_title.tr(args: [storeItem.title]),
                    desc: LocaleKeys.item_expired_desc.tr(),
                    scheduledDate: DateTime.now(), // Schedule it to trigger immediately
                    isAlarm: true, // Always show alarm when timer completes
                  );

                  // Auto-dismiss notification after 10 seconds
                  Future.delayed(const Duration(seconds: 10), () {
                    NotificationService().cancelNotificationOrAlarm(storeItem.id + 200000);
                  });

                  // Mark alarm as triggered so it won't trigger again
                  await prefs.setString('store_item_alarm_triggered_${storeItem.id}', 'true');
                  _storeItemAlarmTriggeredMemory.add(storeItem.id);

                  debugPrint('🔥 ALARM TRIGGERED AND MARKED FOR STORE ITEM: ${storeItem.title}');
                } else {
                  debugPrint('🔥 ALARM ALREADY TRIGGERED FOR STORE ITEM: ${storeItem.title} - SKIPPING');
                }
              }

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

          // Widget'ı güncelle (her 5 saniyede bir veya önemli değişiklik olduğunda)
          if (shouldUpdateWidget) {
            HomeWidgetService.updateTaskCount();
          }
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
        // Always calculate kalan süre from authoritative start time to avoid drift
        final startTimeStr = prefs.getString('item_timer_start_time_${storeItem.id}');
        final startDurationStr = prefs.getString('item_timer_start_duration_${storeItem.id}');
        if (startTimeStr != null && startDurationStr != null) {
          final now = DateTime.now();
          final startTime = DateTime.fromMillisecondsSinceEpoch(int.parse(startTimeStr));
          // Remaining (could be negative after expiry)
          final startRemaining = Duration(seconds: int.parse(startDurationStr));
          final elapsed = now.difference(startTime);

          // previous remaining from last_progress (if exists) else startRemaining
          final lastProgressStr = prefs.getString('item_last_progress_${storeItem.id}');
          final previousRemaining = lastProgressStr != null ? Duration(seconds: int.parse(lastProgressStr)) : startRemaining;
          final newRemaining = startRemaining - elapsed;

          // Alarm trigger detection (pozitiften <=0'a geçiş) using previousRemaining
          if (previousRemaining.inSeconds > 0 && newRemaining.inSeconds <= 0) {
            String? alarmTriggeredStr = prefs.getString('store_item_alarm_triggered_${storeItem.id}');
            bool alarmTriggered = alarmTriggeredStr != null && alarmTriggeredStr == 'true';
            if (!alarmTriggered && !_storeItemAlarmTriggeredMemory.contains(storeItem.id)) {
              debugPrint('🔥 [RESUME] TRIGGERING ALARM FOR STORE ITEM: ${storeItem.title}');
              NotificationService().scheduleNotification(
                id: storeItem.id + 200000,
                title: LocaleKeys.item_expired_title.tr(args: [storeItem.title]),
                desc: LocaleKeys.item_expired_desc.tr(),
                scheduledDate: DateTime.now(),
                isAlarm: true,
              );
              Future.delayed(const Duration(seconds: 10), () {
                NotificationService().cancelNotificationOrAlarm(storeItem.id + 200000);
              });
              await prefs.setString('store_item_alarm_triggered_${storeItem.id}', 'true');
              _storeItemAlarmTriggeredMemory.add(storeItem.id);
              debugPrint('🔥 [RESUME] ALARM TRIGGERED FOR STORE ITEM: ${storeItem.title}');
            } else {
              debugPrint('🔥 [RESUME] ALARM ALREADY TRIGGERED FOR STORE ITEM: ${storeItem.title} - SKIPPING');
            }
          }

          storeItem.currentDuration = newRemaining;
          // Update baseline for next resume
          await prefs.setString('item_last_update_${storeItem.id}', now.toIso8601String());
          await prefs.setString('item_last_progress_${storeItem.id}', newRemaining.inSeconds.toString());
          ServerManager().updateItem(itemModel: storeItem);
        }
      }
      StoreProvider().setStateItems();
    }
  }
}
