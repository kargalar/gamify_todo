import 'package:flutter/material.dart';
import 'package:next_level/Service/sync_manager.dart';

class SyncLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const SyncLifecycleWrapper({
    super.key,
    required this.child,
  });

  @override
  State<SyncLifecycleWrapper> createState() => _SyncLifecycleWrapperState();
}

class _SyncLifecycleWrapperState extends State<SyncLifecycleWrapper> with WidgetsBindingObserver {
  final SyncManager _syncManager = SyncManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('📱 App resumed - triggering sync check');
        _syncManager.onAppResumed();
        break;
      case AppLifecycleState.paused:
        debugPrint('📱 App paused - triggering final sync');
        _syncManager.onAppPaused();
        break;
      case AppLifecycleState.detached:
        debugPrint('📱 App detached - disposing sync manager');
        _syncManager.dispose();
        break;
      case AppLifecycleState.inactive:
        debugPrint('📱 App inactive');
        break;
      case AppLifecycleState.hidden:
        debugPrint('📱 App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
