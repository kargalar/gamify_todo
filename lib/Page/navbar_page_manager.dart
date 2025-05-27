// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Inbox/inbox_page.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Page/Home/home_page.dart';
import 'package:next_level/Page/Profile/profile_page.dart';
import 'package:next_level/Page/Store/add_store_item_page.dart';
import 'package:next_level/Page/Store/store_page.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class NavbarPageManager extends StatefulWidget {
  const NavbarPageManager({super.key});

  @override
  State<NavbarPageManager> createState() => _NavbarPageManagerState();
}

class _NavbarPageManagerState extends State<NavbarPageManager> with WidgetsBindingObserver {
  bool isLoading = false;

  final List<BottomNavigationBarItem> navbarItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.store),
      label: 'Store',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.list),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.tag),
      label: 'Categories',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    getData();
    context.read<NavbarProvider>().pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // Uygulama arkaplandayken timer düzgün çalışmadığı için bu kodu yazdım
    if (state == AppLifecycleState.resumed) {
      // Uygulama öne geldiğinde aktif timer'ları kontrol et
      await GlobalTimer().checkActiveTimerPref();

      // Bildirim izinlerini kontrol et
      await NotificationService().checkNotificationPermissions();

      // Zamanlanmış görevleri kontrol et ve bildirimleri güncelle
      for (var task in TaskProvider().taskList) {
        if (task.time != null && (task.isNotificationOn || task.isAlarmOn)) {
          TaskProvider().checkNotification(task);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isLoading,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: !isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SizedBox.expand(
                child: PageView(
                  controller: context.read<NavbarProvider>().pageController,
                  onPageChanged: (index) {
                    setState(() => context.read<NavbarProvider>().currentIndex = index);
                  },
                  children: const <Widget>[
                    StorePage(),
                    HomePage(),
                    InboxPage(),
                    ProfilePage(),
                  ],
                ),
              ),
        floatingActionButton: floatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Bottom-right corner following Material Design
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: AppColors.transparent,
            highlightColor: AppColors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: context.read<NavbarProvider>().currentIndex,
            onTap: (index) {
              _onItemTapped(index);
            },
            items: navbarItems,
          ),
        ),
      ),
    );
  }

  Future getData() async {
    // TODO: bütün veirler gelecek user bilgisi itemler rutinler tritler.....
    // user
    loginUser = await ServerManager().getUser();
    // item
    context.read<StoreProvider>().storeItemList = await ServerManager().getItems();
    // trait
    context.read<TraitProvider>().traitList = await ServerManager().getTraits();
    // routine
    context.read<TaskProvider>().routineList = await ServerManager().getRoutines();
    // task
    context.read<TaskProvider>().taskList = await ServerManager().getTasks();

    // check routine to task
    await HiveService().createTasksFromRoutines();

    await GlobalTimer().checkSavedTimers();

    // Initialize home widget
    try {
      await HomeWidgetService.setupHomeWidget();
      await HomeWidgetService.updateAllWidgets();
      debugPrint('Home widget initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize home widget: $e');
    }

    isLoading = true;
    setState(() {});
  }

  void _onItemTapped(int index) {
    context.read<NavbarProvider>().updateIndex(index);
  }

  /// Floating Action Button for quick task/item creation
  /// Positioned in bottom-right corner following Material Design guidelines
  /// - Store tab (index 0): Navigate to AddStoreItemPage
  /// - Home tab (index 1): Navigate to AddTaskPage
  /// - Inbox tab (index 2): Navigate to AddTaskPage
  /// - Profile tab (index 3): Hidden
  Widget floatingActionButton() {
    final currentIndex = context.read<NavbarProvider>().currentIndex;

    // Show FAB for Store, Home, and Inbox tabs
    if (currentIndex == 0 || currentIndex == 1 || currentIndex == 2) {
      return FloatingActionButton(
        backgroundColor: AppColors.main, // Use app's primary blue color (#1773DB)
        foregroundColor: Colors.white, // White icon color
        elevation: 6.0, // Appropriate elevation for Material Design
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Rounded corners following Material Design
        ),
        onPressed: () async {
          if (currentIndex == 0) {
            // Store tab - add store item
            await NavigatorService().goTo(
              const AddStoreItemPage(),
              transition: Transition.downToUp,
            );
          } else if (currentIndex == 1 || currentIndex == 2) {
            // Home tab or Inbox tab - add task
            await NavigatorService().goTo(
              const AddTaskPage(),
              transition: Transition.downToUp,
            );
          }
        },
        child: const Icon(
          Icons.add,
          size: 28.0, // Slightly larger icon for better visibility
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}
