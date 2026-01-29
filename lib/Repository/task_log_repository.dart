import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskLogRepository {
  static final TaskLogRepository _instance = TaskLogRepository._internal();
  factory TaskLogRepository() => _instance;
  TaskLogRepository._internal();

  final HiveService _hiveService = HiveService();

  Future<List<TaskLogModel>> getTaskLogs() async {
    try {
      return await _hiveService.getTaskLogs();
    } catch (e) {
      LogService.error('⚠️ TaskLogRepository: Error loading task logs: $e');
      return [];
    }
  }

  Future<int> addTaskLog(TaskLogModel taskLog) async {
    // ID generation logic was in Provider, we should verify if it's better here or usually passed.
    // Provider was doing "highest ID + 1" or "lastLogId from prefs".
    // Ideally this logic belongs here to encapsulate ID management.

    // For now, assuming the Provider constructs the model with an ID or we handle it here.
    // Looking at Provider: it handles ID generation heavily using SharedPreferences.
    // Let's keep it simple: Add to Hive.

    await _hiveService.addTaskLog(taskLog);
    return taskLog.id;
  }

  Future<void> updateTaskLog(TaskLogModel taskLog) async {
    await taskLog.save();
  }

  Future<void> deleteTaskLog(int id) async {
    await _hiveService.deleteTaskLog(id);
  }

  /// Helper to get the next valid ID using SharedPreferences
  /// This encapsulates the logic previously in Provider
  Future<int> generateNextId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int lastLogId = prefs.getInt("last_task_log_id") ?? 0;

    // We should also check Hive to be safe, but adhering to legacy logic of using Prefs + Hive
    final logs = await getTaskLogs();
    int highestLogId = lastLogId;
    for (final log in logs) {
      if (log.id > highestLogId) {
        highestLogId = log.id;
      }
    }

    final nextId = highestLogId + 1;
    await prefs.setInt("last_task_log_id", nextId);
    return nextId;
  }
}
