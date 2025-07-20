import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:next_level/Core/auth_wrapper.dart';
import 'package:next_level/General/app_theme.dart';
import 'package:next_level/General/init_app.dart';
import 'package:next_level/Page/Login/modern_login_page.dart';
import 'package:next_level/Page/navbar_page_manager.dart';
import 'package:next_level/Service/product_localization.dart';
import 'package:next_level/Provider/add_store_item_provider.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_style_provider.dart';
import 'package:next_level/Provider/theme_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Provider/color_provider.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';

void main() async {
  await initApp();

  // Initialize TaskStyleProvider and load saved style
  final taskStyleProvider = TaskStyleProvider();
  await taskStyleProvider.loadSavedStyle();

  // Initialize ColorProvider and load saved color
  final colorProvider = ColorProvider();
  await colorProvider.loadSavedColor();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ChangeNotifierProvider(create: (context) => NavbarProvider()),
      ChangeNotifierProvider(create: (context) => TaskProvider()),
      ChangeNotifierProvider.value(value: taskStyleProvider),
      ChangeNotifierProvider.value(value: colorProvider),
      ChangeNotifierProvider(create: (context) => StoreProvider()),
      ChangeNotifierProvider(create: (context) => AddTaskProvider()),
      ChangeNotifierProvider(create: (context) => AddStoreItemProvider()),
      ChangeNotifierProvider(create: (context) => TraitProvider()),
      ChangeNotifierProvider(create: (context) => TaskLogProvider()),
      ChangeNotifierProvider(create: (context) => CategoryProvider()),
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
          home: const AuthWrapper(),
          routes: {
            '/main': (context) => const NavbarPageManager(),
            '/login': (context) => const ModernLoginPage(),
          },
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        );
      },
    );
  }
}
