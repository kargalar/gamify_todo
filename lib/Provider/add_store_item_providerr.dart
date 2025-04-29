import 'package:flutter/material.dart';
import 'package:gamify_todo/Provider/store_provider.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/store_item_model.dart';

class AddStoreItemProvider with ChangeNotifier {
  // Widget variables
  TextEditingController taskNameController = TextEditingController();

  // Focus nodes for managing keyboard focus
  final FocusNode taskNameFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode(); // Uyumluluk için eklendi

  int addCount = 1;
  Duration taskDuration = const Duration(hours: 0, minutes: 0);
  TaskTypeEnum selectedTaskType = TaskTypeEnum.COUNTER;
  int credit = 0;

  void addItem() {
    StoreProvider().addItem(
      ItemModel(
        title: taskNameController.text,
        type: selectedTaskType,
        credit: credit,
        currentCount: selectedTaskType == TaskTypeEnum.COUNTER ? 0 : null,
        currentDuration: selectedTaskType == TaskTypeEnum.TIMER ? Duration.zero : null,
        addDuration: taskDuration,
        addCount: addCount,
        isTimerActive: selectedTaskType == TaskTypeEnum.TIMER ? false : null,
      ),
    );
  }

  void updateItem(ItemModel existingItem) {
    StoreProvider().editItem(
      ItemModel(
        id: existingItem.id,
        title: taskNameController.text,
        type: selectedTaskType,
        credit: credit,
        currentCount: selectedTaskType == TaskTypeEnum.COUNTER ? existingItem.currentCount : null,
        currentDuration: selectedTaskType == TaskTypeEnum.TIMER ? existingItem.currentDuration : null,
        addDuration: taskDuration,
        addCount: addCount,
        isTimerActive: selectedTaskType == TaskTypeEnum.TIMER ? existingItem.isTimerActive : null,
      ),
    );
  }

  void updateTargetCount(int value) {
    addCount = value;

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
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes safely
    try {
      taskNameController.dispose();
    } catch (e) {
      // Controller may already be disposed
    }

    disposeFocusNodes();
    super.dispose();
  }
}
