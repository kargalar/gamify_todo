// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gamify_todo/General/accessible.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/add_task_page.dart';
import 'package:gamify_todo/Page/Home/home_page.dart';
import 'package:gamify_todo/Page/Profile/profile_page.dart';
import 'package:gamify_todo/Page/Store/add_store_item_page.dart';
import 'package:gamify_todo/Page/Store/store_page.dart';
import 'package:gamify_todo/Service/global_timer.dart';
import 'package:gamify_todo/Service/hive_service.dart';
import 'package:gamify_todo/Service/home_widget_service.dart';
import 'package:gamify_todo/Service/navigator_service.dart';
import 'package:gamify_todo/Service/notification_services.dart';
import 'package:gamify_todo/Service/server_manager.dart';
import 'package:gamify_todo/Provider/navbar_provider.dart';
import 'package:gamify_todo/Provider/store_provider.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Provider/trait_provider.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
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
                    ProfilePage(),
                  ],
                ),
              ),
        floatingActionButton: floatingActionButton(),
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
    HomeWidgetService.updateTaskCount();

    isLoading = true;
    setState(() {});
  }

  void _onItemTapped(int index) {
    context.read<NavbarProvider>().updateIndex(index);
  }

  Widget floatingActionButton() {
    return context.read<NavbarProvider>().currentIndex == 1 || context.read<NavbarProvider>().currentIndex == 0
        ? FloatingActionButton(
            shape: RoundedRectangleBorder(
              borderRadius: AppColors.borderRadiusAll,
            ),
            onPressed: () async {
              await NavigatorService().goTo(
                context.read<NavbarProvider>().currentIndex == 1 ? const AddTaskPage() : const AddStoreItemPage(),
                transition: Transition.downToUp,
              );
            },
            child: const Icon(Icons.add),
          )
        : const SizedBox();
  }
}
