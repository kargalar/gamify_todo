import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:next_level/Core/duration_calculator.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Model/daily_streak_model.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/vacation_date_provider.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/logging_service.dart';

class DailyStreakProvider extends ChangeNotifier {
  static final DailyStreakProvider _instance = DailyStreakProvider._internal();
  factory DailyStreakProvider() => _instance;
  DailyStreakProvider._internal();

  List<DailyStreakModel> _history = [];
  bool _isInitialized = false;

  List<DailyStreakModel> get history => _history;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _history = await HiveService().getAllDailyStreaks();
      LogService.debug('DailyStreakProvider: Loaded ${_history.length} streak records.');

      await _backfillHistory();
      _isInitialized = true;
    } catch (e) {
      LogService.error('DailyStreakProvider: Error initializing: $e');
    }
  }

  /// Backfill missing streak records for past days
  Future<void> _backfillHistory() async {
    final logs = TaskLogProvider().taskLogList;
    if (logs.isEmpty) {
      LogService.debug('DailyStreakProvider: No logs found, skipping backfill.');
      return;
    }

    // Find the first log date
    DateTime firstLogDate = DateTime.now();
    for (var log in logs) {
      if (log.logDate.isBefore(firstLogDate)) {
        firstLogDate = log.logDate;
      }
    }

    // Normalize to start of day
    firstLogDate = DateTime(firstLogDate.year, firstLogDate.month, firstLogDate.day);
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 1));

    if (firstLogDate.isAfter(yesterday)) {
      LogService.debug('DailyStreakProvider: First log is today or later, skipping backfill.');
      return;
    }

    LogService.debug('DailyStreakProvider: Backfilling from $firstLogDate to $yesterday');

    int backfilledCount = 0;
    // Iterate from first log date until yesterday
    for (DateTime date = firstLogDate; date.isBeforeOrSameDay(yesterday); date = date.add(const Duration(days: 1))) {
      // Check if record already exists
      final existingRecord = _history.firstWhereOrNull((s) => s.date.isSameDay(date));
      if (existingRecord != null) continue;

      // Calculate for this past date using CURRENT settings (freezing history)
      final totalDuration = DurationCalculator.calculateTotalDurationForDate(date);

      // Get current streak settings
      final double minHours = StreakSettingsProvider().streakMinimumHours;
      final targetDuration = minHours > 0 ? Duration(minutes: (minHours * 60).toInt()) : const Duration(hours: 1);

      final isVacation = VacationDateProvider().isVacationDay(date);

      // Determine if met
      final isMet = totalDuration >= targetDuration;

      // Create and save
      final newStreak = DailyStreakModel(
        date: date,
        targetDuration: targetDuration,
        totalDuration: totalDuration,
        isMet: isMet,
        isVacation: isVacation,
      );

      await HiveService().addDailyStreak(newStreak);
      _history.add(newStreak);
      backfilledCount++;
    }

    if (backfilledCount > 0) {
      LogService.debug('DailyStreakProvider: Backfilled $backfilledCount days.');
      notifyListeners();
    } else {
      LogService.debug('DailyStreakProvider: History is up to date.');
    }
  }

  /// Get streak record for a specific date
  DailyStreakModel? getStreakForDate(DateTime date) {
    return _history.firstWhereOrNull((s) => s.date.isSameDay(date));
  }
}
