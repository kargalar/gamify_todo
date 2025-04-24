import 'package:flutter/material.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/subtask_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Model/trait_model.dart';

class AddTaskProvider with ChangeNotifier {
  // Widget variables
  TaskModel? editTask;
  TextEditingController taskNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TimeOfDay? selectedTime;
  DateTime selectedDate = DateTime.now();
  bool isNotificationOn = false;
  bool isAlarmOn = false;
  int targetCount = 1;
  Duration taskDuration = const Duration(hours: 0, minutes: 0);
  TaskTypeEnum selectedTaskType = TaskTypeEnum.CHECKBOX;
  List<int> selectedDays = [];
  List<TraitModel> selectedTraits = [];
  int priority = 3;
  List<SubTaskModel> subtasks = [];

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

  void updateLocation() {
    notifyListeners();
  }
}
