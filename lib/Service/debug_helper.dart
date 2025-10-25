import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Service/hive_service.dart';
import 'logging_service.dart';

class DebugHelper {
  static void debugRoutineScheduling() {
    LogService.debug('=== ROUTINE SCHEDULING DEBUG ===');

    final routines = TaskProvider().routineList;
    final today = DateTime.now();

    LogService.debug('Total routines: ${routines.length}');
    LogService.debug('Today: $today (weekday: ${today.weekday})');
    LogService.debug('Today weekday-1: ${today.weekday - 1}');

    for (int i = 0; i < routines.length; i++) {
      final routine = routines[i];
      LogService.debug('\n--- Routine ${i + 1}: ${routine.title} ---');
      LogService.debug('ID: ${routine.id}');
      LogService.debug('Repeat days: ${routine.repeatDays}');
      LogService.debug('Start date: ${routine.startDate}');
      LogService.debug('Is archived: ${routine.isArchived}');
      LogService.debug('Notification on: ${routine.isNotificationOn}');
      LogService.debug('Alarm on: ${routine.isAlarmOn}');
      LogService.debug('Time: ${routine.time}');

      // Check if routine should be active today
      final shouldBeActiveToday = routine.isActiveForThisDate(today);
      LogService.debug('Should be active today: $shouldBeActiveToday');

      if (!shouldBeActiveToday) {
        LogService.debug('Reason not active:');
        LogService.debug('  - Contains today weekday (${today.weekday - 1}): ${routine.repeatDays.contains(today.weekday - 1)}');
        LogService.debug('  - Start date check: ${routine.startDate == null ? 'null (OK)' : '${routine.startDate!.isBeforeOrSameDay(today)} (${routine.startDate})'}');
        LogService.debug('  - Not archived: ${!routine.isArchived}');
      }

      // Check for the next few days
      for (int day = 0; day < 7; day++) {
        final checkDate = today.add(Duration(days: day));
        final isActive = routine.isActiveForThisDate(checkDate);
        LogService.debug('  ${checkDate.toString().split(' ')[0]} (${checkDate.weekday}): $isActive');
      }
    }

    // Check existing tasks from routines
    final routineTasks = TaskProvider().taskList.where((task) => task.routineID != null).toList();
    LogService.debug('\n=== EXISTING ROUTINE TASKS ===');
    LogService.debug('Total routine tasks: ${routineTasks.length}');

    for (final task in routineTasks) {
      LogService.debug('Task: ${task.title} (Routine ID: ${task.routineID}, Date: ${task.taskDate})');
    }
  }

  static Future<void> debugNotificationSetup() async {
    LogService.debug('=== NOTIFICATION SETUP DEBUG ===');

    final notificationService = NotificationService();

    // Check permissions
    final hasNotificationPermission = await notificationService.checkNotificationPermissions();
    LogService.debug('Notification permission: $hasNotificationPermission');

    if (!hasNotificationPermission) {
      LogService.debug('Requesting notification permission...');
      final granted = await notificationService.requestNotificationPermissions();
      LogService.debug('Permission granted: $granted');
    }

    // Test immediate notification
    LogService.debug('Testing immediate notification...');
    try {
      await notificationService.notificationTest();
      LogService.debug('✓ Test notification sent');
    } catch (e) {
      LogService.error('✗ Error sending test notification: $e');
    }
  }

  static Future<void> debugTaskCreationFromRoutines() async {
    LogService.debug('=== TASK CREATION FROM ROUTINES DEBUG ===');

    // Force recreation of tasks from routines
    try {
      await HiveService().createTasksFromRoutines();
      LogService.debug('✓ createTasksFromRoutines done');
    } catch (e) {
      LogService.error('✗ Error in createTasksFromRoutines: $e');
    }

    // Check results
    final routineTasks = TaskProvider().taskList.where((task) => task.routineID != null).toList();
    LogService.debug('Routine tasks after creation: ${routineTasks.length}');

    final today = DateTime.now();
    final todayTasks = routineTasks.where((task) => task.taskDate != null && task.taskDate!.isSameDay(today)).toList();

    LogService.debug('Today\'s routine tasks: ${todayTasks.length}');
    for (final task in todayTasks) {
      LogService.debug('  - ${task.title} (Time: ${task.time}, Notif: ${task.isNotificationOn}, Alarm: ${task.isAlarmOn})');
    }
  }

  static Future<void> runFullDebug() async {
    LogService.debug('\n🔍 STARTING FULL DEBUG SESSION 🔍\n');

    // debugRoutineScheduling();
    await debugNotificationSetup();
    // await debugTaskCreationFromRoutines();

    LogService.debug('\n✅ FULL DEBUG SESSION DONE ✅\n');
  }
}
