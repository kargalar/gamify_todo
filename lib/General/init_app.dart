import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/General/accessible.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Service/notification_services.dart';
import 'package:gamify_todo/Service/server_manager.dart';
import 'package:gamify_todo/Service/home_widget_service.dart';
import 'package:gamify_todo/Provider/task_log_provider.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Provider/theme_provider.dart';
import 'package:gamify_todo/firebase_options.dart';
import 'package:window_manager/window_manager.dart';

Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Orientation
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Theme
  AppColors.updateTheme(isDarkTheme: await ThemeProvider().getSavedTheme());
  // Hive Adapters
  await Helper().registerAdapters();

  // Localization
  await EasyLocalization.ensureInitialized();
  EasyLocalization.logger.enableBuildModes = [];

  // Notification
  await NotificationService().init();
  await NotificationService().requestNotificationPermissions();
  await NotificationService().requestAlarmPermission();

  // Desktop Window
  if (!kIsWeb && Platform.isWindows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      title: "Next Level",
      size: Size(450, 1000),
      maximumSize: Size(450, 99999),
      minimumSize: Size(400, 600),
      backgroundColor: Colors.transparent,
      // fullScreen: false,
      // skipTaskbar: false,
      // center: true,
      // titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  // Home Widget
  else {
    await HomeWidgetService.setupHomeWidget();
  }

  // auto login
  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // final String? email = prefs.getString('email');
  // final String? password = prefs.getString('password');
  // if (email != null && password != null) {
  //   loginUser = await ServerManager().login(
  //     email: email,
  //     password: password,
  //     isAutoLogin: true,
  //   );
  // }

  loginUser = await ServerManager().getUser();

  // Load task logs
  await TaskLogProvider().loadTaskLogs();

  // Load categories
  await TaskProvider().loadCategories();

  // Custom Error
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(15),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: AppColors.borderRadiusAll,
            ),
            child: Wrap(
              children: [
                Column(
                  children: [
                    const Text(
                      "Error",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      details.exception.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };
}
