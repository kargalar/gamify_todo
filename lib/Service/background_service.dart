// import 'dart:async';

// import 'package:flutter_background_service/flutter_background_service.dart';
// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// // init de bunu çalıştırınca galiba artık uygulama arkaplanda açık kalabiliyor.
// Future<void> initBackgroundService() async {
//   final service = FlutterBackgroundService();

//   // const channel = AndroidNotificationChannel(
//   //   'timer_channel',
//   //   'Timer Channel',
//   //   description: 'Shows timer progress',
//   //   importance: Importance.high,
//   // );

//   // final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//   // await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       // notificationChannelId: channel.id,
//       initialNotificationTitle: 'Timer App',
//       initialNotificationContent: 'Timer durdu',
//       foregroundServiceNotificationId: 888,
//     ),
//     iosConfiguration: IosConfiguration(),
//   );
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   Duration currentDuration = Duration.zero;
//   bool isTimerActive = false;

//   service.on('toggle_timer').listen((event) {
//     isTimerActive = event?['isActive'] ?? false;
//   });

//   // Timer her saniye çalışacak
//   Timer.periodic(const Duration(seconds: 1), (timer) async {
//     if (isTimerActive) {
//       currentDuration += const Duration(seconds: 1);

//       // Bildirim güncelleme
//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: 'Timer Çalışıyor',
//           content: formatDuration(currentDuration),
//         );
//       }

//       // UI'a süreyi gönder
//       service.invoke(
//         'update_duration',
//         {'duration': currentDuration.inSeconds},
//       );
//     }
//   });
// }

// String formatDuration(Duration duration) {
//   String twoDigits(int n) => n.toString().padLeft(2, '0');
//   String hours = twoDigits(duration.inHours);
//   String minutes = twoDigits(duration.inMinutes.remainder(60));
//   String seconds = twoDigits(duration.inSeconds.remainder(60));
//   return "$hours:$minutes:$seconds";
// }




// // *******************
// //  final service = FlutterBackgroundService();

// //   @override
// //   void initState() {
// //     super.initState();
// //     _setupServiceListener();
// //   }

// //   void _setupServiceListener() {
// //     service.on('update_duration').listen((event) {
// //       if (event != null) {
// //         final seconds = event['duration'] as int;
// //         context.read<TimerProvider>().updateDuration(
// //               Duration(seconds: seconds),
// //             );
// //       }
// //     });
// //   }



// //  onPressed: () {
// //                     timer.toggleTimer();
// //                     service.invoke(
// //                       'toggle_timer',
// //                       {'isActive': timer.isTimerActive},
// //                     );
// //                   },