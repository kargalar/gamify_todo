import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:next_level/Provider/task_provider.dart';

class HomeWidgetService {
  static const String appGroupId = 'app.nextlevel.widget';
  static const String taskCountKey = 'taskCount';

  static Future<void> updateTaskCount() async {
    final taskProvider = TaskProvider();
    final todayTasks = taskProvider.getTasksForDate(DateTime.now());
    final routineTasks = taskProvider.getRoutineTasksForDate(DateTime.now());

    final incompleteTasks = todayTasks.where((task) => task.status == null).length + routineTasks.where((task) => task.status == null).length;

    try {
      await HomeWidget.saveWidgetData(taskCountKey, incompleteTasks);
      await HomeWidget.updateWidget(
        androidName: 'TaskWidgetProvider',
        iOSName: 'TaskWidget',
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  static Future<void> setupHomeWidget() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  // reset
  static Future<void> resetHomeWidget() async {
    await HomeWidget.saveWidgetData(taskCountKey, -1);
    await HomeWidget.updateWidget(
      androidName: 'TaskWidgetProvider',
      iOSName: 'TaskWidget',
    );
  }
}
