import 'package:flutter/material.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class StreakSettingsViewModel extends ChangeNotifier {
  final StreakSettingsProvider _streakSettingsProvider = StreakSettingsProvider();
  late TextEditingController _hoursController;

  // Form validation
  String? _hoursError;
  bool _isInitialized = false;

  // Getters
  StreakSettingsProvider get streakSettings => _streakSettingsProvider;
  TextEditingController get hoursController => _hoursController;
  String? get hoursError => _hoursError;
  bool get isInitialized => _isInitialized;

  // Weekday names for UI
  List<String> get weekdayNames => [
        LocaleKeys.Monday.tr(),
        LocaleKeys.Tuesday.tr(),
        LocaleKeys.Wednesday.tr(),
        LocaleKeys.Thursday.tr(),
        LocaleKeys.Friday.tr(),
        LocaleKeys.Saturday.tr(),
        LocaleKeys.Sunday.tr(),
      ];

  // Initialize the view model
  Future<void> initialize() async {
    if (_isInitialized) return;

    _hoursController = TextEditingController(
      text: _streakSettingsProvider.streakMinimumHours.toStringAsFixed(1),
    );

    // Listen to provider changes
    _streakSettingsProvider.addListener(_onStreakSettingsChanged);

    _isInitialized = true;
    notifyListeners();
  }

  // Handle streak settings provider changes
  void _onStreakSettingsChanged() {
    // Update hours controller if value changed externally
    final currentValue = double.tryParse(_hoursController.text) ?? 0.0;
    if (currentValue != _streakSettingsProvider.streakMinimumHours) {
      _hoursController.text = _streakSettingsProvider.streakMinimumHours.toStringAsFixed(1);
    }
    notifyListeners();
  }

  // Handle hours input change
  void onHoursChanged(String value) {
    _hoursError = null;

    if (value.isEmpty) {
      _hoursError = "Please enter a value";
      notifyListeners();
      return;
    }

    final hours = double.tryParse(value);
    if (hours == null) {
      _hoursError = "Please enter a valid number";
      notifyListeners();
      return;
    }

    if (hours < 0) {
      _hoursError = "Value must be positive";
      notifyListeners();
      return;
    }

    if (hours > 24) {
      _hoursError = "Value cannot exceed 24 hours";
      notifyListeners();
      return;
    }

    // Valid input, update the provider
    _streakSettingsProvider.setStreakMinimumHours(hours);
    notifyListeners();
  }

  // Toggle vacation weekday
  void toggleVacationWeekday(int weekdayIndex) {
    _streakSettingsProvider.toggleVacationWeekday(weekdayIndex);
    notifyListeners();
  }

  // Check if weekday is selected for vacation
  bool isWeekdaySelected(int weekdayIndex) {
    return _streakSettingsProvider.vacationWeekdays.contains(weekdayIndex);
  }

  // Get formatted hours display
  String getFormattedHours() {
    final hours = _streakSettingsProvider.streakMinimumHours;
    if (hours == hours.toInt()) {
      return hours.toInt().toString();
    }
    return hours.toStringAsFixed(1);
  }

  // Validate all form fields
  bool isFormValid() {
    return _hoursError == null && _hoursController.text.isNotEmpty && double.tryParse(_hoursController.text) != null;
  }

  // Reset form to defaults
  void resetToDefaults() {
    _streakSettingsProvider.setStreakMinimumHours(1.0);
    _streakSettingsProvider.clearVacationWeekdays();
    _hoursController.text = "1.0";
    _hoursError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _streakSettingsProvider.removeListener(_onStreakSettingsChanged);
    if (_isInitialized) {
      _hoursController.dispose();
    }
    super.dispose();
  }
}
