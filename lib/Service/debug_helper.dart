import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Service/hive_service.dart';

class DebugHelper {
  static void debugRoutineScheduling() {
    debugPrint('=== ROUTINE SCHEDULING DEBUG ===');
    
    final routines = TaskProvider().routineList;
    final today = DateTime.now();
    
    debugPrint('Total routines: ${routines.length}');
    debugPrint('Today: $today (weekday: ${today.weekday})');
    debugPrint('Today weekday-1: ${today.weekday - 1}');
    
    for (int i = 0; i < routines.length; i++) {
      final routine = routines[i];
      debugPrint('\n--- Routine ${i + 1}: ${routine.title} ---');
      debugPrint('ID: ${routine.id}');
      debugPrint('Repeat days: ${routine.repeatDays}');
      debugPrint('Start date: ${routine.startDate}');
      debugPrint('Is archived: ${routine.isArchived}');
      debugPrint('Notification on: ${routine.isNotificationOn}');
      debugPrint('Alarm on: ${routine.isAlarmOn}');
      debugPrint('Time: ${routine.time}');
      
      // Check if routine should be active today
      final shouldBeActiveToday = routine.isActiveForThisDate(today);
      debugPrint('Should be active today: $shouldBeActiveToday');
      
      if (!shouldBeActiveToday) {
        debugPrint('Reason not active:');
        debugPrint('  - Contains today weekday (${today.weekday - 1}): ${routine.repeatDays.contains(today.weekday - 1)}');
        debugPrint('  - Start date check: ${routine.startDate == null ? 'null (OK)' : '${routine.startDate!.isBeforeOrSameDay(today)} (${routine.startDate})'}');
        debugPrint('  - Not archived: ${!routine.isArchived}');
      }
      
      // Check for the next few days
      for (int day = 0; day < 7; day++) {
        final checkDate = today.add(Duration(days: day));
        final isActive = routine.isActiveForThisDate(checkDate);
        debugPrint('  ${checkDate.toString().split(' ')[0]} (${checkDate.weekday}): $isActive');
      }
    }
    
    // Check existing tasks from routines
    final routineTasks = TaskProvider().taskList.where((task) => task.routineID != null).toList();
    debugPrint('\n=== EXISTING ROUTINE TASKS ===');
    debugPrint('Total routine tasks: ${routineTasks.length}');
    
    for (final task in routineTasks) {
      debugPrint('Task: ${task.title} (Routine ID: ${task.routineID}, Date: ${task.taskDate})');
    }
  }
  
  static Future<void> debugNotificationSetup() async {
    debugPrint('=== NOTIFICATION SETUP DEBUG ===');
    
    final notificationService = NotificationService();
    
    // Check permissions
    final hasNotificationPermission = await notificationService.checkNotificationPermissions();
    debugPrint('Notification permission: $hasNotificationPermission');
    
    if (!hasNotificationPermission) {
      debugPrint('Requesting notification permission...');
      final granted = await notificationService.requestNotificationPermissions();
      debugPrint('Permission granted: $granted');
    }
    
    // Test immediate notification
    debugPrint('Testing immediate notification...');
    try {
      await notificationService.notificationTest();
      debugPrint('✓ Test notification sent');
    } catch (e) {
      debugPrint('✗ Error sending test notification: $e');
    }
  }
  
  static Future<void> debugTaskCreationFromRoutines() async {
    debugPrint('=== TASK CREATION FROM ROUTINES DEBUG ===');
    
    // Force recreation of tasks from routines
    try {
      await HiveService().createTasksFromRoutines();
      debugPrint('✓ createTasksFromRoutines completed');
    } catch (e) {
      debugPrint('✗ Error in createTasksFromRoutines: $e');
    }
    
    // Check results
    final routineTasks = TaskProvider().taskList.where((task) => task.routineID != null).toList();
    debugPrint('Routine tasks after creation: ${routineTasks.length}');
    
    final today = DateTime.now();
    final todayTasks = routineTasks.where((task) => 
      task.taskDate != null && task.taskDate!.isSameDay(today)
    ).toList();
    
    debugPrint('Today\'s routine tasks: ${todayTasks.length}');
    for (final task in todayTasks) {
      debugPrint('  - ${task.title} (Time: ${task.time}, Notif: ${task.isNotificationOn}, Alarm: ${task.isAlarmOn})');
    }
  }
  
  static Future<void> runFullDebug() async {
    debugPrint('\n🔍 STARTING FULL DEBUG SESSION 🔍\n');
    
    debugRoutineScheduling();
    await debugNotificationSetup();
    await debugTaskCreationFromRoutines();
    
    debugPrint('\n✅ FULL DEBUG SESSION COMPLETED ✅\n');
  }
}
