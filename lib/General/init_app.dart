import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/auth_service.dart';
import 'package:next_level/Service/sync_manager.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/theme_provider.dart';
import 'package:next_level/firebase_options.dart';
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

  // Hive Adapters - initialize first
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
  } // Home Widget
  else {
    await HomeWidgetService.setupHomeWidget();
  }

  // Ensure loginUser is null at startup for testing
  debugPrint('initApp: loginUser before checkAuthState = ${loginUser?.username}');

  // Check authentication state
  await AuthService().checkAuthState();

  debugPrint('initApp: loginUser after checkAuthState = ${loginUser?.username}');

  // If user is not authenticated, loginUser will be null
  // Don't create any guest user - user must login to access the app

  // Only load data if user is authenticated
  if (loginUser != null) {
    // Load task logs
    await TaskLogProvider().loadTaskLogs();

    // Load categories
    await TaskProvider().loadCategories();

    // Initialize SyncManager
    await SyncManager().initialize();
  }

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
