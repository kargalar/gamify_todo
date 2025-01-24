// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/timezone.dart' as timezone;
// import 'package:timezone/data/latest.dart' as timezone;

// class NotificationServices {
//   static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

//   final BehaviorSubject<NotificationResponse?> onNotifications = BehaviorSubject<NotificationResponse?>();

//   Future<void> checkNotificationStatus(BuildContext context) async {
//     // ? Bildirimler var mı diye kontrol etmek için
//     if (kDebugMode) {
//       final List<PendingNotificationRequest> pendingNotificationRequests = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
//       debugPrint(pendingNotificationRequests.toString());
//     }

//     if (!isNotificationsEnabled) {
//       return;
//     }

//     // ? Eğer bildirimler açık ise ama bildirim izni kapatılmış ise
//     else if (await Permission.notification.isDenied || await Permission.notification.isPermanentlyDenied) {
//       isNotificationsEnabled = false;
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       prefs.setBool('notificationsEnabled', isNotificationsEnabled);
//       await cancelAllNotificaitons();
//     }

//     // ? Eğer bildirimler açık ise ve izin de verilmiş ise bildirimleri güncelle
//     else {
//       await _initNotification(context);
//       await updateNotificaitons(context);
//     }
//   }

//   Future<bool> _initNotification(BuildContext context) async {
//     // TODO: aşağıdaki isteği atınca hiçbir şey sormuyor bende. acaba gereksiz mi?
//     await Permission.scheduleExactAlarm.request();

//     PermissionStatus notificaitonStatus = await Permission.notification.request();

//     if (!notificaitonStatus.isGranted) {
//       Helper().getDialog(
//         message: LocaleKeys.SettingsPage_SettingsTiles_DailyReminder_AccessNotificaitonDialog.tr(),
//         onAccept: () async {
//              Get.back();
//           openAppSettings();
//         },
//       );
//       return false;
//     } else {
//       const InitializationSettings initializationSettings = InitializationSettings(
//         android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//       );

//       timezone.initializeTimeZones();
//       final locationName = await FlutterNativeTimezone.getLocalTimezone();
//       timezone.setLocalLocation(timezone.getLocation(locationName));

//       await flutterLocalNotificationsPlugin.initialize(
//         initializationSettings,

//         // ? Bildirime tıklanınca ne olacağı burada belirleniyor.
//         // onDidReceiveNotificationResponse: (response) async {
//         //   onNotifications.add(response);

//         // Normalde bu şekilde kullanabiliyoruz ama şuan hem yönlenirirken context ile ilgili bir sorun var hemde direkt camera sayfasının açılmasını istemiyorum.
//         // if (response.payload == 'CameraPage') {
//         //   Navigator.push(
//         //     context,
//         //     MaterialPageRoute(
//         //       builder: (context) => const CameraPage(),
//         //     ),
//         //   );
//         // }
//         // },
//       );

//       return true;
//     }
//   }

//   Future setDailyNotification(
//     BuildContext context, {
//     TimeOfDay? selectedTime,
//   }) async {
//     if (!await _initNotification(context)) {
//       return;
//     }
//     selectedTime ??= notificationTime;

//     if (!isNotificationsEnabled) {
//       isNotificationsEnabled = true;
//       LogService().notificationOnOff(notificationTime.format(context).toString());
//     }
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     prefs.setBool('notificationsEnabled', isNotificationsEnabled);

//     notificationTime = selectedTime;

//     prefs.setInt('selectedHour', notificationTime.hour);
//     prefs.setInt('selectedMinute', notificationTime.minute);

//     await updateNotificaitons(context);
//   }

//   Future<void> scheduleNotification({
//     required BuildContext context,
//     required timezone.TZDateTime newNotificaitonTime,
//     required int uniqInt,
//   }) async {
//     flutterLocalNotificationsPlugin.zonedSchedule(
//       uniqInt,
//       // eğer localizaiton tr ise title ve body değişecek
//       context.locale == const Locale('tr', 'TR') ? '⚠️ Fotoğraf Zamanı ' : '⚠️Create Yourself!',
//       context.locale == const Locale('tr', 'TR') ? 'Bugüne dair bir anı bırakmayı unutma!' : 'Don\'t forget to leave a memory of today!',
//       newNotificaitonTime,
//       notificationDetails(),
//       // payload: 'CameraPage',
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
//       matchDateTimeComponents: DateTimeComponents.dateAndTime,
//     );
//   }

//   Future<void> updateNotificaitons(BuildContext context) async {
//     if (!isNotificationsEnabled) return;

//     await cancelAllNotificaitons();

//     timezone.TZDateTime newNotificaitonTime = timezone.TZDateTime(
//       timezone.local,
//       DateTime.now().year,
//       DateTime.now().month,
//       DateTime.now().day,
//       notificationTime.hour,
//       notificationTime.minute,
//     );

//     var allPhotoList = context.read<PhotoProvider>().allPhotosList;
//     // 30 günlük hazırla
//     for (int i = 0; i < 30; i++) {
//       // eğer bildirim tarihi daha geçmemiş ise ve o gün fotoğraf çekilmemiş ise
//       if (i == 0 && newNotificaitonTime.isAfter(timezone.TZDateTime.now(timezone.local)) && (allPhotoList.isEmpty || Helper().isSameDay(allPhotoList.last.date, DateTime.now()))) {
//         debugPrint('Bildirim bugüne ayarlandı');
//         //
//       } else {
//         newNotificaitonTime = newNotificaitonTime.add(const Duration(days: 1));
//       }

//       await scheduleNotification(
//         context: context,
//         newNotificaitonTime: newNotificaitonTime,
//         uniqInt: i,
//       );
//     }
//   }

//   Future<void> pushNotification(RemoteMessage notification) async {
//     await flutterLocalNotificationsPlugin.show(
//       0,
//       notification.notification!.title,
//       notification.notification!.body,
//       notificationDetails(),

//       // payload: 'CameraPage',
//     );
//   }

//   Future<void> cancelAllNotificaitons() async {
//     await flutterLocalNotificationsPlugin.cancelAll();
//   }

//   notificationDetails() {
//     //  Android
//     const androidPlatformChannelSpecifics = AndroidNotificationDetails(
//       'dailyReminder', // Burası ayarlar bölümünde görünüyor.
//       'dailyPhoto', // Burası ayarlar bölümünde görünüyor.
//       channelDescription: 'this channel for daily reminder',
//       importance: Importance.max,
//       icon: '@mipmap/ic_launcher',
//       priority: Priority.high,
//       sound: RawResourceAndroidNotificationSound('notification_sound'),
//     );

//     return const NotificationDetails(
//       android: androidPlatformChannelSpecifics,
//     );
//   }
// }
