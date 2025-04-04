import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:easy_localization/easy_localization.dart';
import 'dart:typed_data';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
    notificationCategories: [
      DarwinNotificationCategory(
        'demoCategory',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain('id_1', 'Action 1'),
          DarwinNotificationAction.plain(
            'id_2',
            'Action 2',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.destructive,
            },
          ),
          DarwinNotificationAction.plain(
            'id_3',
            'Action 3',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
        },
      )
    ],
  );

  Future<void> init() async {
    tz.initializeTimeZones();

    const WindowsInitializationSettings windowsIitializationSettings = WindowsInitializationSettings(
      appName: 'Next Level',
      appUserModelId: 'Next Level',
      guid: '123e4567-e89b-12d3-a456-426614174000',
    );
    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Alarm kanalını özelleştir
    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      'task_alarm',
      'Task Alarm',
      description: 'Alarms for tasks',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
    );

    const AndroidNotificationChannel scheduleChannel = AndroidNotificationChannel(
      'task_schedule',
      'Task Schedule',
      description: 'Notification for schedule tasks',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
    );

    // Timer kanalını özelleştir
    const AndroidNotificationChannel timerChannel = AndroidNotificationChannel(
      'task_timer',
      'Task Timer',
      description: 'Timer for tasks',
      importance: Importance.max,
      playSound: false,
      showBadge: false,
    );

    // Kanalları oluştur
    final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(alarmChannel);
    await androidPlugin?.createNotificationChannel(scheduleChannel);
    await androidPlugin?.createNotificationChannel(timerChannel);

    InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: initializationSettingsDarwin,
      windows: windowsIitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<bool> requestNotificationPermissions() async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      return true;
    } else {
      Helper().getDialog(message: LocaleKeys.notification_permission_required.tr());
      return false;
    }
  }

  Future<bool> requestAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.request();

    if (status.isGranted) {
      return true;
    } else {
      Helper().getDialog(message: LocaleKeys.alarm_permission_required.tr());
      return false;
    }
  }

  // Future<void> showTaskCompletionNotification({
  //   required String taskTitle,
  // }) async {
  //   await flutterLocalNotificationsPlugin.show(
  //     DateTime.now().millisecondsSinceEpoch.remainder(100000),
  //     '🎉 Görev Tamamlandı!',
  //     '$taskTitle başarıyla tamamlandı!',
  //     notificationDetails(),
  //   );
  // }

  // scheduledNotification
  Future<void> scheduleNotification({
    required int id,
    required String desc,
    required String title,
    required DateTime scheduledDate,
    required bool isAlarm,
  }) async {
    final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      desc,
      scheduledTZDate,
      notificationDetails(isAlarm),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> notificaitonTest() async {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      21232,
      "test",
      "test test test",
      scheduledDate,
      notificationDetails(true),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotificationOrAlarm(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  NotificationDetails notificationDetails(bool isAlarm) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        isAlarm ? 'task_alarm' : 'task_schedule',
        isAlarm ? 'Task Alarm' : 'Task Schedule',
        channelDescription: isAlarm ? 'Alarms for tasks' : 'Notification for schedule tasks',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        sound: isAlarm ? const RawResourceAndroidNotificationSound('alarm') : null,
        enableLights: true,
        enableVibration: true,
        vibrationPattern: isAlarm ? Int64List.fromList([0, 1000, 500, 1000, 500, 1000]) : null,
        ongoing: isAlarm,
        autoCancel: false,
        fullScreenIntent: isAlarm,
        category: AndroidNotificationCategory.alarm,
        actions: isAlarm
            ? [
                const AndroidNotificationAction(
                  'stop_alarm',
                  '⏹️ STOP ALARM',
                  cancelNotification: true,
                  showsUserInterface: true,
                )
              ]
            : null,
        onlyAlertOnce: false,
        timeoutAfter: isAlarm ? null : const Duration(seconds: 10).inMilliseconds,
        audioAttributesUsage: isAlarm ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
        playSound: true,
        ticker: isAlarm ? 'Alarm is active' : null,
        visibility: NotificationVisibility.public,
      ),
      windows: const WindowsNotificationDetails(),
    );
  }

  // TODO: gliba farklı android versiyonlarında bildirim panelinden kaydırarak silinme özelliğini kapatma işlevi çalışmıyor.
  Future<void> showTimerNotification({
    required int id,
    required String title,
    required Duration currentDuration,
    required Duration? remainingDuration,
    required bool isCountDown,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      // ? schedule notification ile çakışmaması için "-"
      -id,
      title,
      remainingDuration != null ? "Target Duration: ${remainingDuration.textShort2hour()}" : "Timer active",
      NotificationDetails(
        android: AndroidNotificationDetails(
          'task_timer',
          'Task Timer',
          channelDescription: 'Timer for tasks',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: false,
          ongoing: true,
          autoCancel: false,
          usesChronometer: true,
          chronometerCountDown: isCountDown,
          when: isCountDown ? DateTime.now().millisecondsSinceEpoch + currentDuration.inMilliseconds : DateTime.now().millisecondsSinceEpoch - currentDuration.inMilliseconds,
          visibility: NotificationVisibility.private,
          onlyAlertOnce: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.service,
          silent: true,
        ),
      ),
    );
  }
}

// timer başladığında arkada sessizce sabitlenecek bir bildirim gelecek. onu kapatamaması lazım. (öyle bir özellik yoksa olmayabilir)

// alarmlı bildirimler.
// stop alarm butonu iyi olur. tıklayınca alarmı susacak.

// export import için izinleri kontrol et düzenle.
