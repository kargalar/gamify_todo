import 'package:flutter/material.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/store_item_model.dart';

class AddStoreItemProvider with ChangeNotifier {
  // Widget variables
  ItemModel? editItem;
  TextEditingController taskNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  // Focus nodes for managing keyboard focus
  final FocusNode taskNameFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();

  int addCount = 1;
  Duration taskDuration = const Duration(hours: 0, minutes: 0);
  TaskTypeEnum selectedTaskType = TaskTypeEnum.COUNTER;
  int credit = 0;

  void addItem() {
    StoreProvider().addItem(
      ItemModel(
        title: taskNameController.text,
        description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
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
    final updatedItem = ItemModel(
      id: existingItem.id,
      title: taskNameController.text,
      description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
      type: selectedTaskType,
      credit: credit,
      currentCount: selectedTaskType == TaskTypeEnum.COUNTER ? existingItem.currentCount : null,
      currentDuration: selectedTaskType == TaskTypeEnum.TIMER ? existingItem.currentDuration : null,
      addDuration: taskDuration,
      addCount: addCount,
      isTimerActive: selectedTaskType == TaskTypeEnum.TIMER ? existingItem.isTimerActive : null,
    );

    // Update the editItem reference
    editItem = updatedItem;

    StoreProvider().editItem(updatedItem);
  }

  void setEditItem(ItemModel? item) {
    editItem = item;
    if (item != null) {
      taskNameController.text = item.title;
      descriptionController.text = item.description ?? '';
      credit = item.credit;
      taskDuration = item.addDuration!;
      selectedTaskType = item.type;
      addCount = item.addCount ?? 1;
    } else {
      taskNameController.clear();
      descriptionController.clear();
      credit = 0;
      taskDuration = const Duration(hours: 0, minutes: 0);
      selectedTaskType = TaskTypeEnum.COUNTER;
      addCount = 1;
    }
    notifyListeners();
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
