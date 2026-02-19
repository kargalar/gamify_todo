import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:next_level/General/app_theme.dart';
import 'package:next_level/General/init_app.dart';
import 'package:next_level/Page/navbar_page_manager.dart';
import 'package:next_level/Service/product_localization.dart';
import 'package:next_level/Service/app_launch_service.dart';
import 'package:next_level/Provider/add_store_item_provider.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Provider/quick_add_task_provider.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Provider/navbar_visibility_provider.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
import 'package:next_level/Provider/vacation_mode_provider.dart';
import 'package:next_level/Provider/vacation_date_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_style_provider.dart';
import 'package:next_level/Provider/theme_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Provider/color_provider.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/Provider/projects_provider.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Provider/task_template_provider.dart';
import 'package:next_level/Service/task_template_service.dart';
import 'package:get/route_manager.dart';
import 'package:next_level/Provider/daily_streak_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initApp();

  // Initialize TaskTemplateService
  await TaskTemplateService.initialize();

  // Initialize TaskStyleProvider and load saved style
  final taskStyleProvider = TaskStyleProvider();
  await taskStyleProvider.loadSavedStyle();

  // Initialize ColorProvider and load saved color
  final colorProvider = ColorProvider();
  await colorProvider.loadSavedColor();

  // Initialize VacationModeProvider
  final vacationModeProvider = VacationModeProvider();
  await vacationModeProvider.initialize();

  // Initialize VacationDateProvider
  final vacationDateProvider = VacationDateProvider();
  await vacationDateProvider.initialize();

  // Initialize StreakSettingsProvider
  final streakSettingsProvider = StreakSettingsProvider();
  await streakSettingsProvider.initialize();

  // Initialize DailyStreakProvider
  final dailyStreakProvider = DailyStreakProvider();
  await dailyStreakProvider.initialize();

  // Initialize NavbarVisibilityProvider
  final navbarVisibilityProvider = NavbarVisibilityProvider();

  // Initialize AppLaunchService and increment launch count
  final appLaunchService = AppLaunchService();
  await appLaunchService.incrementLaunchCountAndRequestReview();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ChangeNotifierProvider(create: (context) => NavbarProvider()),
      ChangeNotifierProvider.value(value: navbarVisibilityProvider),
      ChangeNotifierProvider(create: (context) => TaskProvider()),
      ChangeNotifierProvider(create: (context) => TaskTemplateProvider()),
      ChangeNotifierProvider.value(value: taskStyleProvider),
      ChangeNotifierProvider.value(value: colorProvider),
      ChangeNotifierProvider.value(value: vacationModeProvider),
      ChangeNotifierProvider.value(value: vacationDateProvider),
      ChangeNotifierProvider.value(value: streakSettingsProvider),
      ChangeNotifierProvider.value(value: dailyStreakProvider),
      ChangeNotifierProvider(create: (context) => StoreProvider()),
      ChangeNotifierProvider(create: (context) => AddTaskProvider()),
      ChangeNotifierProvider(create: (context) => QuickAddTaskProvider()),
      ChangeNotifierProvider(create: (context) => AddStoreItemProvider()),
      ChangeNotifierProvider(create: (context) => TraitProvider()),
      ChangeNotifierProvider(create: (context) => TaskLogProvider()),
      ChangeNotifierProvider(create: (context) => CategoryProvider()),
      ChangeNotifierProvider(create: (context) => NotesProvider()),
      ChangeNotifierProvider(create: (context) => ProjectsProvider()),
      ChangeNotifierProvider(create: (context) => UserProvider()),
    ],
    child: ProductLocalization(child: const Main()),
  ));
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X boyutunu referans aldık
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'NextLevel',
          theme: AppTheme().theme,
          debugShowCheckedModeBanner: false,
          showPerformanceOverlay: false,
          home: const NavbarPageManager(),
          routes: {
            '/main': (context) => const NavbarPageManager(),
          },
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: const Locale('en', 'US'), // Force English as default language
        );
      },
    );
  }
}
