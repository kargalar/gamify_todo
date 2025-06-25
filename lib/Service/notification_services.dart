import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
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
      showBadge: true,
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

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(alarmChannel);
      await androidPlugin.createNotificationChannel(scheduleChannel);
      await androidPlugin.createNotificationChannel(timerChannel);
    }

    InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: initializationSettingsDarwin,
      windows: windowsIitializationSettings,
    );

    // Bildirime tıklandığında yapılacak işlemi tanımla
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Bildirime tıklandığında yapılacak işlemler
        // _handleNotificationTap(response.payload);
      },
    );
  }

  // Bildirime tıklandığında çağrılacak metod
  // ignore: unused_element
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        // Payload'dan task ID'sini çıkar
        final Map<String, dynamic> data = jsonDecode(payload);
        final int taskId = data['taskId'];

        // İlgili task'ı bul
        final taskList = TaskProvider().taskList;
        final taskIndex = taskList.indexWhere((task) => task.id == taskId);

        if (taskIndex != -1) {
          // Task detay sayfasına yönlendir
          final task = taskList[taskIndex];
          NavigatorService().goTo(
            AddTaskPage(editTask: task),
            transition: Transition.size,
          );
        }
      } catch (e) {
        debugPrint('Notification payload parsing error: $e');
      }
    }
  }

  Future<bool> requestNotificationPermissions() async {
    // Önce mevcut izin durumunu kontrol et
    var status = await Permission.notification.status;

    // İzin verilmemişse iste
    if (!status.isGranted) {
      status = await Permission.notification.request();
    }

    if (status.isGranted) {
      return true;
    } else {
      Helper().getDialog(message: LocaleKeys.notification_permission_required.tr());
      return false;
    }
  }

  // İzinlerin verilip verilmediğini kontrol et (izin istemeden)
  Future<bool> checkNotificationPermissions() async {
    final status = await Permission.notification.status;
    return status.isGranted;
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
    int? earlyReminderMinutes,
  }) async {
    debugPrint('=== scheduleNotification Debug ===');
    debugPrint('ID: $id');
    debugPrint('Title: $title');
    debugPrint('Scheduled Date: $scheduledDate');
    debugPrint('Is Alarm: $isAlarm');
    debugPrint('Early Reminder Minutes: $earlyReminderMinutes');

    final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    debugPrint('Scheduled TZ Date: $scheduledTZDate');
    debugPrint('Current TZ Date: ${tz.TZDateTime.now(tz.local)}');

    // Task ID'sini payload olarak ekle
    final String payload = jsonEncode({'taskId': id}); // Eğer erken hatırlatma süresi belirtilmişse (alarm veya bildirim için), erken hatırlatma bildirimi planla
    if (earlyReminderMinutes != null && earlyReminderMinutes > 0) {
      final tz.TZDateTime earlyReminderDate = scheduledTZDate.subtract(Duration(minutes: earlyReminderMinutes));

      // Erken hatırlatma zamanı geçmemişse bildirim planla
      if (earlyReminderDate.isAfter(tz.TZDateTime.now(tz.local))) {
        String reminderText;
        if (earlyReminderMinutes >= 60) {
          final hours = earlyReminderMinutes ~/ 60;
          final minutes = earlyReminderMinutes % 60;
          if (minutes > 0) {
            reminderText = "${hours}h ${minutes}m sonra başlayacak";
          } else {
            reminderText = "${hours}h sonra başlayacak";
          }
        } else {
          reminderText = "$earlyReminderMinutes dakika sonra başlayacak";
        }

        await flutterLocalNotificationsPlugin.zonedSchedule(
          id + 300000, // Erken hatırlatma için farklı bir ID kullan
          "⏰ $title",
          reminderText,
          earlyReminderDate,
          notificationDetails(false), // Erken hatırlatma için alarm değil, normal bildirim kullan
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
          payload: payload,
        );
      }
    }

    // Asıl bildirimi planla
    try {
      debugPrint('✓ Scheduling main notification...');
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        desc,
        scheduledTZDate,
        notificationDetails(isAlarm),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // Use dateAndTime to ensure notifications are scheduled for the exact date and time
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        payload: payload,
      );
      debugPrint('✓ Main notification scheduled successfully');
    } catch (e) {
      debugPrint('✗ Error scheduling main notification: $e');
    }
  }

  Future<void> notificationTest() async {
    // Bildirim izinlerini kontrol et
    bool hasPermission = await checkNotificationPermissions();
    if (!hasPermission) {
      hasPermission = await requestNotificationPermissions();
      if (!hasPermission) {
        debugPrint('Notification permission denied');
        return;
      }
    }

    // Test bildirimi için payload
    final String payload = jsonEncode({'taskId': 0, 'isTest': true});

    // // Anlık bildirim gönder
    // await flutterLocalNotificationsPlugin.show(
    //   99999, // Test için özel ID
    //   "Bildirim Testi",
    //   "Bu bir test bildirimidir. Bildirimler çalışıyor!",
    //   const NotificationDetails(
    //     android: AndroidNotificationDetails(
    //       'task_schedule',
    //       'Task Schedule',
    //       channelDescription: 'Notification for schedule tasks',
    //       importance: Importance.max,
    //       priority: Priority.high,
    //       playSound: true,
    //     ),
    //   ),
    //   payload: payload,
    // );

    // // 5 saniye sonra zamanlanmış bildirim gönder
    // final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

    // await flutterLocalNotificationsPlugin.zonedSchedule(
    //   88888, // Test için farklı bir ID
    //   "Zamanlanmış Bildirim Testi",
    //   "Bu bir zamanlanmış test bildirimidir. 5 saniye sonra gösterildi!",
    //   scheduledDate,
    //   notificationDetails(false), // Normal bildirim
    //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    //   payload: payload,
    // );

    // 10 saniye sonra alarm bildirimi gönder
    final tz.TZDateTime alarmDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 2));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      77777, // Alarm test için farklı bir ID
      "🚨 Alarm Testi",
      "Bu bir alarm test bildirimidir. 10 saniye sonra çaldı!",
      alarmDate,
      notificationDetails(true), // Alarm bildirimi
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
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
        vibrationPattern: isAlarm ? Int64List.fromList([0, 800, 400, 800, 400, 800, 400, 800, 400, 800, 400, 800, 400, 800, 400, 800, 400, 800, 400, 800]) : null,
        ongoing: isAlarm, // Only alarms stay visible, notifications can be swiped away
        autoCancel: false, // Alarms cannot be auto-dismissed
        fullScreenIntent: isAlarm,
        category: isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
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
        timeoutAfter: null, // Ensures no timeout for notifications
        audioAttributesUsage: isAlarm ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
        playSound: true,
        ticker: isAlarm ? 'Alarm is active' : null,
        visibility: NotificationVisibility.public,
      ),
      windows: const WindowsNotificationDetails(),
    );
  }

  Future<void> showTimerNotification({
    required int id,
    required String title,
    required Duration currentDuration,
    required Duration? remainingDuration,
    required bool isCountDown,
    bool isCompleted = false, // Add isCompleted parameter with default value false
  }) async {
    // Task ID'sini payload olarak ekle (negatif ID'yi pozitife çevir)
    final int taskId = id < 0 ? -id : id;
    final String payload = jsonEncode({'taskId': taskId});

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
          // Make active timer notifications non-dismissible, but completed ones dismissible
          ongoing: !isCompleted, // Cannot be swiped away when true for active timers
          autoCancel: isCompleted, // Auto dismiss when tapped if completed
          usesChronometer: !isCompleted, // Don't use chronometer for completed notifications
          chronometerCountDown: isCountDown && !isCompleted,
          when: isCountDown ? DateTime.now().millisecondsSinceEpoch + currentDuration.inMilliseconds : DateTime.now().millisecondsSinceEpoch - currentDuration.inMilliseconds,
          visibility: NotificationVisibility.private,
          onlyAlertOnce: true,
          fullScreenIntent: false, // Don't use full screen intent for timers
          category: isCompleted ? AndroidNotificationCategory.status : AndroidNotificationCategory.service,
          silent: !isCompleted, // Play sound for completion notifications
        ),
      ),
      payload: payload,
    );
  }
}

// timer başladığında arkada sessizce sabitlenecek bir bildirim gelecek. onu kapatamaması lazım. (öyle bir özellik yoksa olmayabilir)

// alarmlı bildirimler.
// stop alarm butonu iyi olur. tıklayınca alarmı susacak.

// export import için izinleri kontrol et düzenle.
