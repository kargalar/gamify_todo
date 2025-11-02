import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Service/logging_service.dart';

/// QuickAddTaskProvider - Hızlı task ekleme için state management
/// AddTaskProvider'den daha basit ve compact
class QuickAddTaskProvider with ChangeNotifier {
  // Controllers
  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Focus nodes
  final FocusNode taskNameFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();

  // State variables
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TaskTypeEnum _selectedTaskType = TaskTypeEnum.CHECKBOX;
  int _priority = 3; // Default: low priority
  bool _isLoading = false;
  int _notificationAlarmState = 0; // 0: Off, 1: Notification, 2: Alarm
  int? _earlyReminderMinutes;
  int _targetCount = 1; // Counter için hedef sayısı
  Duration _remainingDuration = const Duration(hours: 0, minutes: 0); // Duration için kalan süre

  // Getters
  DateTime? get selectedDate => _selectedDate;
  TimeOfDay? get selectedTime => _selectedTime;
  TaskTypeEnum get selectedTaskType => _selectedTaskType;
  int get priority => _priority;
  bool get isLoading => _isLoading;
  int get notificationAlarmState => _notificationAlarmState;
  int? get earlyReminderMinutes => _earlyReminderMinutes;
  int get targetCount => _targetCount;
  Duration get remainingDuration => _remainingDuration;

  QuickAddTaskProvider() {
    _selectedDate = DateTime.now();
    LogService.debug('🟢 QuickAddTaskProvider initialized');
  }

  /// Task name güncelle
  void updateTaskName(String value) {
    taskNameController.text = value;
    notifyListeners();
  }

  /// Description güncelle
  void updateDescription(String value) {
    descriptionController.text = value;
    notifyListeners();
  }

  /// Tarih güncelle
  void updateDate(DateTime? date) {
    _selectedDate = date;
    LogService.debug('📅 Date updated: $date');
    notifyListeners();
  }

  /// Update time with notification/alarm state (0: Off, 1: Notification, 2: Alarm)
  void updateTime(TimeOfDay? time, {int? notificationAlarmState, int? earlyReminderMinutes}) {
    _selectedTime = time;
    if (notificationAlarmState != null) {
      _notificationAlarmState = notificationAlarmState;
      switch (notificationAlarmState) {
        case 0:
          LogService.debug('🔇 Notification/Alarm: Off');
        case 1:
          LogService.debug('📢 Notification/Alarm: Notification');
        case 2:
          LogService.debug('🔔 Notification/Alarm: Alarm');
      }
    }
    if (earlyReminderMinutes != null) {
      _earlyReminderMinutes = earlyReminderMinutes;
      LogService.debug('⏰ Early reminder: $earlyReminderMinutes minutes');
    }
    LogService.debug('⏰ Time updated: $time');
    notifyListeners();
  }

  /// Task type güncelle (Checkbox, Counter, Duration)
  void updateTaskType(TaskTypeEnum type) {
    _selectedTaskType = type;
    LogService.debug('🔄 Task type updated: ${type.toString()}');
    notifyListeners();
  }

  /// Priority güncelle (1: High, 2: Medium, 3: Low)
  void updatePriority(int value) {
    _priority = value;
    LogService.debug('⭐ Priority updated: $value');
    notifyListeners();
  }

  /// Loading durumu güncelle
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Early reminder güncelle (dakika cinsinden)
  void updateEarlyReminderMinutes(int? minutes) {
    _earlyReminderMinutes = minutes;
    LogService.debug('🔔 Early reminder updated: $minutes minutes');
    notifyListeners();
  }

  /// Target count güncelle (Counter için)
  void updateTargetCount(int value) {
    _targetCount = value;
    LogService.debug('🎯 Target count updated: $value');
    notifyListeners();
  }

  /// Remaining duration güncelle (Duration için)
  void updateRemainingDuration(Duration value) {
    _remainingDuration = value;
    LogService.debug('⏱ Remaining duration updated: ${value.inMinutes}min');
    notifyListeners();
  }

  /// Tüm alanları validate et
  String? validateInputs() {
    final name = taskNameController.text.trim();

    if (name.isEmpty) {
      LogService.error('❌ QuickAdd validation failed: Task name is empty');
      return 'Task name cannot be empty';
    }

    if (name.length > 200) {
      LogService.error('❌ QuickAdd validation failed: Task name too long');
      return 'Task name is too long (max 200 characters)';
    }

    LogService.debug('✅ QuickAdd validation passed');
    return null;
  }

  /// Model'e dönüştür
  TaskModel toTaskModel() {
    return TaskModel(
      title: taskNameController.text.trim(),
      description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
      type: _selectedTaskType,
      taskDate: _selectedDate,
      time: _selectedTime,
      isNotificationOn: _notificationAlarmState == 1,
      isAlarmOn: _notificationAlarmState == 2,
      targetCount: _selectedTaskType == TaskTypeEnum.COUNTER ? _targetCount : null,
      remainingDuration: _selectedTaskType == TaskTypeEnum.TIMER ? _remainingDuration : null,
      priority: _priority,
      earlyReminderMinutes: _earlyReminderMinutes,
    );
  }

  /// Formu reset et
  void reset() {
    taskNameController.clear();
    descriptionController.clear();
    _selectedDate = DateTime.now();
    _selectedTime = null;
    _selectedTaskType = TaskTypeEnum.CHECKBOX;
    _priority = 3;
    _notificationAlarmState = 0;
    _earlyReminderMinutes = null;
    _targetCount = 1;
    _remainingDuration = const Duration(hours: 0, minutes: 0);
    LogService.debug('🔄 QuickAddTaskProvider reset');
    notifyListeners();
  }

  /// Provider'ı temizle
  void clear() {
    taskNameController.dispose();
    descriptionController.dispose();
    taskNameFocus.dispose();
    descriptionFocus.dispose();
    LogService.debug('🟡 QuickAddTaskProvider disposed');
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
