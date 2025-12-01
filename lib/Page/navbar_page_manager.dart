// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Navbar/constants/navbar_constants.dart';
import 'package:next_level/Page/Navbar/constants/navbar_pages.dart';
import 'package:next_level/Page/Navbar/handlers/navbar_fab_handler.dart';
import 'package:next_level/Page/Navbar/handlers/navbar_lifecycle_handler.dart';
import 'package:next_level/Page/Navbar/utils/navbar_visibility_utils.dart';
import 'package:next_level/Page/Navbar/widgets/default_data_dialog.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Provider/navbar_visibility_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Service/default_data_service.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:provider/provider.dart';

class NavbarPageManager extends StatefulWidget {
  const NavbarPageManager({super.key});

  @override
  State<NavbarPageManager> createState() => _NavbarPageManagerState();
}

class _NavbarPageManagerState extends State<NavbarPageManager> with WidgetsBindingObserver {
  bool isLoading = false;
  bool _isInitialized = false;
  late NavbarFABHandler _fabHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fabHandler = NavbarFABHandler(context);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    LogService.debug('🔄 App lifecycle state changed: $state');

    if (state == AppLifecycleState.resumed) {
      await GlobalTimer().checkActiveTimerPref();
      await NotificationService().checkNotificationPermissions();

      if (mounted) {
        await NavbarLifecycleHandler.handleResumed(context);
        setState(() {});
      }
    } else if (state == AppLifecycleState.paused) {
      if (mounted) {
        await NavbarLifecycleHandler.handlePaused(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeNavbar();

    final visibilityProvider = context.watch<NavbarVisibilityProvider>();
    final navbarItems = NavbarConstants.getNavbarItems();
    final allPages = NavbarPages.getAllPages();

    final visibleNavbarItems = NavbarVisibilityUtils.getVisibleNavbarItems(visibilityProvider, navbarItems);
    final visiblePages = NavbarVisibilityUtils.getVisiblePages(visibilityProvider, allPages);

    return IgnorePointer(
      ignoring: !isLoading,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: !isLoading ? const Center(child: CircularProgressIndicator()) : _buildPageView(visibilityProvider, visiblePages),
        floatingActionButton: _fabHandler.buildFAB(context.read<NavbarProvider>().currentIndex),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: _buildBottomNavigationBar(visibilityProvider, visibleNavbarItems),
      ),
    );
  }

  Widget _buildPageView(NavbarVisibilityProvider provider, List<Widget> visiblePages) {
    return SizedBox.expand(
      child: PageView(
        controller: context.read<NavbarProvider>().pageController,
        onPageChanged: (visibleIndex) {
          final pageIndex = provider.mapVisibleIndexToPageIndex(visibleIndex);
          setState(() => context.read<NavbarProvider>().currentIndex = pageIndex);
        },
        children: visiblePages,
      ),
    );
  }

  Widget _buildBottomNavigationBar(NavbarVisibilityProvider provider, List<BottomNavigationBarItem> items) {
    return Theme(
      data: NavbarVisibilityUtils.buildNavbarTheme(context),
      child: BottomNavigationBar(
        currentIndex: NavbarVisibilityUtils.getSafeVisibleIndex(
          provider,
          context.read<NavbarProvider>().currentIndex,
        ),
        onTap: (index) {
          final pageIndex = provider.mapVisibleIndexToPageIndex(index);
          context.read<NavbarProvider>().updateIndex(pageIndex);
        },
        items: items,
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
    );
  }

  void _initializeNavbar() {
    if (!_isInitialized) {
      final visibilityProvider = context.read<NavbarVisibilityProvider>();
      final navbarProvider = context.read<NavbarProvider>();

      navbarProvider.setVisibilityProvider(visibilityProvider);
      NavigatorService().setVisibilityProvider(visibilityProvider);

      final initialPage = visibilityProvider.getFirstVisiblePageIndex();
      navbarProvider.currentIndex = initialPage;
      navbarProvider.pageController = PageController(initialPage: initialPage);

      LogService.debug('Navbar initialized with page index: $initialPage');
      _isInitialized = true;
    }
  }

  Future<void> _loadData() async {
    try {
      LogService.debug('📥 Loading initial data...');

      context.read<StoreProvider>().storeItemList = await ServerManager().getItems();
      context.read<TraitProvider>().traitList = await ServerManager().getTraits();
      context.read<TaskProvider>().routineList = await ServerManager().getRoutines();
      context.read<TaskProvider>().taskList = await ServerManager().getTasks();

      await HiveService().createTasksFromRoutines();
      await GlobalTimer().checkSavedTimers();

      // Initialize home widget
      try {
        await HomeWidgetService.setupHomeWidget();
        await HomeWidgetService.updateAllWidgets();
        LogService.debug('🏠 Home widget initialized successfully');
      } catch (e) {
        LogService.error('Failed to initialize home widget: $e');
      }

      isLoading = true;
      setState(() {});

      _showDefaultDataDialogIfNeeded();
    } catch (e) {
      LogService.error('❌ Failed to load initial data: $e');
      isLoading = true;
      setState(() {});
    }
  }

  Future<void> _showDefaultDataDialogIfNeeded() async {
    try {
      final isFirstLaunch = await DefaultDataService.isFirstLaunch();

      if (!isFirstLaunch || !mounted) return;

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      LogService.debug('📱 First launch detected, showing dialog...');

      final result = await DefaultDataDialog.show(context);
      await DefaultDataService.markFirstLaunchSeen();

      if (result == true && mounted) {
        await _loadDefaultData();
      } else if (result == false) {
        LogService.debug('ℹ️ User declined to load sample data');
      }
    } catch (e) {
      LogService.error('❌ Error showing default data dialog: $e');
    }
  }

  Future<void> _loadDefaultData() async {
    if (!mounted) return;

    LogService.debug('✅ User accepted to load sample data');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DefaultDataDialog.buildLoadingDialog(),
    );

    try {
      await DefaultDataService.loadDefaultData();

      if (!mounted) return;

      context.read<StoreProvider>().storeItemList = await ServerManager().getItems();
      context.read<TraitProvider>().traitList = await ServerManager().getTraits();
      context.read<TaskProvider>().routineList = await ServerManager().getRoutines();
      context.read<TaskProvider>().taskList = await ServerManager().getTasks();
      await context.read<TaskProvider>().loadCategories();

      context.read<TaskProvider>().updateItems();

      Navigator.of(context).pop();

      Helper().getMessage(message: 'Sample data loaded successfully!');

      LogService.debug('✅ Sample data loaded and UI updated');
    } catch (e) {
      LogService.error('❌ Failed to load sample data: $e');

      if (mounted) {
        Navigator.of(context).pop();

        Helper().getMessage(message: 'Failed to load sample data: $e', status: StatusEnum.WARNING);
      }
    }
  }
}
