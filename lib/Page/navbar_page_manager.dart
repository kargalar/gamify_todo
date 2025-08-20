// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/quick_add_task_bottom_sheet.dart';
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
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      // ÖNEMLİ: Daha önce burada her resume'da tüm görevler için checkNotification çağrılıyordu.
      // Bu çağrı önce mevcut bildirimi iptal ettiği için çalan alarm ekran açıldığında susuyordu.
      // Sorunu gidermek için bu toplu yeniden planlama kaldırıldı.
      // (Görev düzenlenince veya yeni oluşturulunca zaten checkNotification çağrılıyor.)

      // Widget üzerinden yapılan değişiklikleri anında görmek için
      // Hive'dan görevleri ve logları yeniden yükle
      try {
        context.read<TaskProvider>().taskList = await ServerManager().getTasks();
        await context.read<TaskProvider>().loadCategories();
      } catch (_) {}
      try {
        await context.read<TaskLogProvider>().loadTaskLogs();
      } catch (_) {}
      // UI'ı tazele
      if (mounted) {
        context.read<TaskProvider>().updateItems();
        setState(() {});
      }
    } else if (state == AppLifecycleState.paused) {
      // Aktif task ve store item timer'larının snapshot'ını kaydet
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toIso8601String();
      for (var task in context.read<TaskProvider>().taskList) {
        if (task.isTimerActive == true) {
          // task_last_update / task_last_progress zaten global timer tarafından güncelleniyor; yine de son anı zorla yaz
          prefs.setString('task_last_update_${task.id}', now);
          prefs.setString('task_last_progress_${task.id}', task.currentDuration!.inSeconds.toString());
        }
      }
      for (var item in context.read<StoreProvider>().storeItemList) {
        if (item.isTimerActive == true) {
          prefs.setString('item_last_update_${item.id}', now);
          prefs.setString('item_last_progress_${item.id}', item.currentDuration!.inSeconds.toString());
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
        floatingActionButton: floatingActionButtons(),
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
    // !!!! bu olunca loginUser null oluyor, bu yüzden loginUser'ı burada kullanmıyorum
    // loginUser = await ServerManager().getUser();
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
  Widget floatingActionButtons() {
    final currentIndex = context.read<NavbarProvider>().currentIndex;

    // Show FAB for Store, Home, and Inbox tabs
    if (currentIndex == 0 || currentIndex == 1 || currentIndex == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (currentIndex == 1) // Show quick add FAB only for Home and Inbox tabs
            SizedBox(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                backgroundColor: AppColors.text, // Use app's primary blue color (#1773DB)
                foregroundColor: AppColors.background, // White icon color
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    barrierColor: Colors.transparent,
                    builder: (context) => const QuickAddTaskBottomSheet(),
                  );
                },
                elevation: 4,
                child: const Icon(
                  Icons.flash_on_rounded,
                  size: 22,
                ),
              ),
            ),
          const SizedBox(width: 10), // Spacing between FABs
          FloatingActionButton(
            backgroundColor: AppColors.text, // Use app's primary blue color (#1773DB)
            foregroundColor: AppColors.background, // White icon color
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
          ),
        ],
      );
    } else {
      return const SizedBox();
    }
  }
}
