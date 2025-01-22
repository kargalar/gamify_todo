import 'dart:async';
import 'package:gamify_todo/1%20Core/extensions.dart';
import 'package:gamify_todo/5%20Service/app_helper.dart';
import 'package:gamify_todo/5%20Service/home_widget_service.dart';
import 'package:gamify_todo/5%20Service/locale_keys.g.dart';
import 'package:gamify_todo/5%20Service/notification_services.dart';
import 'package:gamify_todo/5%20Service/server_manager.dart';
import 'package:gamify_todo/6%20Provider/navbar_provider.dart';
import 'package:gamify_todo/6%20Provider/store_provider.dart';
import 'package:gamify_todo/6%20Provider/task_provider.dart';
import 'package:gamify_todo/7%20Enum/task_status_enum.dart';
import 'package:gamify_todo/8%20Model/store_item_model.dart';
import 'package:gamify_todo/8%20Model/task_model.dart';
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
      taskModel.isTimerActive = !taskModel.isTimerActive!;

      // Timer başlatıldığında zamanı kaydet
      final prefs = await SharedPreferences.getInstance();
      if (taskModel.isTimerActive!) {
        NotificationService().showTimerNotification(
          id: taskModel.id,
          currentDuration: taskModel.currentDuration!,
          title: taskModel.title,
          isCountDown: false,
        );

        final now = DateTime.now().toIso8601String();
        await prefs.setString('task_last_update_${taskModel.id}', now);
        await prefs.setString('task_last_progress_${taskModel.id}', taskModel.currentDuration!.inSeconds.toString());

        // birldirim ayarla
        if (taskModel.status != TaskStatusEnum.COMPLETED) {
          // scheduled notification
          final scheduledDate = DateTime.now().add(taskModel.remainingDuration! - taskModel.currentDuration!);
          NotificationService().scheduleNotification(
            id: taskModel.id,
            title: LocaleKeys.task_completed_title.tr(args: [taskModel.title]),
            desc: LocaleKeys.task_completed_desc.tr(args: [taskModel.remainingDuration!.textLongDynamicWithoutZero()]),
            scheduledDate: scheduledDate,
            isAlarm: true,
          );
        }
      } else {
        await prefs.remove('task_last_update_${taskModel.id}');
        await prefs.remove('task_last_progress_${taskModel.id}');

        NotificationService().cancelNotificationOrAlarm(taskModel.id);
      }
    } else if (storeItemModel != null) {
      storeItemModel.isTimerActive = !storeItemModel.isTimerActive!;

      // Timer başlatıldığında zamanı kaydet
      final prefs = await SharedPreferences.getInstance();
      if (storeItemModel.isTimerActive!) {
        NotificationService().showTimerNotification(
          id: storeItemModel.id,
          currentDuration: storeItemModel.currentDuration!,
          title: storeItemModel.title,
          isCountDown: true,
        );

        final now = DateTime.now().toIso8601String();
        await prefs.setString('item_last_update_${storeItemModel.id}', now);
        await prefs.setString('item_last_progress_${storeItemModel.id}', storeItemModel.currentDuration!.inSeconds.toString());

        if (storeItemModel.currentDuration!.inSeconds > 0) {
          // scheduled notification
          final scheduledDate = DateTime.now().add(storeItemModel.currentDuration!);
          NotificationService().scheduleNotification(
            id: storeItemModel.id,
            title: LocaleKeys.item_expired_title.tr(args: [storeItemModel.title]),
            desc: LocaleKeys.item_expired_desc.tr(),
            scheduledDate: scheduledDate,
            isAlarm: true,
          );
        }
      } else {
        await prefs.remove('item_last_update_${storeItemModel.id}');
        await prefs.remove('item_last_progress_${storeItemModel.id}');

        NotificationService().cancelNotificationOrAlarm(storeItemModel.id);
      }
    }

    startStopGlobalTimer();
  }

  void startStopGlobalTimer() {
    final bool isAllTimersOff = !TaskProvider().taskList.any((element) => element.isTimerActive != null && element.isTimerActive!) && !StoreProvider().storeItemList.any((element) => element.isTimerActive != null && element.isTimerActive!);

    if (_timer != null && _timer!.isActive && isAllTimersOff) {
      _timer!.cancel();
    } else if (_timer == null || !_timer!.isActive) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          for (var task in TaskProvider().taskList) {
            if (task.isTimerActive != null && task.isTimerActive == true) {
              task.currentDuration = task.currentDuration! + const Duration(seconds: 1);

              if (task.status != TaskStatusEnum.COMPLETED && task.currentDuration! >= task.remainingDuration!) {
                task.status = TaskStatusEnum.COMPLETED;
                HomeWidgetService.updateTaskCount();
              }

              if (task.currentDuration!.inSeconds % 60 == 0) {
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setString('task_last_update_${task.id}', DateTime.now().toIso8601String());
                  prefs.setString('task_last_progress_${task.id}', task.currentDuration!.inSeconds.toString());
                });

                ServerManager().updateTask(taskModel: task);

                AppHelper().addCreditByProgress(const Duration(seconds: 60));
              }
            }
          }

          for (var storeItem in StoreProvider().storeItemList) {
            if (storeItem.isTimerActive != null && storeItem.isTimerActive == true) {
              storeItem.currentDuration = storeItem.currentDuration! - const Duration(seconds: 1);

              if (storeItem.currentDuration!.inSeconds % 60 == 0) {
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setString('item_last_update_${storeItem.id}', DateTime.now().toIso8601String());
                  prefs.setString('item_last_progress_${storeItem.id}', storeItem.currentDuration!.inSeconds.toString());
                });

                ServerManager().updateItem(itemModel: storeItem);
              }
            }
          }

          if (NavbarProvider().currentIndex == 0) {
            StoreProvider().setStateItems();
          } else if (NavbarProvider().currentIndex == 1) {
            TaskProvider().updateItems();
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

          // Son güncelleme ile şimdiki zaman arasındaki farkı ekle
          task.currentDuration = lastProgress + difference;

          // Son güncelleme zamanını güncelle
          await prefs.setString('task_last_update_${task.id}', now.toIso8601String());
          await prefs.setString('task_last_progress_${task.id}', task.currentDuration!.inSeconds.toString());

          ServerManager().updateTask(taskModel: task);

          AppHelper().addCreditByProgress(difference);
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
