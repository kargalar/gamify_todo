import 'package:flutter/foundation.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Enum/task_type_enum.dart';

class WidgetDebugService {
  static void debugWidgetData() {
    if (kDebugMode) {
      debugPrint('=== WIDGET DEBUG SERVICE ===');

      final taskProvider = TaskProvider();
      final today = DateTime.now();

      debugPrint('Today: $today');
      debugPrint('Total tasks in taskList: ${taskProvider.taskList.length}');

      // Debug all tasks
      for (var task in taskProvider.taskList) {
        debugPrint('Task: ${task.title}');
        debugPrint('  ID: ${task.id}');
        debugPrint('  Date: ${task.taskDate}');
        debugPrint('  Is today: ${task.taskDate?.isSameDay(today)}');
        debugPrint('  Routine ID: ${task.routineID}');
        debugPrint('  Status: ${task.status}');
        debugPrint('  Is incomplete: ${task.status == null}');
      }

      // Debug today's tasks using our widget logic
      final todayTasks = taskProvider.taskList.where((task) => task.taskDate?.isSameDay(today) == true && task.routineID == null && task.status == null).toList();

      final routineTasks = taskProvider.taskList.where((task) => task.taskDate?.isSameDay(today) == true && task.routineID != null && task.status == null).toList();

      debugPrint('Today tasks (non-routine, incomplete): ${todayTasks.length}');
      for (var task in todayTasks) {
        debugPrint('  - ${task.title}');
      }

      debugPrint('Routine tasks (today, incomplete): ${routineTasks.length}');
      for (var task in routineTasks) {
        debugPrint('  - ${task.title}');
      }

      final allIncompleteTasks = [...todayTasks, ...routineTasks];
      debugPrint('Total incomplete tasks for today: ${allIncompleteTasks.length}');

      // Test widget update
      debugPrint('Triggering widget update...');
      HomeWidgetService.updateAllWidgets();
    }
  }

  static void debugTaskProvider() {
    if (kDebugMode) {
      debugPrint('=== TASK PROVIDER DEBUG ===');

      final taskProvider = TaskProvider();
      final today = DateTime.now();

      // Test the original methods
      final originalTodayTasks = taskProvider.getTasksForDate(today);
      final originalRoutineTasks = taskProvider.getRoutineTasksForDate(today);

      debugPrint('Original getTasksForDate: ${originalTodayTasks.length}');
      debugPrint('Original getRoutineTasksForDate: ${originalRoutineTasks.length}');
      debugPrint('showCompleted setting: ${taskProvider.showCompleted}');

      for (var task in originalTodayTasks) {
        debugPrint('  Task: ${task.title} - Status: ${task.status}');
      }

      for (var task in originalRoutineTasks) {
        debugPrint('  Routine: ${task.title} - Status: ${task.status}');
      }
    }
  }

  static void createTestTasksForWidget() {
    if (kDebugMode) {
      debugPrint('=== CREATING TEST TASKS FOR WIDGET ===');

      final taskProvider = TaskProvider();
      final today = DateTime.now();

      // Create multiple test tasks for today
      final testTasks = ['Complete project documentation', 'Review code changes', 'Update widget implementation', 'Test scrollable functionality', 'Fix UI design issues', 'Implement new features', 'Write unit tests', 'Update README file', 'Optimize performance', 'Deploy to production'];

      for (int i = 0; i < testTasks.length; i++) {
        final task = TaskModel(
          id: 10000 + i, // Use high IDs to avoid conflicts
          title: testTasks[i],
          type: TaskTypeEnum.CHECKBOX,
          taskDate: today,
          isNotificationOn: false,
          isAlarmOn: false,
          priority: (i % 3) + 1, // Rotate between priorities 1, 2, 3
        );

        taskProvider.taskList.add(task);
      }

      debugPrint('Added ${testTasks.length} test tasks for today');

      // Update widget
      HomeWidgetService.updateAllWidgets();

      debugPrint('Widget updated with test data');
    }
  }

  static void removeTestTasksForWidget() {
    if (kDebugMode) {
      debugPrint('=== REMOVING TEST TASKS FOR WIDGET ===');

      final taskProvider = TaskProvider();

      // Remove test tasks (IDs 10000+)
      taskProvider.taskList.removeWhere((task) => task.id >= 10000);

      debugPrint('Removed test tasks');

      // Update widget
      HomeWidgetService.updateAllWidgets();

      debugPrint('Widget updated after removing test data');
    }
  }

  static Future<void> forceWidgetUpdate() async {
    if (kDebugMode) {
      debugPrint('=== FORCING WIDGET UPDATE ===');

      try {
        await HomeWidgetService.setupHomeWidget();
        await HomeWidgetService.updateAllWidgets();
        debugPrint('Force widget update done successfully');
      } catch (e) {
        debugPrint('Force widget update failed: $e');
      }
    }
  }

  static Future<void> testWidgetWithSampleData() async {
    if (kDebugMode) {
      debugPrint('=== TESTING WIDGET WITH SAMPLE DATA ===');

      // Create sample tasks
      createTestTasksForWidget();

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 500));

      // Force update
      await forceWidgetUpdate();

      debugPrint('Widget test with sample data done');
    }
  }
}
