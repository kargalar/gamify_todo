import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Core/Enums/status_enum.dart';

class OfflineModeProvider extends ChangeNotifier {
  static final OfflineModeProvider _instance = OfflineModeProvider._internal();
  factory OfflineModeProvider() => _instance;
  OfflineModeProvider._internal();

  static const String _offlineModeKey = 'offline_mode_enabled';
  bool _isOfflineModeEnabled = false;

  bool get isOfflineModeEnabled => _isOfflineModeEnabled;

  /// Initialize offline mode settings
  Future<void> initialize() async {
    await _loadOfflineModeSettings();
  }

  /// Load offline mode settings from SharedPreferences
  Future<void> _loadOfflineModeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOfflineModeEnabled = prefs.getBool(_offlineModeKey) ?? false;
      debugPrint('Loaded offline mode setting: $_isOfflineModeEnabled');
    } catch (e) {
      debugPrint('Error loading offline mode settings: $e');
      _isOfflineModeEnabled = false;
    }
  }

  /// Save offline mode settings to SharedPreferences
  Future<void> _saveOfflineModeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineModeKey, _isOfflineModeEnabled);
      debugPrint('Saved offline mode setting: $_isOfflineModeEnabled');
    } catch (e) {
      debugPrint('Error saving offline mode settings: $e');
    }
  }

  /// Toggle offline mode
  Future<void> toggleOfflineMode() async {
    _isOfflineModeEnabled = !_isOfflineModeEnabled;
    await _saveOfflineModeSettings();

    // Show feedback message to user
    Helper().getMessage(
      message: _isOfflineModeEnabled ? LocaleKeys.OfflineModeEnabled.tr() : LocaleKeys.OfflineModeDisabled.tr(),
      status: StatusEnum.INFO,
    );

    notifyListeners();
  }

  /// Set offline mode explicitly
  Future<void> setOfflineMode(bool enabled) async {
    if (_isOfflineModeEnabled != enabled) {
      _isOfflineModeEnabled = enabled;
      await _saveOfflineModeSettings();
      notifyListeners();
    }
  }

  /// Check if Firebase operations should be disabled
  bool shouldDisableFirebase() {
    return _isOfflineModeEnabled;
  }
}
