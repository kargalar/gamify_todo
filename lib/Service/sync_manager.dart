import 'dart:async';
import 'package:flutter/material.dart';
import 'package:next_level/Service/firestore_service.dart';
import 'package:next_level/Service/auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final Connectivity _connectivity = Connectivity();

  static const String _lastSyncKey = 'last_full_sync';
  static const String _autoSyncKey = 'auto_sync_enabled';
  static const String _syncOnStartupKey = 'sync_on_startup_enabled';

  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  // Settings
  bool _autoSyncEnabled = true;
  bool _syncOnStartupEnabled = true;
  Duration _syncInterval = const Duration(minutes: 15);

  // Getters
  bool get isSyncing => _isSyncing;
  bool get autoSyncEnabled => _autoSyncEnabled;
  bool get syncOnStartupEnabled => _syncOnStartupEnabled;
  Duration get syncInterval => _syncInterval;

  /// Initialize sync manager
  Future<void> initialize() async {
    await _loadSettings();
    await _firestoreService.enableOfflinePersistence();
    _setupConnectivityListener();

    if (_autoSyncEnabled) {
      _startPeriodicSync();
    }

    // Start real-time listeners for instant sync
    if (_authService.isLoggedIn) {
      await _firestoreService.startRealtimeListeners();
    }

    // Perform startup sync if enabled
    if (_syncOnStartupEnabled && _authService.isLoggedIn) {
      _performStartupSync();
    }
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSyncEnabled = prefs.getBool(_autoSyncKey) ?? true;
    _syncOnStartupEnabled = prefs.getBool(_syncOnStartupKey) ?? true;
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, _autoSyncEnabled);
    await prefs.setBool(_syncOnStartupKey, _syncOnStartupEnabled);
  }

  /// Setup connectivity listener
  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((connectivityResults) {
      final hasConnection = connectivityResults.any((result) => result == ConnectivityResult.mobile || result == ConnectivityResult.wifi);

      if (hasConnection && _autoSyncEnabled && _authService.isLoggedIn) {
        // Connection restored, perform incremental sync
        _performIncrementalSync();
      }
    });
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      if (_authService.isLoggedIn && !_isSyncing) {
        _performIncrementalSync();
      }
    });
  }

  /// Stop periodic sync
  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Perform startup sync (incremental)
  Future<void> _performStartupSync() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      debugPrint('Performing startup sync...');

      final hasConnection = await _hasInternetConnection();
      if (hasConnection) {
        // İlk açılışta hem upload hem download yap
        await _firestoreService.performFullUpload(); // Local verileri yükle
        await _firestoreService.performIncrementalSync(); // Güncellemeleri indir
        debugPrint('Startup sync completed');
      } else {
        debugPrint('No internet connection for startup sync');
      }
    } catch (e) {
      debugPrint('Error during startup sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Perform incremental sync
  Future<void> _performIncrementalSync() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      debugPrint('Performing incremental sync...');

      final hasConnection = await _hasInternetConnection();
      if (hasConnection) {
        await _firestoreService.performIncrementalSync();
        debugPrint('Incremental sync completed');
      } else {
        debugPrint('No internet connection for incremental sync');
      }
    } catch (e) {
      debugPrint('Error during incremental sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Perform full upload (manual)
  Future<bool> performFullUpload() async {
    if (_isSyncing) return false;

    try {
      _isSyncing = true;
      debugPrint('Performing full upload...');

      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) {
        debugPrint('No internet connection for full upload');
        return false;
      }

      final success = await _firestoreService.performFullUpload();
      if (success) {
        await _updateLastSyncTime();
      }
      return success;
    } catch (e) {
      debugPrint('Error during full upload: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Perform full download (manual)
  Future<bool> performFullDownload() async {
    if (_isSyncing) return false;

    try {
      _isSyncing = true;
      debugPrint('Performing full download...');

      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) {
        debugPrint('No internet connection for full download');
        return false;
      }

      final success = await _firestoreService.performFullDownload();
      if (success) {
        await _updateLastSyncTime();
      }
      return success;
    } catch (e) {
      debugPrint('Error during full download: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single task immediately
  Future<bool> syncTask(dynamic task) async {
    if (!_authService.isLoggedIn) return false;

    try {
      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) return false;

      return await _firestoreService.syncTask(task);
    } catch (e) {
      debugPrint('Error syncing task: $e');
      return false;
    }
  }

  /// Sync a single task log immediately
  Future<bool> syncTaskLog(dynamic log) async {
    if (!_authService.isLoggedIn) return false;

    try {
      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) return false;

      return await _firestoreService.syncTaskLog(log);
    } catch (e) {
      debugPrint('Error syncing task log: $e');
      return false;
    }
  }

  /// Sync a single category immediately
  Future<bool> syncCategory(dynamic category) async {
    if (!_authService.isLoggedIn) return false;

    try {
      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) return false;

      return await _firestoreService.syncCategory(category);
    } catch (e) {
      debugPrint('Error syncing category: $e');
      return false;
    }
  }

  /// Sync a single trait immediately
  Future<bool> syncTrait(dynamic trait) async {
    if (!_authService.isLoggedIn) return false;

    try {
      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) return false;

      return await _firestoreService.syncTrait(trait);
    } catch (e) {
      debugPrint('Error syncing trait: $e');
      return false;
    }
  }

  /// Sync a single store item immediately
  Future<bool> syncStoreItem(dynamic item) async {
    if (!_authService.isLoggedIn) return false;

    try {
      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) return false;

      return await _firestoreService.syncStoreItem(item);
    } catch (e) {
      debugPrint('Error syncing store item: $e');
      return false;
    }
  }

  /// Sync a single routine immediately
  Future<bool> syncRoutine(dynamic routine) async {
    if (!_authService.isLoggedIn) return false;

    try {
      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) return false;

      return await _firestoreService.syncRoutine(routine);
    } catch (e) {
      debugPrint('Error syncing routine: $e');
      return false;
    }
  }

  /// Delete task from Firestore
  Future<bool> deleteTaskFromFirestore(int taskId) async {
    if (!_authService.isLoggedIn) return false;

    try {
      final hasConnection = await _hasInternetConnection();
      if (!hasConnection) return false;

      return await _firestoreService.deleteTaskFromFirestore(taskId);
    } catch (e) {
      debugPrint('Error deleting task from Firestore: $e');
      return false;
    }
  }

  /// Check internet connection
  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      return connectivityResults.any((result) => result == ConnectivityResult.mobile || result == ConnectivityResult.wifi);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  /// Update last sync time
  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);
    if (lastSyncString != null) {
      return DateTime.tryParse(lastSyncString);
    }
    return null;
  }

  /// Enable/disable auto sync
  Future<void> setAutoSyncEnabled(bool enabled) async {
    _autoSyncEnabled = enabled;
    await _saveSettings();

    if (enabled) {
      _startPeriodicSync();
    } else {
      _stopPeriodicSync();
    }
  }

  /// Enable/disable sync on startup
  Future<void> setSyncOnStartupEnabled(bool enabled) async {
    _syncOnStartupEnabled = enabled;
    await _saveSettings();
  }

  /// Set sync interval
  void setSyncInterval(Duration interval) {
    _syncInterval = interval;
    if (_autoSyncEnabled) {
      _startPeriodicSync(); // Restart with new interval
    }
  }

  /// Stop real-time listeners
  void stopRealtimeListeners() {
    _firestoreService.stopRealtimeListeners();
  }

  /// Cleanup resources
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    stopRealtimeListeners();
  }
}
