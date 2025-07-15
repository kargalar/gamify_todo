import 'dart:async';
import 'package:flutter/material.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Service/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncManager {
  SyncManager._privateConstructor();
  static final SyncManager _instance = SyncManager._privateConstructor();
  factory SyncManager() => _instance;

  final ServerManager _serverManager = ServerManager();
  final FirebaseService _firebaseService = FirebaseService();

  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  bool _isSyncing = false;
  DateTime? _lastSuccessfulSync;

  // Sync intervals
  static const Duration _backgroundSyncInterval = Duration(minutes: 5);
  static const Duration _foregroundSyncInterval = Duration(minutes: 1);

  // Initialize sync manager
  Future<void> initialize() async {
    debugPrint('🔄 Initializing SyncManager...');

    // Load last sync time
    await _loadLastSyncTime();

    // Setup connectivity monitoring
    _setupConnectivityMonitoring();

    // Start periodic sync
    _startPeriodicSync();

    debugPrint('✅ SyncManager initialized successfully');
  }

  // Load last sync time from preferences
  Future<void> _loadLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('last_sync_time');
      if (lastSyncStr != null) {
        _lastSuccessfulSync = DateTime.parse(lastSyncStr);
        debugPrint('📅 Last sync time loaded: $_lastSuccessfulSync');
      }
    } catch (e) {
      debugPrint('❌ Error loading last sync time: $e');
    }
  }

  // Setup connectivity monitoring
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline = results.any((result) => result != ConnectivityResult.none);

        debugPrint('📡 Connectivity changed: ${results.map((r) => r.name).join(', ')} (online: $_isOnline)');

        // If we just came back online, trigger sync
        if (!wasOnline && _isOnline) {
          debugPrint('🔄 Back online, triggering sync...');
          _triggerSync();
        }
      },
    );
  }

  // Start periodic sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_backgroundSyncInterval, (timer) {
      if (_isOnline && !_isSyncing) {
        _triggerSync();
      }
    });
  }

  // Trigger sync manually
  Future<void> _triggerSync() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    debugPrint('🔄 Starting sync...');

    try {
      // Check if user is authenticated
      if (_firebaseService.currentUserUid == null) {
        debugPrint('⚠️ No authenticated user, skipping sync');
        return;
      }

      // Perform bidirectional sync
      await _serverManager.syncAllData();

      // Update last sync time
      _lastSuccessfulSync = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', _lastSuccessfulSync!.toIso8601String());

      debugPrint('✅ Sync completed successfully at $_lastSuccessfulSync');
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Force sync now
  Future<void> forceSyncNow() async {
    debugPrint('🔄 Force sync requested...');
    await _triggerSync();
  }

  // Sync when app comes to foreground
  Future<void> onAppResumed() async {
    debugPrint('📱 App resumed, checking sync...');

    if (_lastSuccessfulSync == null) {
      debugPrint('🔄 No previous sync, triggering sync...');
      await _triggerSync();
      return;
    }

    final timeSinceLastSync = DateTime.now().difference(_lastSuccessfulSync!);
    if (timeSinceLastSync > _foregroundSyncInterval) {
      debugPrint('🔄 Last sync was ${timeSinceLastSync.inMinutes} minutes ago, triggering sync...');
      await _triggerSync();
    } else {
      debugPrint('⏰ Last sync was recent (${timeSinceLastSync.inSeconds} seconds ago), skipping');
    }
  }

  // Sync when app goes to background
  Future<void> onAppPaused() async {
    debugPrint('📱 App paused, performing final sync...');
    await _triggerSync();
  }

  // Sync when task is added/updated/deleted
  Future<void> onTaskChanged() async {
    debugPrint('📝 Task changed, triggering sync...');
    await _triggerSync();
  }

  // Sync when item is added/updated/deleted
  Future<void> onItemChanged() async {
    debugPrint('🛍️ Item changed, triggering sync...');
    await _triggerSync();
  }

  // Get sync status
  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;

  // Get sync status text
  String get syncStatusText {
    if (_isSyncing) return 'Syncing...';
    if (!_isOnline) return 'Offline';
    if (_lastSuccessfulSync == null) return 'Never synced';

    final timeSinceSync = DateTime.now().difference(_lastSuccessfulSync!);
    if (timeSinceSync.inMinutes < 1) return 'Just synced';
    if (timeSinceSync.inMinutes < 60) return '${timeSinceSync.inMinutes}m ago';
    if (timeSinceSync.inHours < 24) return '${timeSinceSync.inHours}h ago';
    return '${timeSinceSync.inDays}d ago';
  }

  // Clean up
  void dispose() {
    debugPrint('🧹 Disposing SyncManager...');
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  // Manual sync methods for specific data types
  Future<void> syncTasksOnly() async {
    if (!_isOnline || _isSyncing) return;

    try {
      _isSyncing = true;
      debugPrint('🔄 Syncing tasks only...');

      if (_firebaseService.currentUserUid != null) {
        await _serverManager.syncAllData();
      }

      debugPrint('✅ Tasks sync completed');
    } catch (e) {
      debugPrint('❌ Tasks sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncItemsOnly() async {
    if (!_isOnline || _isSyncing) return;

    try {
      _isSyncing = true;
      debugPrint('🔄 Syncing items only...');

      if (_firebaseService.currentUserUid != null) {
        await _serverManager.syncAllData();
      }

      debugPrint('✅ Items sync completed');
    } catch (e) {
      debugPrint('❌ Items sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Check for conflicts and resolve them
  Future<void> resolveConflicts() async {
    // This method can be expanded to handle specific conflict resolution logic
    debugPrint('🔧 Resolving conflicts...');

    try {
      // For now, we'll use the bidirectional sync which favors Firebase data
      await _serverManager.syncAllData();
      debugPrint('✅ Conflicts resolved');
    } catch (e) {
      debugPrint('❌ Conflict resolution failed: $e');
    }
  }

  // Enable/disable auto sync
  void setAutoSyncEnabled(bool enabled) {
    if (enabled) {
      _startPeriodicSync();
      debugPrint('✅ Auto sync enabled');
    } else {
      _syncTimer?.cancel();
      debugPrint('⏸️ Auto sync disabled');
    }
  }

  // Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'is_syncing': _isSyncing,
      'is_online': _isOnline,
      'last_sync': _lastSuccessfulSync?.toIso8601String(),
      'sync_status': syncStatusText,
      'current_user': _firebaseService.currentUserUid,
    };
  }
}
