import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gamify_todo/1%20Core/helper.dart';
import 'package:gamify_todo/5%20Service/locale_keys.g.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:easy_localization/easy_localization.dart';
import 'dart:typed_data';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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

    if (isAlarm) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        desc,
        scheduledTZDate,
        notificationDetails(isAlarm),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        desc,
        scheduledTZDate,
        notificationDetails(isAlarm),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> notificaitonTest() async {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      21232,
      "test",
      "test test test",
      scheduledDate,
      notificationDetails(false),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
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
        isAlarm ? 'task_alarm' : 'task_completion',
        isAlarm ? 'Task Alarm' : 'Task Completion',
        channelDescription: isAlarm ? 'Alarms for tasks' : 'Notifications for completed tasks',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        sound: isAlarm ? const RawResourceAndroidNotificationSound('alarm') : null,
        playSound: true,
        enableLights: true,
        enableVibration: true,
        vibrationPattern: isAlarm ? Int64List.fromList([0, 1000, 500, 1000, 500, 1000]) : null,
      ),
    );
  }
}
