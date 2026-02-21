import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Repository/task_log_repository.dart';
import 'package:next_level/Repository/task_repository.dart';
import 'package:next_level/Provider/user_provider.dart';

class TaskLogProvider with ChangeNotifier {
  static final TaskLogProvider _instance = TaskLogProvider._internal();

  factory TaskLogProvider() {
    return _instance;
  }

  TaskLogProvider._internal();

  TaskLogRepository _repository = TaskLogRepository();

  @visibleForTesting
  void setRepository(TaskLogRepository repo) {
    _repository = repo;
  }

  TaskRepository _taskRepository = TaskRepository();

  @visibleForTesting
  void setTaskRepository(TaskRepository repo) {
    _taskRepository = repo;
  }

  TaskProvider? _taskProvider;

  TaskProvider get taskProvider {
    _taskProvider ??= TaskProvider();
    return _taskProvider!;
  }

  @visibleForTesting
  void setTaskProvider(TaskProvider provider) {
    _taskProvider = provider;
  }

  List<TaskLogModel> taskLogList = [];

  Future<void> loadTaskLogs() async {
    taskLogList = await _repository.getTaskLogs();
    notifyListeners();
  }

  Future<void> addTaskLog(
    TaskModel taskModel, {
    DateTime? customLogDate,
    Duration? customDuration,
    int? customCount,
    TaskStatusEnum? customStatus,
  }) async {
    // If a timer is active for this task, stop it before recording the log
    // to prevent overlapping timer state with manual logs. Avoid creating an
    // additional stop log by suppressing it.
    // (import at top ensures availability)
    // Now proceed with normal log creation

    // Get the log date (either custom or now)
    final DateTime logDate = customLogDate ?? DateTime.now();

    // For checkbox tasks, check if there's already a status log for the same day
    if (taskModel.type == TaskTypeEnum.CHECKBOX) {
      // Find logs for this task
      List<TaskLogModel> taskLogs = getLogsByTaskId(taskModel.id);

      // Filter logs for the same day
      List<TaskLogModel> sameDayLogs = taskLogs.where((log) {
        return log.logDate.year == logDate.year && log.logDate.month == logDate.month && log.logDate.day == logDate.day;
      }).toList();

      // Sort logs by date (newest first)
      sameDayLogs.sort((a, b) => b.logDate.compareTo(a.logDate));

      // If there's a status log for the same day, update it instead of creating a new one
      if (sameDayLogs.isNotEmpty) {
        // Get the most recent log for this day
        TaskLogModel existingLog = sameDayLogs.first;

        TaskStatusEnum? oldStatus = existingLog.status;
        TaskStatusEnum? newStatus = customStatus ?? taskModel.status;

        // DP Update Logic for Checkbox status changes
        int dpChange = 0;
        if (oldStatus != TaskStatusEnum.DONE && newStatus == TaskStatusEnum.DONE) dpChange += 1;
        if (oldStatus == TaskStatusEnum.DONE && newStatus != TaskStatusEnum.DONE) dpChange -= 1;
        if (oldStatus != TaskStatusEnum.FAILED && newStatus == TaskStatusEnum.FAILED) dpChange -= 1;
        if (oldStatus == TaskStatusEnum.FAILED && newStatus != TaskStatusEnum.FAILED) dpChange += 1;
        if (dpChange != 0) {
          UserProvider().updateDisciplinePoints(dpChange);
        }
        taskProvider.checkDailyDPBonuses(logDate);

        // Update the existing log with the new status
        existingLog.status = newStatus;
        existingLog.logDate = logDate; // Update timestamp to current time

        // Save the updated log
        await _repository.updateTaskLog(existingLog);

        // Update the log in the provider's list
        final index = taskLogList.indexWhere((log) => log.id == existingLog.id);
        if (index != -1) {
          taskLogList[index] = existingLog;
        }

        notifyListeners();
        return; // Exit early since we've updated an existing log
      }
    }

    // If we get here, either it's not a checkbox task or there's no existing log for today
    // Generate next ID via Repository
    int nextId = await _repository.generateNextId();

    final TaskLogModel taskLog = TaskLogModel(
      id: nextId,
      taskId: taskModel.id,
      routineId: taskModel.routineID,
      logDate: logDate,
      taskTitle: taskModel.title,
      // Eğer customDuration açıkça verilmişse, o değeri kullan
      // Aksi takdirde, sadece checkbox olmayan ve customDuration null olan durumlarda taskModel.currentDuration kullan
      duration: customDuration,
      // Eğer customCount açıkça verilmişse, o değeri kullan
      // Aksi takdirde, sadece counter olan ve customCount null olan durumlarda taskModel.currentCount kullan
      count: customCount,
      // Eğer customStatus açıkça null olarak verilmişse, bu checkbox'ın hiçbir durumunun seçili olmadığını gösterir
      // Ancak UI'da bu, hiçbir durumun seçili olmadığını gösterecek
      status: customStatus ?? taskModel.status,
    );

    // Before saving the log, ensure timer is stopped (if still active)
    if (taskModel.type == TaskTypeEnum.TIMER && (taskModel.isTimerActive ?? false)) {
      // Stop timer without generating an automatic stop log
      GlobalTimer().startStopTimer(taskModel: taskModel, suppressStopLog: true);
    }

    // DP Update Logic for initial log
    TaskStatusEnum? freshStatus = customStatus ?? taskModel.status;
    int dpChange = 0;
    if (freshStatus == TaskStatusEnum.DONE) dpChange += 1;
    if (freshStatus == TaskStatusEnum.FAILED) dpChange -= 1;
    if (dpChange != 0) {
      UserProvider().updateDisciplinePoints(dpChange);
    }
    taskProvider.checkDailyDPBonuses(logDate);

    await _repository.addTaskLog(taskLog);
    taskLogList.add(taskLog);

    await recalculateTaskProgress(taskModel.id);

    // Auto-update log statuses for tracked types to ensure consistency
    if (taskModel.type == TaskTypeEnum.COUNTER) {
      await updateCounterTaskLogStatuses(taskModel);
    } else if (taskModel.type == TaskTypeEnum.TIMER) {
      await updateTimerTaskLogStatuses(taskModel);
    }

    notifyListeners();
  }

  Future<void> addSystemLog(TaskLogModel systemLog) async {
    await _repository.addTaskLog(systemLog);
    taskLogList.add(systemLog);
    notifyListeners();
  }

  Future<void> deleteSystemLogsForTaskAndDate(int taskId, DateTime date) async {
    final logsToDelete = taskLogList.where((log) => log.taskId == taskId && log.logDate.year == date.year && log.logDate.month == date.month && log.logDate.day == date.day).toList();
    for (final log in logsToDelete) {
      await _repository.deleteTaskLog(log.id);
      taskLogList.remove(log);
    }
    notifyListeners();
  }

  List<TaskLogModel> getLogsByTaskId(int taskId) {
    return taskLogList.where((log) => log.taskId == taskId).toList();
  }

  List<TaskLogModel> getLogsByRoutineId(int routineId) {
    return taskLogList.where((log) => log.routineId == routineId).toList();
  }

  List<TaskLogModel> getRecentLogs(int count) {
    // Sort logs by date (newest first) and return the specified count
    final sortedLogs = List<TaskLogModel>.from(taskLogList);
    sortedLogs.sort((a, b) => b.logDate.compareTo(a.logDate));

    return sortedLogs.take(count).toList();
  }

  // Delete all logs associated with a specific task
  Future<void> deleteLogsByTaskId(int taskId) async {
    // Get all logs for this task
    final logsToDelete = taskLogList.where((log) => log.taskId == taskId).toList();

    // Delete each log from Repo
    for (final log in logsToDelete) {
      await _repository.deleteTaskLog(log.id);
      taskLogList.remove(log);
    }

    // Find the task in TaskProvider and reset its status to null
    final taskIndex = taskProvider.taskList.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      // Reset task status to null
      taskProvider.taskList[taskIndex].status = null;
      // Reset progress
      if (taskProvider.taskList[taskIndex].type == TaskTypeEnum.COUNTER) {
        taskProvider.taskList[taskIndex].currentCount = 0;
      } else if (taskProvider.taskList[taskIndex].type == TaskTypeEnum.TIMER) {
        taskProvider.taskList[taskIndex].currentDuration = Duration.zero;
      }

      // Update task in storage using TaskRepository
      await _taskRepository.updateTask(taskProvider.taskList[taskIndex]);
    }

    notifyListeners();
  }

  // Delete all logs associated with a specific routine
  Future<void> deleteLogsByRoutineId(int routineId) async {
    // Get all logs for this routine
    final logsToDelete = taskLogList.where((log) => log.routineId == routineId).toList();

    // Delete each log from Repo
    for (final log in logsToDelete) {
      await _repository.deleteTaskLog(log.id);
      taskLogList.remove(log);
    }

    // Find all tasks associated with this routine and reset their status to null
    final tasksToReset = taskProvider.taskList.where((task) => task.routineID == routineId).toList();

    for (final task in tasksToReset) {
      // Reset task status to null
      task.status = null;
      // Update task in storage using TaskRepository
      await _taskRepository.updateTask(task);
    }

    notifyListeners();
  }

  // Clear all logs from the provider (used when deleting all data)
  Future<void> clearAllLogs() async {
    taskLogList.clear();

    // Reset status of all tasks to null
    for (final task in taskProvider.taskList) {
      task.status = null;
      await _taskRepository.updateTask(task);
    }

    notifyListeners();
  }

  // Delete log by task ID and status (for checkbox tasks when undoing status)
  Future<void> deleteLogByTaskIdAndStatus(int taskId, TaskStatusEnum status) async {
    // Find the log for this task with the specific status
    final logToDelete = taskLogList
        .where(
          (log) => log.taskId == taskId && log.status == status,
        )
        .firstOrNull;

    if (logToDelete != null) {
      await _repository.deleteTaskLog(logToDelete.id);
      taskLogList.remove(logToDelete);
      notifyListeners();
    }
  }

  // Delete a specific log by ID
  Future<void> deleteTaskLog(int logId) async {
    // We need the task ID to recalculate, so find the log before deleting or store the ID
    final logIndex = taskLogList.indexWhere((log) => log.id == logId);
    if (logIndex != -1) {
      final taskId = taskLogList[logIndex].taskId;
      taskLogList.removeAt(logIndex);
      await _repository.deleteTaskLog(logId);

      await recalculateTaskProgress(taskId);

      // Find the task model to check type and get targets
      final taskIndex = taskProvider.taskList.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        final task = taskProvider.taskList[taskIndex];

        // Recalculate status of remaining logs based on task type
        if (task.type == TaskTypeEnum.COUNTER) {
          await updateCounterTaskLogStatuses(task);
        } else if (task.type == TaskTypeEnum.TIMER) {
          await updateTimerTaskLogStatuses(task);
        }
      }
    }

    notifyListeners();
  }

  // Edit a specific log
  Future<void> editTaskLog(int logId, dynamic newValue) async {
    final index = taskLogList.indexWhere((log) => log.id == logId);
    if (index == -1) return;

    final log = taskLogList[index];

    // Update value based on type logic if needed, but here we just update flexible fields.
    // Assuming newValue matches the type (Duration or int).
    if (newValue is int) {
      log.count = newValue;
    } else if (newValue is Duration) {
      log.duration = newValue;
    }

    await _repository.updateTaskLog(log);
    taskLogList[index] = log;

    await recalculateTaskProgress(log.taskId);
    notifyListeners();
  }

  /// Counter task'ın target count'u değiştirildiğinde logları güncelle
  Future<void> updateCounterTaskLogStatuses(TaskModel updatedTask) async {
    if (updatedTask.type != TaskTypeEnum.COUNTER) {
      return; // Sadece counter task'lar için
    }

    final logs = getLogsByTaskId(updatedTask.id);
    if (logs.isEmpty || updatedTask.targetCount == null) {
      return;
    }

    int currentCount = 0;

    // Logları zamana göre sırala (en eski ilk)
    logs.sort((a, b) => a.logDate.compareTo(b.logDate));

    for (final log in logs) {
      // Her log'un count'unu currentCount'a ekle
      if (log.count != null) {
        currentCount += log.count!;
      }

      // Yeni target count'a göre status belirle
      TaskStatusEnum? newStatus;
      if (currentCount >= updatedTask.targetCount!) {
        newStatus = TaskStatusEnum.DONE;
      } else {
        newStatus = null; // Counter task default status null
      }

      // Status değişmişse güncelle
      if (log.status != newStatus) {
        log.status = newStatus;
        // Use Repository to save
        await _repository.updateTaskLog(log);
        notifyListeners();
      }
    }
  }

  /// Timer task'ın duration'u değiştirildiğinde logları güncelle
  Future<void> updateTimerTaskLogStatuses(TaskModel updatedTask) async {
    if (updatedTask.type != TaskTypeEnum.TIMER) {
      return; // Sadece timer task'lar için
    }

    final logs = getLogsByTaskId(updatedTask.id);
    if (logs.isEmpty || updatedTask.remainingDuration == null) {
      return;
    }

    Duration cumulativeDuration = Duration.zero;

    // Logları zamana göre sırala (en eski ilk)
    logs.sort((a, b) => a.logDate.compareTo(b.logDate));

    for (final log in logs) {
      // Her log'un duration'ını cumulativeDuration'a ekle
      if (log.duration != null) {
        cumulativeDuration = cumulativeDuration + log.duration!;
      }

      // Yeni target duration'a göre status belirle
      TaskStatusEnum? newStatus;
      if (cumulativeDuration >= updatedTask.remainingDuration!) {
        newStatus = TaskStatusEnum.DONE;
      } else {
        newStatus = null; // Timer task default status null
      }

      // Status değişmişse güncelle
      if (log.status != newStatus) {
        log.status = newStatus;
        // Use Repository to save
        await _repository.updateTaskLog(log);
        notifyListeners();
      }
    }
  }

  // Existing methods implementation...

  /// Recalculate task progress based on logs
  Future<void> recalculateTaskProgress(int taskId) async {
    final taskIndex = taskProvider.taskList.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = taskProvider.taskList[taskIndex];
    final logs = getLogsByTaskId(taskId); // Gets current logs from memory

    if (task.type == TaskTypeEnum.COUNTER) {
      int totalCount = 0;
      for (var log in logs) {
        if (log.count != null) {
          totalCount += log.count!;
        }
      }
      task.currentCount = totalCount;

      // Update status if needed
      bool isDone = (task.targetCount ?? 0) > 0 && totalCount >= task.targetCount!;
      if (isDone) {
        if (task.status != TaskStatusEnum.DONE) {
          task.status = TaskStatusEnum.DONE;
          UserProvider().updateDisciplinePoints(1);
          taskProvider.checkDailyDPBonuses(DateTime.now());
        }
      } else {
        if (task.status == TaskStatusEnum.DONE) {
          task.status = null;
          UserProvider().updateDisciplinePoints(-1);
        }
      }
    } else if (task.type == TaskTypeEnum.TIMER) {
      Duration totalDuration = Duration.zero;
      for (var log in logs) {
        if (log.duration != null) {
          totalDuration += log.duration!;
        }
      }
      task.currentDuration = totalDuration;

      // Update status if needed
      bool isDone = (task.remainingDuration ?? Duration.zero) > Duration.zero && totalDuration >= task.remainingDuration!;
      if (isDone) {
        if (task.status != TaskStatusEnum.DONE) {
          task.status = TaskStatusEnum.DONE;
          UserProvider().updateDisciplinePoints(1);
          taskProvider.checkDailyDPBonuses(DateTime.now());
        }
      } else {
        if (task.status == TaskStatusEnum.DONE) {
          task.status = null;
          UserProvider().updateDisciplinePoints(-1);
        }
      }
    }

    // Save updated task
    await TaskRepository().updateTask(task);

    // Notify TaskProvider listeners to update UI
    taskProvider.notifyListeners();
  }
}
