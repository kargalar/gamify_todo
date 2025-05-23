import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/trait_model.dart';

class AddTaskProvider with ChangeNotifier {
  // Widget variables
  TaskModel? editTask;
  TextEditingController taskNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  // Focus nodes for managing keyboard focus
  final FocusNode taskNameFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();
  final FocusNode locationFocus = FocusNode();
  final FocusNode subtaskFocus = FocusNode();

  TimeOfDay? selectedTime;
  DateTime? selectedDate = DateTime.now();
  bool isNotificationOn = false;
  bool isAlarmOn = false;
  int targetCount = 1;
  Duration taskDuration = const Duration(hours: 0, minutes: 0);
  TaskTypeEnum selectedTaskType = TaskTypeEnum.CHECKBOX;
  List<int> selectedDays = [];
  List<TraitModel> selectedTraits = [];
  int priority = 3;
  List<SubTaskModel> subtasks = [];
  int? categoryId;
  int? earlyReminderMinutes; // Erken hatırlatma süresi (dakika cinsinden)

  void updateTime(TimeOfDay? time) {
    selectedTime = time;

    notifyListeners();
  }

  void updatePriority(int value) {
    priority = value;

    notifyListeners();
  }

  void updateTargetCount(int value) {
    targetCount = value;

    notifyListeners();
  }

  void addSubtask(SubTaskModel subtask) {
    subtasks.add(subtask);
    notifyListeners();
  }

  void updateSubtask(int index, SubTaskModel updatedSubtask) {
    if (index >= 0 && index < subtasks.length) {
      subtasks[index] = updatedSubtask;
      notifyListeners();
    }
  }

  void removeSubtask(int index) {
    if (index >= 0 && index < subtasks.length) {
      subtasks.removeAt(index);
      notifyListeners();
    }
  }

  void clearSubtasks() {
    subtasks.clear();
    notifyListeners();
  }

  void toggleSubtaskCompletion(int index) {
    if (index >= 0 && index < subtasks.length) {
      subtasks[index].isCompleted = !subtasks[index].isCompleted;
      notifyListeners();
    }
  }

  void loadSubtasksFromTask(TaskModel task) {
    if (task.subtasks != null) {
      subtasks = List.from(task.subtasks!);
    } else {
      subtasks = [];
    }
    notifyListeners();
  }

  void updateCategory(int? id) {
    categoryId = id;
    notifyListeners();
  }

  void updateEarlyReminderMinutes(int? minutes) {
    earlyReminderMinutes = minutes;
    notifyListeners();
  }

  // Bildirim durumu değiştiğinde tüm bağımlı widget'ları güncelle
  void refreshNotificationStatus() {
    notifyListeners();
  }

  void updateLocation() {
    notifyListeners();
  }

  // Method to unfocus all text fields
  void unfocusAll() {
    try {
      if (taskNameFocus.hashCode != 0) {
        taskNameFocus.unfocus();
      }
    } catch (e) {
      // Focus node may have issues
    }

    try {
      if (descriptionFocus.hashCode != 0) {
        descriptionFocus.unfocus();
      }
    } catch (e) {
      // Focus node may have issues
    }

    try {
      if (locationFocus.hashCode != 0) {
        locationFocus.unfocus();
      }
    } catch (e) {
      // Focus node may have issues
    }

    try {
      if (subtaskFocus.hashCode != 0) {
        subtaskFocus.unfocus();
      }
    } catch (e) {
      // Focus node may have issues
    }
  }

  // Dispose focus nodes when provider is disposed
  void disposeFocusNodes() {
    try {
      if (taskNameFocus.hashCode != 0) {
        taskNameFocus.dispose();
      }
    } catch (e) {
      // Focus node may already be disposed
    }

    try {
      if (descriptionFocus.hashCode != 0) {
        descriptionFocus.dispose();
      }
    } catch (e) {
      // Focus node may already be disposed
    }

    try {
      if (locationFocus.hashCode != 0) {
        locationFocus.dispose();
      }
    } catch (e) {
      // Focus node may already be disposed
    }

    try {
      if (subtaskFocus.hashCode != 0) {
        subtaskFocus.dispose();
      }
    } catch (e) {
      // Focus node may already be disposed
    }
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes safely
    try {
      taskNameController.dispose();
    } catch (e) {
      // Controller may already be disposed
    }

    try {
      descriptionController.dispose();
    } catch (e) {
      // Controller may already be disposed
    }

    try {
      locationController.dispose();
    } catch (e) {
      // Controller may already be disposed
    }

    disposeFocusNodes();
    super.dispose();
  }
}
