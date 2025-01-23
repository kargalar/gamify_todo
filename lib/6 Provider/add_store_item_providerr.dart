import 'package:flutter/material.dart';
import 'package:gamify_todo/6%20Provider/store_provider.dart';
import 'package:gamify_todo/7%20Enum/task_type_enum.dart';
import 'package:gamify_todo/8%20Model/store_item_model.dart';

class AddStoreItemProvider with ChangeNotifier {
  // Widget variables
  TextEditingController taskNameController = TextEditingController();
  int targetCount = 1;
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
        isTimerActive: selectedTaskType == TaskTypeEnum.TIMER ? existingItem.isTimerActive : null,
      ),
    );
  }
}
