import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Provider/task_provider.dart';

class VacationModeProvider extends ChangeNotifier {
  static final VacationModeProvider _instance = VacationModeProvider._internal();
  factory VacationModeProvider() => _instance;
  VacationModeProvider._internal();

  static const String _vacationModeKey = 'vacation_mode_enabled';
  bool _isVacationModeEnabled = false;

  bool get isVacationModeEnabled => _isVacationModeEnabled;

  /// Initialize vacation mode settings
  Future<void> initialize() async {
    await _loadVacationModeSettings();
  }

  /// Load vacation mode settings from SharedPreferences
  Future<void> _loadVacationModeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVacationModeEnabled = prefs.getBool(_vacationModeKey) ?? false;
      debugPrint('Loaded vacation mode setting: $_isVacationModeEnabled');
    } catch (e) {
      debugPrint('Error loading vacation mode settings: $e');
      _isVacationModeEnabled = false;
    }
  }

  /// Save vacation mode settings to SharedPreferences
  Future<void> _saveVacationModeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_vacationModeKey, _isVacationModeEnabled);
      debugPrint('Saved vacation mode setting: $_isVacationModeEnabled');
    } catch (e) {
      debugPrint('Error saving vacation mode settings: $e');
    }
  }

  /// Toggle vacation mode
  Future<void> toggleVacationMode() async {
    _isVacationModeEnabled = !_isVacationModeEnabled;
    await _saveVacationModeSettings();

    // Show feedback message to user
    Helper().getMessage(
      message: _isVacationModeEnabled ? 'Tatil modu aktifleştirildi' : 'Tatil modu devre dışı bırakıldı',
      status: StatusEnum.INFO,
    );

    // Notify TaskProvider to update UI immediately
    TaskProvider().notifyListeners();

    notifyListeners();
  }

  /// Set vacation mode explicitly
  Future<void> setVacationMode(bool enabled) async {
    if (_isVacationModeEnabled != enabled) {
      _isVacationModeEnabled = enabled;
      await _saveVacationModeSettings();
      // Notify TaskProvider to update UI immediately
      TaskProvider().notifyListeners();
      notifyListeners();
    }
  }
}
