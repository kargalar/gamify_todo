import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/vacation_date_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/logging_service.dart';

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
      LogService.debug('Loaded vacation mode setting: $_isVacationModeEnabled');
    } catch (e) {
      LogService.error('Error loading vacation mode settings: $e');
      _isVacationModeEnabled = false;
    }
  }

  /// Save vacation mode settings to SharedPreferences
  Future<void> _saveVacationModeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_vacationModeKey, _isVacationModeEnabled);
      LogService.debug('Saved vacation mode setting: $_isVacationModeEnabled');
    } catch (e) {
      LogService.error('Error saving vacation mode settings: $e');
    }
  }

  /// Toggle vacation mode
  Future<void> toggleVacationMode() async {
    _isVacationModeEnabled = !_isVacationModeEnabled;
    await _saveVacationModeSettings();

    // When enabling vacation mode, mark today as vacation date
    // When disabling, today's vacation status remains in history
    if (_isVacationModeEnabled) {
      final today = DateTime.now();
      await VacationDateProvider().setDateVacation(today, true);
      LogService.debug('VacationMode: Marked today as vacation date');
    }

    // Show feedback message to user
    Helper().getMessage(
      message: _isVacationModeEnabled ? 'VacationModeEnabled'.tr() : 'VacationModeDisabled'.tr(),
      status: StatusEnum.INFO,
    ); // Notify TaskProvider to update UI immediately
    TaskProvider().notifyListeners();

    notifyListeners();
  }
}
