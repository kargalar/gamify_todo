import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/user_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/theme_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:window_manager/window_manager.dart';

Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Theme
  AppColors.updateTheme(isDarkTheme: await ThemeProvider().getSavedTheme());

  // Hive Adapters - initialize first
  await Helper().registerAdapters();

  // Initialize or load user
  loginUser = await ServerManager().getUser();
  if (loginUser == null) {
    // Create a default guest user if no user exists
    loginUser = UserModel(
      id: 0,
      email: 'guest@nextlevel.app',
      password: '',
      username: 'Guest',
      creditProgress: Duration.zero,
      userCredit: 0,
    );
    await HiveService().addUser(loginUser!);
    LogService.debug('✅ Created default guest user');
  } else {
    LogService.debug('✅ Loaded existing user: ${loginUser!.username}');
  }

  // Sync loginUser with UserProvider
  UserProvider().setUser(loginUser!);

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

  // Only load data if user is authenticated
  if (loginUser != null) {
    // Load task logs
    await TaskLogProvider().loadTaskLogs();

    // Load categories
    await TaskProvider().loadCategories();

    // Load store items
    await StoreProvider().loadItems();

    // NOT: Varsayılan veriler artık otomatik yüklenmiyor
    // Kullanıcıya ilk açılışta dialog gösterilecek (ana sayfada)
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
