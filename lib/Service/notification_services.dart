import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Page/Task Detail Page/routine_detail_page.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
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

    // Initialize alarm package
    await Alarm.init();

    // Alarm ringing listener'ı ayarla
    Alarm.ringing.listen((AlarmSet alarmSet) {
      debugPrint('');
      debugPrint('🚨🚨🚨 ALARM IS RINGING! 🚨🚨🚨');
      for (final alarm in alarmSet.alarms) {
        debugPrint('🚨 ALARM ID: ${alarm.id}');
        debugPrint('🚨 ALARM TITLE: ${alarm.notificationSettings.title}');
        debugPrint('🚨 ALARM BODY: ${alarm.notificationSettings.body}');
      }
      debugPrint('🚨 CURRENT TIME: ${DateTime.now()}');
      debugPrint('🚨🚨🚨 ALARM IS RINGING! 🚨🚨🚨');
      debugPrint('');
      // Burada alarm çaldığında yapılacak işlemleri ekleyebilirsin
    });

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
        _handleNotificationTap(response.payload);
      },
    );
  }

  // Bildirime tıklandığında çağrılacak metod
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
            RoutineDetailPage(taskModel: task),
            transition: Transition.rightToLeft,
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
    // Bildirim/alarm ID'sini 32-bit integer sınırında tut
    final safeId = id % 2147483647;
    debugPrint('=== scheduleNotification Debug ===');
    debugPrint('ID: $id | safeId: $safeId');
    debugPrint('Title: $title');
    debugPrint('Scheduled Date: $scheduledDate');
    debugPrint('Is Alarm: $isAlarm');
    debugPrint('Early Reminder Minutes: $earlyReminderMinutes');
    debugPrint('Current DateTime: ${DateTime.now()}');
    debugPrint('ScheduledDate isAfter now: ${scheduledDate.isAfter(DateTime.now())}');

    // Task ID'sini payload olarak ekle
    final Map<String, dynamic> payload = {'taskId': id};
    debugPrint('Payload: $payload');

    // Eğer erken hatırlatma süresi belirtilmişse, erken hatırlatma bildirimi planla
    if (earlyReminderMinutes != null && earlyReminderMinutes > 0) {
      final DateTime earlyReminderDate = scheduledDate.subtract(Duration(minutes: earlyReminderMinutes));
      debugPrint('EarlyReminderDate: $earlyReminderDate');
      debugPrint('EarlyReminderDate isAfter now: ${earlyReminderDate.isAfter(DateTime.now())}');
      // Erken hatırlatma zamanı geçmemişse bildirim planla
      if (earlyReminderDate.isAfter(DateTime.now())) {
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

        final tz.TZDateTime earlyReminderTZDate = tz.TZDateTime.from(earlyReminderDate, tz.local);
        debugPrint('earlyReminderTZDate: $earlyReminderTZDate');
        final String earlyPayload = jsonEncode(payload);
        debugPrint('earlyPayload: $earlyPayload');
        try {
          final earlyId = (safeId + 300000) % 2147483647;
          await flutterLocalNotificationsPlugin.zonedSchedule(
            earlyId, // Güvenli ID
            "⏰ $title",
            reminderText,
            earlyReminderTZDate,
            notificationDetails(false), // Erken hatırlatma için normal bildirim kullan
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dateAndTime,
            payload: earlyPayload,
          );
          debugPrint('✓ Early reminder notification scheduled (earlyId: $earlyId)');
        } catch (e) {
          debugPrint('✗ Error scheduling early reminder notification: $e');
        }
      } else {
        debugPrint('✗ Early reminder date is not after now, notification not scheduled');
      }
    }

    // Asıl bildirimi/alarmı planla
    try {
      if (isAlarm) {
        // Alarm package kullanarak gerçek alarm planla
        debugPrint('✓ Scheduling alarm with alarm package...');
        debugPrint('Alarm DateTime: $scheduledDate');
        debugPrint('Current DateTime: ${DateTime.now()}');
        debugPrint('Time difference: ${scheduledDate.difference(DateTime.now()).inMinutes} minutes');

        // Alarm package için gerekli izinleri kontrol et
        bool hasAlarmPermission = await requestAlarmPermission();
        if (!hasAlarmPermission) {
          debugPrint('✗ Alarm permission not granted');
          return;
        }

        final alarmSettings = AlarmSettings(
          id: safeId,
          dateTime: scheduledDate,
          assetAudioPath: 'assets/sounds/alarm.mp3',
          loopAudio: true,
          vibrate: true,
          warningNotificationOnKill: true, // Uygulama öldürüldüğünde uyarı
          androidFullScreenIntent: true, // Android'de tam ekran intent
          volumeSettings: VolumeSettings.fade(
            volume: 0.8,
            fadeDuration: const Duration(seconds: 3),
            volumeEnforced: false, // Prevent volume control UI from appearing
          ),
          notificationSettings: NotificationSettings(
            title: '🚨 $title',
            body: desc,
            stopButton: 'Alarmı Durdur',
            icon: 'notification_icon',
          ),
        );

        try {
          await Alarm.set(alarmSettings: alarmSettings);
          debugPrint('✓ Alarm set called');
        } catch (e) {
          debugPrint('✗ Error calling Alarm.set: $e');
        }

        // Alarm'ın doğru ayarlandığını doğrula
        try {
          final alarms = await Alarm.getAlarms();
          final setAlarm = alarms.where((alarm) => alarm.id == safeId).firstOrNull;
          if (setAlarm != null) {
            debugPrint('✓ Alarm successfully set and verified');
            debugPrint('Alarm ID: ${setAlarm.id}');
            debugPrint('Alarm DateTime: ${setAlarm.dateTime}');
          } else {
            debugPrint('✗ Alarm was not set properly');
          }
        } catch (e) {
          debugPrint('✗ Error verifying alarm: $e');
        }

        debugPrint('✓ Alarm scheduled successfully with alarm package');

        // Debug: Alarm'ları kontrol et
        await debugAlarms();
      } else {
        // Normal bildirim için flutter_local_notifications kullan
        debugPrint('✓ Scheduling notification...');
        final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);
        debugPrint('scheduledTZDate: $scheduledTZDate');
        final String notificationPayload = jsonEncode(payload);
        debugPrint('notificationPayload: $notificationPayload');
        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            safeId,
            title,
            desc,
            scheduledTZDate,
            notificationDetails(false),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dateAndTime,
            payload: notificationPayload,
          );
          debugPrint('✓ Notification scheduled successfully (safeId: $safeId)');
        } catch (e) {
          debugPrint('✗ Error scheduling notification: $e');
        }
      }
    } catch (e) {
      debugPrint('✗ Error scheduling ${isAlarm ? 'alarm' : 'notification'}: $e');
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

    // Anlık bildirim gönder
    try {
      await flutterLocalNotificationsPlugin.show(
        99999, // Test için özel ID
        "Bildirim Testi",
        "Bu bir test bildirimidir. Bildirimler çalışıyor!",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_schedule',
            'Task Schedule',
            channelDescription: 'Notification for schedule tasks',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        payload: payload,
      );
      debugPrint('✓ Test bildirimi gönderildi');
    } catch (e) {
      debugPrint('✗ Test bildirimi gönderilemedi: $e');
    }
    // 5 saniye sonra zamanlanmış bildirim gönder
    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        88888, // Test için farklı bir ID
        "Zamanlanmış Bildirim Testi",
        "Bu bir zamanlanmış test bildirimidir. 5 saniye sonra gösterildi!",
        scheduledDate,
        notificationDetails(false), // Normal bildirim
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('✓ Zamanlanmış test bildirimi gönderildi');
    } catch (e) {
      debugPrint('✗ Zamanlanmış test bildirimi gönderilemedi: $e');
    }
    // 5 saniye sonra gerçek alarm (alarm package ile)
    final DateTime realAlarmDate = DateTime.now().add(const Duration(seconds: 5));
    try {
      final alarmSettings = AlarmSettings(
        id: 66666, // Gerçek alarm test için farklı bir ID
        dateTime: realAlarmDate,
        assetAudioPath: 'assets/sounds/alarm.mp3',
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: true,
        androidFullScreenIntent: true,
        volumeSettings: VolumeSettings.fade(
          fadeDuration: const Duration(seconds: 3),
        ),
        notificationSettings: const NotificationSettings(
          title: '⏰ Gerçek Alarm Testi',
          body: 'Bu alarm package ile yapılan gerçek bir alarm testi!',
          stopButton: 'Alarmı Durdur',
          icon: 'notification_icon',
        ),
      );

      await Alarm.set(alarmSettings: alarmSettings);

      // Alarm'ın doğru ayarlandığını kontrol et
      final alarms = await Alarm.getAlarms();
      debugPrint('✓ Total alarms set: ${alarms.length}');
      final testAlarm = alarms.where((alarm) => alarm.id == 66666).firstOrNull;
      if (testAlarm != null) {
        debugPrint('✓ Test alarm found: ID ${testAlarm.id}, DateTime: ${testAlarm.dateTime}');
      } else {
        debugPrint('✗ Test alarm not found in alarm list');
      }

      debugPrint('✓ Real alarm test scheduled for 5 seconds');
    } catch (e) {
      debugPrint('✗ Error setting test alarm: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    // Cancel all alarms from alarm package
    await Alarm.stopAll();
  }

  Future<void> cancelNotificationOrAlarm(int id) async {
    // Cancel işlemlerinde de güvenli ID kullan
    final safeId = id % 2147483647;
    await flutterLocalNotificationsPlugin.cancel(safeId);
    await Alarm.stop(safeId);
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
        autoCancel: false, // Prevent auto-dismissal when notification panel is opened/closed
        fullScreenIntent: isAlarm,
        category: isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
        actions: isAlarm
            ? [
                const AndroidNotificationAction(
                  'stop_alarm',
                  '⏹️ STOP ALARM',
                  cancelNotification: true,
                  showsUserInterface: false, // Prevent showing UI when action is pressed
                ),
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
          autoCancel: false,
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

  /// Debug: Tüm ayarlanmış alarm'ları göster
  Future<void> debugAlarms() async {
    try {
      final alarms = await Alarm.getAlarms();
      debugPrint('=== DEBUG ALARMS ===');
      debugPrint('Total alarms: ${alarms.length}');

      if (alarms.isEmpty) {
        debugPrint('No alarms set');
      } else {
        for (var alarm in alarms) {
          debugPrint('Alarm ID: ${alarm.id}');
          debugPrint('  DateTime: ${alarm.dateTime}');
          debugPrint('  Title: ${alarm.notificationSettings.title}');
          debugPrint('  Time until alarm: ${alarm.dateTime.difference(DateTime.now()).inMinutes} minutes');
          debugPrint('  ---');
        }
      }
      debugPrint('=== END DEBUG ALARMS ===');
    } catch (e) {
      debugPrint('Error getting alarms: $e');
    }
  }
}

// timer başladığında arkada sessizce sabitlenecek bir bildirim gelecek. onu kapatamaması lazım. (öyle bir özellik yoksa olmayabilir)

// alarmlı bildirimler.
// stop alarm butonu iyi olur. tıklayınca alarmı susacak.

// export import için izinleri kontrol et düzenle.
