// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/QuickAddTask/quick_add_task_bottom_sheet.dart';
import 'package:next_level/Page/Inbox/inbox_page.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Page/Home/home_page.dart';
import 'package:next_level/Page/Profile/profile_page.dart';
import 'package:next_level/Page/Store/add_store_item_page.dart';
import 'package:next_level/Page/Store/store_page.dart';
import 'package:next_level/Page/Notes/notes_page.dart';
import 'package:next_level/Page/Projects/projects_page.dart';
import 'package:next_level/Widgets/add_edit_item_bottom_sheet.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Service/default_data_service.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Provider/navbar_visibility_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/logging_service.dart';

class NavbarPageManager extends StatefulWidget {
  const NavbarPageManager({super.key});

  @override
  State<NavbarPageManager> createState() => _NavbarPageManagerState();
}

class _NavbarPageManagerState extends State<NavbarPageManager> with WidgetsBindingObserver {
  bool isLoading = false;
  bool _isInitialized = false;

  final List<BottomNavigationBarItem> navbarItems = [
    BottomNavigationBarItem(
      icon: const Icon(Icons.store),
      label: StringTranslateExtension(LocaleKeys.Store).tr(),
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.list),
      label: StringTranslateExtension(LocaleKeys.Inbox).tr(), // Home yok, Inbox kullanılıyor
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.tag),
      label: StringTranslateExtension(LocaleKeys.Categories).tr(),
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.note),
      label: StringTranslateExtension(LocaleKeys.MyNotes).tr(),
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.folder_outlined),
      label: 'Projects', // Projects için uygun bir key yok, düz metin bırakıldı
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.person_rounded),
      label: StringTranslateExtension(LocaleKeys.Profile).tr(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    getData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    LogService.debug('🔄 App lifecycle state changed: $state');
    // Uygulama arkaplandayken timer düzgün çalışmadığı için bu kodu yazdım
    if (state == AppLifecycleState.resumed) {
      LogService.debug('✅ App resumed - reloading data');
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
      // Kullanıcı bilgilerini de yeniden yükle (credit güncellemesi için)
      try {
        final user = await ServerManager().getUser();
        if (user != null) {
          LogService.debug('💰 User reloaded: credit=${user.userCredit}, progress=${user.creditProgress.inMinutes} minutes');
          loginUser = user; // Global değişkeni güncelle
          if (mounted) {
            context.read<UserProvider>().setUser(user); // Provider'ı güncelle
            LogService.debug('💰 UserProvider updated with new credit');
          }
        }
      } catch (e) {
        LogService.error('❌ Failed to reload user: $e');
      }
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
    // Initialize providers on first build
    if (!_isInitialized) {
      final visibilityProvider = context.read<NavbarVisibilityProvider>();
      final navbarProvider = context.read<NavbarProvider>();

      // Set visibility provider to navbar provider and navigator service
      navbarProvider.setVisibilityProvider(visibilityProvider);
      NavigatorService().setVisibilityProvider(visibilityProvider);

      // Get first visible page index
      final initialPage = visibilityProvider.getFirstVisiblePageIndex();
      navbarProvider.currentIndex = initialPage;

      // Initialize PageController with safe initial page
      navbarProvider.pageController = PageController(initialPage: initialPage);

      LogService.debug('Navbar initialized with page index: $initialPage');
      _isInitialized = true;
    }

    // Get visible navbar items based on provider settings
    final visibilityProvider = context.watch<NavbarVisibilityProvider>();
    final visibleNavbarItems = _getVisibleNavbarItems(visibilityProvider);
    final visiblePages = _getVisiblePages(visibilityProvider);

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
                  onPageChanged: (visibleIndex) {
                    // Convert visible index to actual page index
                    final pageIndex = visibilityProvider.mapVisibleIndexToPageIndex(visibleIndex);
                    setState(() => context.read<NavbarProvider>().currentIndex = pageIndex);
                  },
                  children: visiblePages,
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
            currentIndex: _getSafeVisibleIndex(
              visibilityProvider,
              context.read<NavbarProvider>().currentIndex,
            ),
            onTap: (index) {
              final pageIndex = visibilityProvider.mapVisibleIndexToPageIndex(index);
              _onItemTapped(pageIndex);
            },
            items: visibleNavbarItems,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.main,
            unselectedItemColor: AppColors.text.withValues(alpha: 0.5),
            selectedFontSize: 13,
            unselectedFontSize: 11,
            selectedIconTheme: const IconThemeData(size: 28),
            unselectedIconTheme: const IconThemeData(size: 24),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            backgroundColor: AppColors.background,
            elevation: 8,
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
      LogService.debug('Home widget initialized successfully');
    } catch (e) {
      LogService.error('Failed to initialize home widget: $e');
    }

    isLoading = true;
    setState(() {});

    // İlk yükleme kontrolü - Dialog göster
    _checkAndShowDefaultDataDialog();
  }

  void _onItemTapped(int index) {
    context.read<NavbarProvider>().updateIndex(index);
  }

  /// Get safe visible index for BottomNavigationBar
  /// Returns valid index within bounds of visible items
  int _getSafeVisibleIndex(NavbarVisibilityProvider provider, int pageIndex) {
    final visibleIndex = provider.mapPageIndexToVisibleIndex(pageIndex);

    // If page is not visible (returns -1) or invalid, return first visible item (0)
    if (visibleIndex < 0) {
      return 0;
    }

    // Ensure index is within bounds of visible items
    final visibleCount = provider.getVisibleItemsCount();
    if (visibleIndex >= visibleCount) {
      return visibleCount - 1; // Return last item
    }

    return visibleIndex;
  }

  List<BottomNavigationBarItem> _getVisibleNavbarItems(NavbarVisibilityProvider provider) {
    List<BottomNavigationBarItem> visibleItems = [];

    if (provider.showStore) {
      visibleItems.add(navbarItems[0]); // Store
    }
    if (provider.showInbox) {
      visibleItems.add(navbarItems[1]); // Inbox
    }
    if (provider.showCategories) {
      visibleItems.add(navbarItems[2]); // Categories
    }
    if (provider.showNotes) {
      visibleItems.add(navbarItems[3]); // Notes
    }
    if (provider.showProjects) {
      visibleItems.add(navbarItems[4]); // Projects
    }
    // Profile is always visible
    visibleItems.add(navbarItems[5]); // Profile

    return visibleItems;
  }

  /// Get list of visible pages for PageView
  List<Widget> _getVisiblePages(NavbarVisibilityProvider provider) {
    List<Widget> visiblePages = [];

    if (provider.showStore) {
      visiblePages.add(const StorePage());
    }
    if (provider.showInbox) {
      visiblePages.add(const HomePage());
    }
    if (provider.showCategories) {
      visiblePages.add(const InboxPage());
    }
    if (provider.showNotes) {
      visiblePages.add(const NotesPage());
    }
    if (provider.showProjects) {
      visiblePages.add(const ProjectsPage());
    }
    // Profile is always visible
    visiblePages.add(const ProfilePage());

    return visiblePages;
  }

  Widget floatingActionButtons() {
    final currentIndex = context.read<NavbarProvider>().currentIndex;

    // Show FAB for Store, Home, Inbox, Notes, and Projects tabs
    if (currentIndex == 0 || currentIndex == 1 || currentIndex == 2 || currentIndex == 3 || currentIndex == 4) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (currentIndex == 1) // Show quick add FAB only for Home tab
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
          if (currentIndex == 1) const SizedBox(width: 10), // Spacing between FABs
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
              } else if (currentIndex == 3) {
                // Notes tab - add note with bottom sheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AddEditItemBottomSheet(type: ItemType.note),
                );
              } else if (currentIndex == 4) {
                // Projects tab - add project with bottom sheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AddEditItemBottomSheet(type: ItemType.project),
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

  /// İlk yükleme kontrolü yapar ve varsayılan veri yükleme dialog'unu gösterir
  Future<void> _checkAndShowDefaultDataDialog() async {
    try {
      final isFirstLaunch = await DefaultDataService.isFirstLaunch();

      if (isFirstLaunch && mounted) {
        // Biraz gecikme ekleyelim ki UI tam yüklensin
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        LogService.debug('📱 DefaultDataService: İlk yükleme tespit edildi, dialog gösteriliyor...');

        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.rocket_launch, color: AppColors.main, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Welcome to Next Level! 🎉',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Would you like to load sample data to explore the app features?',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.main.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.main.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sample data includes:',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFeatureItem('✓ Categories & Tasks'),
                        _buildFeatureItem('✓ Projects with notes'),
                        _buildFeatureItem('✓ Store items & rewards'),
                        _buildFeatureItem('✓ Skills & Attributes'),
                        _buildFeatureItem('✓ Daily routines'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You can delete these anytime from settings.',
                    style: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.main,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text(
                    'Load Sample Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );

        // Dialog'u gördü, ilk yükleme bayrağını işaretle
        await DefaultDataService.markFirstLaunchSeen();

        // Kullanıcı "Evet" dediyse varsayılan verileri yükle
        if (result == true && mounted) {
          LogService.debug('✅ DefaultDataService: Kullanıcı varsayılan verileri yüklemeyi onayladı');

          // Loading göster
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.main),
                    const SizedBox(height: 16),
                    Text(
                      'Loading sample data...',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          try {
            // Varsayılan verileri yükle
            await DefaultDataService.loadDefaultData();

            // Verileri yeniden yükle
            if (mounted) {
              context.read<StoreProvider>().storeItemList = await ServerManager().getItems();
              context.read<TraitProvider>().traitList = await ServerManager().getTraits();
              context.read<TaskProvider>().routineList = await ServerManager().getRoutines();
              context.read<TaskProvider>().taskList = await ServerManager().getTasks();
              await context.read<TaskProvider>().loadCategories();

              // UI'ı güncelle
              context.read<TaskProvider>().updateItems();

              // Loading dialog'unu kapat
              Navigator.of(context).pop();

              // Başarı mesajı göster
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✅ Sample data loaded successfully!'),
                  backgroundColor: AppColors.green,
                  duration: const Duration(seconds: 3),
                ),
              );

              LogService.debug('✅ DefaultDataService: Varsayılan veriler başarıyla yüklendi ve UI güncellendi');
            }
          } catch (e) {
            LogService.error('❌ DefaultDataService: Varsayılan veri yükleme hatası: $e');

            if (mounted) {
              // Loading dialog'unu kapat
              Navigator.of(context).pop();

              // Hata mesajı göster
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Failed to load sample data: $e'),
                  backgroundColor: AppColors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        } else if (result == false) {
          LogService.debug('ℹ️ DefaultDataService: Kullanıcı varsayılan verileri yüklemeyi reddetti');
        }
      }
    } catch (e) {
      LogService.error('❌ DefaultDataService: Dialog gösterme hatası: $e');
    }
  }

  /// Dialog için feature item widget'ı
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.text.withValues(alpha: 0.85),
          fontSize: 14,
        ),
      ),
    );
  }
}
