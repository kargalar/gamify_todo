import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Page/Task Detail Page/routine_detail_page.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz; // latest_all to cover all locales
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'dart:typed_data';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/alarm_sound_service.dart';

class NotificationService {
  final AlarmSoundService _alarmSoundService = AlarmSoundService();

  /// Timer taskı durdurulunca çağrılacak örnek fonksiyon
  Future<void> stopTimerTask(int id) async {
    // ...timerı durdurma işlemleri...
    await cancelTimerNotification(id);
    LogService.debug('Timer bildirimi iptal edildi (id: $id)');
  }

  /// Timer bildirimi için kullanılan ID hesaplama fonksiyonu
  int getTimerNotificationId(int id) {
    final int taskId = id < 0 ? -id : id;
    return (1000000000 + taskId) % 2147483647;
  }

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
    // Initialize time zones and set tz.local to match device time zone
    tz.initializeTimeZones();

    final String deviceTimeZone = await _getLocalTimezone();
    final location = tz.getLocation(deviceTimeZone);
    tz.setLocalLocation(location);
    LogService.debug('Timezone initialized. Device timezone: $deviceTimeZone');

    // Initialize alarm package
    await Alarm.init();

    // Alarm ringing listener'ı ayarla
    Alarm.ringing.listen((AlarmSet alarmSet) {
      LogService.debug('');
      LogService.debug('🚨🚨🚨 ALARM IS RINGING! 🚨🚨🚨');
      for (final alarm in alarmSet.alarms) {
        LogService.debug('🚨 ALARM ID: ${alarm.id}');
        LogService.debug('🚨 ALARM TITLE: ${alarm.notificationSettings.title}');
        LogService.debug('🚨 ALARM BODY: ${alarm.notificationSettings.body}');
      }
      LogService.debug('🚨 CURRENT TIME: ${DateTime.now()}');
      LogService.debug('🚨🚨🚨 ALARM IS RINGING! 🚨🚨🚨');
      LogService.debug('');
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
      // Alarm ses kanalını kullan (telefon sessizdeyken respektlenecek)
      audioAttributesUsage: AudioAttributesUsage.alarm,
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

    // Define what to do when notification is tapped
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Bildirime tıklandığında yapılacak işlemler
        _handleNotificationTap(response.payload);
      },
    );
  }

  // Platform channel to get device timezone without external plugin
  static const MethodChannel _tzChannel = MethodChannel('app.nextlevel/timezone');
  Future<String> _getLocalTimezone() async {
    try {
      final tzName = await _tzChannel.invokeMethod<String>('getLocalTimezone');
      return (tzName ?? 'UTC');
    } catch (_) {
      return 'UTC';
    }
  }

  // Bildirime tıklandığında çağrılacak metod
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        // Payload'dan task ID'sini çıkar
        final Map<String, dynamic> data = jsonDecode(payload);

        // Aktif timer bildirimleri: tıklayınca hiçbir yere gitme
        // (Uygulama açıkken ya da kapalıyken sadece bildirim paneli kapanmalı)
        if (data['noNavigate'] == true) {
          return; // erken çıkış, yönlendirme yapma
        }

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
        LogService.error('Notification payload parsing error: $e');
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
    AlarmType alarmType = AlarmType.scheduled, // Default: scheduled task alarm
  }) async {
    // Bildirim/alarm ID'sini 32-bit integer sınırında tut
    final safeId = id % 2147483647;
    LogService.debug('=== scheduleNotification Debug ===');
    LogService.debug('ID: $id | safeId: $safeId');
    LogService.debug('Title: $title');
    LogService.debug('Scheduled Date: $scheduledDate');
    LogService.debug('Is Alarm: $isAlarm');
    LogService.debug('Early Reminder Minutes: $earlyReminderMinutes');
    LogService.debug('Current DateTime: ${DateTime.now()}');
    LogService.debug('ScheduledDate isAfter now: ${scheduledDate.isAfter(DateTime.now())}');

    // Task ID'sini payload olarak ekle
    final Map<String, dynamic> payload = {'taskId': id};
    LogService.debug('Payload: $payload');

    // Early reminder varsa, bildirimi o kadar dakika erkene al
    DateTime actualNotificationTime = scheduledDate;
    if (earlyReminderMinutes != null && earlyReminderMinutes > 0) {
      actualNotificationTime = scheduledDate.subtract(Duration(minutes: earlyReminderMinutes));
      LogService.debug('⏰ Early Reminder Active: $earlyReminderMinutes minutes');
      LogService.debug('⏰ Original scheduled time: $scheduledDate');
      LogService.debug('⏰ Adjusted notification time: $actualNotificationTime (${earlyReminderMinutes}m earlier)');
    }

    // Bildirim/alarmı planla (early reminder varsa erken saatte, yoksa normal saatte)
    try {
      if (isAlarm) {
        // Alarm package kullanarak gerçek alarm planla
        LogService.debug('🚨 Scheduling alarm with alarm package...');
        LogService.debug('🚨 Alarm DateTime: $actualNotificationTime');
        LogService.debug('🚨 Current DateTime: ${DateTime.now()}');
        LogService.debug('🚨 Time difference: ${actualNotificationTime.difference(DateTime.now()).inMinutes} minutes');

        // Alarm package için gerekli izinleri kontrol et
        bool hasAlarmPermission = await requestAlarmPermission();
        if (!hasAlarmPermission) {
          LogService.debug('❌ Alarm permission not granted');
          return;
        }

        // Seçili alarm sesini al
        final selectedSoundPath = await _alarmSoundService.getSelectedSoundPath(alarmType);
        LogService.debug('✅ Selected alarm sound for ${alarmType.name}: $selectedSoundPath');

        final alarmSettings = AlarmSettings(
          id: safeId,
          dateTime: actualNotificationTime, // Early reminder varsa erken saat
          assetAudioPath: selectedSoundPath, // Kullanıcının seçtiği ses
          loopAudio: true,
          vibrate: true,
          warningNotificationOnKill: true, // Uygulama öldürüldüğünde uyarı
          // Ekran kapalıysa ekranı uyandır
          androidFullScreenIntent: true,
          // Sistem alarm ses seviyesini kullan, otomatik yükseltme yok
          // fadeDuration: 1ms - Minimal fade, neredeyse direkt ses
          // volumeEnforced: false - Ses otomatik yükseltilmez
          volumeSettings: VolumeSettings.fixed(
            volumeEnforced: false, // Otomatik ses yükseltme yok
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
          LogService.debug('🚨 Alarm set called');
        } catch (e) {
          LogService.error('❌ Error calling Alarm.set: $e');
        }

        // Alarm'ın doğru ayarlandığını doğrula
        try {
          final alarms = await Alarm.getAlarms();
          final setAlarm = alarms.where((alarm) => alarm.id == safeId).firstOrNull;
          if (setAlarm != null) {
            LogService.debug('✅ Alarm successfully set and verified');
            LogService.debug('🚨 Alarm ID: ${setAlarm.id}');
            LogService.debug('🚨 Alarm DateTime: ${setAlarm.dateTime}');
            LogService.debug('🚨 Time until alarm: ${setAlarm.dateTime.difference(DateTime.now()).inMinutes} minutes');
          } else {
            LogService.debug('❌ Alarm was not set properly');
          }
        } catch (e) {
          LogService.error('❌ Error verifying alarm: $e');
        }

        LogService.debug('✅ Alarm scheduled successfully with alarm package');

        // Debug: Alarm'ları kontrol et
        await debugAlarms();
      } else {
        // Normal bildirim için flutter_local_notifications kullan
        LogService.debug('📢 Scheduling notification...');
        final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(actualNotificationTime, tz.local); // Early reminder varsa erken saat
        LogService.debug('📢 ScheduledTZDate: $scheduledTZDate');
        final String notificationPayload = jsonEncode(payload);
        LogService.debug('📢 NotificationPayload: $notificationPayload');
        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            safeId,
            title,
            desc,
            scheduledTZDate,
            notificationDetails(false),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: notificationPayload,
          );
          LogService.debug('✅ Notification scheduled successfully (safeId: $safeId)');
        } catch (e) {
          LogService.error('❌ Error scheduling notification: $e');
        }
      }
    } catch (e) {
      LogService.error('❌ Error scheduling ${isAlarm ? 'alarm' : 'notification'}: $e');
    }
  }

  Future<void> notificationTest() async {
    // Bildirim izinlerini kontrol et
    bool hasPermission = await checkNotificationPermissions();
    if (!hasPermission) {
      hasPermission = await requestNotificationPermissions();
      if (!hasPermission) {
        LogService.debug('Notification permission denied');
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
      LogService.debug('✓ Test bildirimi gönderildi');
    } catch (e) {
      LogService.error('✗ Test bildirimi gönderilemedi: $e');
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
      LogService.debug('✓ Zamanlanmış test bildirimi gönderildi');
    } catch (e) {
      LogService.error('✗ Zamanlanmış test bildirimi gönderilemedi: $e');
    }
    // 5 saniye sonra gerçek alarm (alarm package ile)
    final DateTime realAlarmDate = DateTime.now().add(const Duration(seconds: 5));
    try {
      // Test alarmı için seçili sesi kullan (scheduled type for testing)
      final selectedSoundPath = await _alarmSoundService.getSelectedSoundPath(AlarmType.scheduled);

      final alarmSettings = AlarmSettings(
        id: 66666, // Gerçek alarm test için farklı bir ID
        dateTime: realAlarmDate,
        assetAudioPath: selectedSoundPath, // Seçili alarm sesi
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: true,
        // Ekran kapalıysa uyandır
        androidFullScreenIntent: true,
        // Sistem alarm ses seviyesi kullan
        volumeSettings: VolumeSettings.fixed(
          volumeEnforced: false,
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
      LogService.debug('✓ Total alarms set: ${alarms.length}');
      final testAlarm = alarms.where((alarm) => alarm.id == 66666).firstOrNull;
      if (testAlarm != null) {
        LogService.debug('✓ Test alarm found: ID ${testAlarm.id}, DateTime: ${testAlarm.dateTime}');
      } else {
        LogService.debug('✗ Test alarm not found in alarm list');
      }

      LogService.debug('✓ Real alarm test scheduled for 5 seconds');
    } catch (e) {
      LogService.error('✗ Error setting test alarm: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      LogService.error('Error canceling local notifications: $e');
    }

    try {
      // Cancel all alarms from alarm package
      await Alarm.stopAll();
    } catch (e) {
      LogService.error('Error stopping all alarms: $e');
      // Alarm paketinde hata olursa devam et
    }
  }

  Future<void> cancelNotificationOrAlarm(int id) async {
    try {
      // Cancel işlemlerinde de güvenli ID kullan
      final safeId = id % 2147483647;
      await flutterLocalNotificationsPlugin.cancel(safeId);
    } catch (e) {
      LogService.error('Error canceling notification for id $id: $e');
    }

    try {
      final safeId = id % 2147483647;
      await Alarm.stop(safeId);
    } catch (e) {
      LogService.error('Error stopping alarm for id $id: $e');
      // Alarm paketinde hata olursa devam et
    }
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
        // fullScreenIntent: true - Alarm için ekran kapalıysa uyandır
        // Bildirim ekranda kapanana kadar görünür kalacak
        fullScreenIntent: isAlarm, // Alarm çaldığında ekranı uyandır
        category: isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
        // Alarm her zaman genişletilmiş (expanded) şekilde göster
        styleInformation: isAlarm
            ? const BigTextStyleInformation(
                '',
                htmlFormatBigText: true,
                contentTitle: '', // Title büyük yazılacak
                htmlFormatContentTitle: true,
                summaryText: '',
                htmlFormatSummaryText: true,
              )
            : null,
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
        onlyAlertOnce: false, // Her zaman ses çıkar
        timeoutAfter: null, // Asla zaman aşımına uğramasın
        when: null, // Zaman gösterme (heads-up'ın kaybolmasını engeller)
        usesChronometer: false, // Kronometre kullanma
        chronometerCountDown: false,
        showWhen: false, // Zaman gösterme
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
    // Task ID'sini payload olarak ekle ve timer bildirimi için güvenli pozitif ID kullan
    final int taskId = id < 0 ? -id : id;
    // Aktif timer bildirimi: tıklayınca navigasyon istemiyoruz
    final String payload = jsonEncode({'taskId': taskId, 'noNavigate': true});
    final int safeTimerId = getTimerNotificationId(id);
    LogService.debug('showTimerNotification: id=$id, safeTimerId=$safeTimerId');

    await flutterLocalNotificationsPlugin.show(
      safeTimerId,
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

  /// Timer bildirimi iptal fonksiyonu
  Future<void> cancelTimerNotification(int id) async {
    final int safeTimerId = getTimerNotificationId(id);
    LogService.debug('cancelTimerNotification: id=$id, safeTimerId=$safeTimerId');
    await flutterLocalNotificationsPlugin.cancel(safeTimerId);
    cancelNotificationOrAlarm(id);
  }

  /// Debug: Tüm ayarlanmış alarm'ları göster
  Future<void> debugAlarms() async {
    try {
      final alarms = await Alarm.getAlarms();
      LogService.debug('=== DEBUG ALARMS ===');
      LogService.debug('Total alarms: ${alarms.length}');

      if (alarms.isEmpty) {
        LogService.debug('No alarms set');
      } else {
        for (var alarm in alarms) {
          LogService.debug('Alarm ID: ${alarm.id}');
          LogService.debug('  DateTime: ${alarm.dateTime}');
          LogService.debug('  Title: ${alarm.notificationSettings.title}');
          LogService.debug('  Time until alarm: ${alarm.dateTime.difference(DateTime.now()).inMinutes} minutes');
          LogService.debug('  ---');
        }
      }
      LogService.debug('=== END DEBUG ALARMS ===');
    } catch (e) {
      LogService.error('Error getting alarms: $e');
    }
  }
}

// timer başladığında arkada sessizce sabitlenecek bir bildirim gelecek. onu kapatamaması lazım. (öyle bir özellik yoksa olmayabilir)

// alarmlı bildirimler.
// stop alarm butonu iyi olur. tıklayınca alarmı susacak.

// export import için izinleri kontrol et düzenle.
