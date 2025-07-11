import 'package:flutter/services.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Page/Task%20Detail%20Page/routine_detail_page.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/app_helper.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';

/// A centralized handler for task-related actions
class TaskActionHandler {
  /// Handles the primary action for a task based on its type
  static void handleTaskAction(TaskModel taskModel, {Function? onStateChanged, bool skipLogging = false, int? batchChange}) {
    final bool wasCompleted = taskModel.status == TaskStatusEnum.COMPLETED;

    // Handle batch change for counter tasks
    if (batchChange != null && taskModel.type == TaskTypeEnum.COUNTER) {
      int previousCount = taskModel.currentCount!;
      taskModel.currentCount = previousCount + batchChange;

      // Create a single batch log for the total change
      TaskLogProvider().addTaskLog(
        taskModel,
        customCount: batchChange, // Log the total batch change
      );

      // Calculate credit for the batch change
      Duration creditPerIncrement = taskModel.remainingDuration! ~/ taskModel.targetCount!;
      AppHelper().addCreditByProgress(creditPerIncrement * batchChange);

      if (taskModel.currentCount! >= taskModel.targetCount! && !wasCompleted) {
        // Clear any existing status before setting to COMPLETED
        taskModel.status = TaskStatusEnum.COMPLETED;

        // Create log for completed counter task
        TaskLogProvider().addTaskLog(
          taskModel,
          customStatus: TaskStatusEnum.COMPLETED,
        );

        HomeWidgetService.updateAllWidgets();
      }

      // Update task in provider and save
      ServerManager().updateTask(taskModel: taskModel);
      TaskProvider().updateItems();

      if (onStateChanged != null) onStateChanged();
      return;
    }
    if (taskModel.type == TaskTypeEnum.CHECKBOX) {
      // Toggle completion status for checkbox tasks
      if (taskModel.status == TaskStatusEnum.COMPLETED) {
        // When uncompleting a task, check if it should be overdue based on date
        if (taskModel.taskDate != null) {
          final now = DateTime.now();
          final taskDateTime = taskModel.taskDate!.copyWith(
            hour: taskModel.time?.hour ?? 23,
            minute: taskModel.time?.minute ?? 59,
            second: 59,
          );

          if (taskDateTime.isBefore(now)) {
            // Task date is in the past, mark as overdue
            taskModel.status = TaskStatusEnum.OVERDUE;

            // Create log for overdue status (unless logging is skipped)
            if (!skipLogging) {
              TaskLogProvider().addTaskLog(
                taskModel,
                customStatus: TaskStatusEnum.OVERDUE,
              );
            }
          } else {
            // Task date is in the future or today, set to in progress
            taskModel.status = null;

            // Create log for uncompleted checkbox task (unless logging is skipped)
            if (!skipLogging) {
              TaskLogProvider().addTaskLog(
                taskModel,
                customStatus: null, // null status means "in progress"
              );
            }
          }
        } else {
          // Dateless task, set to in progress
          taskModel.status = null;

          // Create log for uncompleted checkbox task (unless logging is skipped)
          if (!skipLogging) {
            TaskLogProvider().addTaskLog(
              taskModel,
              customStatus: null, // null status means "in progress"
            );
          }
        }

        // Subtract credit for uncompleting the task
        if (taskModel.remainingDuration != null) {
          AppHelper().addCreditByProgress(-taskModel.remainingDuration!);
        }

        // Update task in provider and save
        ServerManager().updateTask(taskModel: taskModel);
        HomeWidgetService.updateAllWidgets();
      } else {
        // Add haptic feedback when completing a checkbox task
        HapticFeedback.lightImpact();

        // Use the new undo functionality for completion
        TaskProvider().completeTaskWithUndo(taskModel);
        return; // Return early since completeTaskWithUndo handles all updates
      }
    } else if (taskModel.type == TaskTypeEnum.COUNTER) {
      // Increment counter for counter tasks
      int previousCount = taskModel.currentCount!;
      taskModel.currentCount = previousCount + 1;

      // Create log for counter increment (unless logging is skipped)
      if (!skipLogging) {
        TaskLogProvider().addTaskLog(
          taskModel,
          customCount: 1, // Log the increment amount
        );
      }

      AppHelper().addCreditByProgress(taskModel.remainingDuration);

      if (taskModel.currentCount! >= taskModel.targetCount! && !wasCompleted) {
        // Clear any existing status before setting to COMPLETED
        taskModel.status = TaskStatusEnum.COMPLETED;

        // Create log for completed counter task (unless logging is skipped)
        if (!skipLogging) {
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: TaskStatusEnum.COMPLETED,
          );
        }

        HomeWidgetService.updateAllWidgets();
      }
    } else if (taskModel.type == TaskTypeEnum.TIMER) {
      // Toggle timer for timer tasks
      // Toggle timer using startStopTimer
      GlobalTimer().startStopTimer(taskModel: taskModel);

      // Note: Timer logs are created in the GlobalTimer class when the timer is stopped
    }

    // Update task in provider
    ServerManager().updateTask(taskModel: taskModel);
    TaskProvider().updateItems();

    // Notify state change if callback provided
    if (onStateChanged != null) {
      onStateChanged();
    }
  }

  /// Handles long press action for a task
  static Future<void> handleTaskLongPress(TaskModel taskModel) async {
    if (taskModel.routineID != null) {
      await NavigatorService()
          .goTo(
        RoutineDetailPage(
          taskModel: taskModel,
        ),
        transition: Transition.size,
      )
          .then(
        (value) {
          TaskProvider().updateItems();
        },
      );
    } else {
      await NavigatorService()
          .goTo(
        AddTaskPage(editTask: taskModel),
        transition: Transition.size,
      )
          .then(
        (value) {
          TaskProvider().updateItems();
        },
      );
    }
  }

  /// Handles task failure action
  static void handleTaskFailure(TaskModel taskModel) {
    if (taskModel.status == TaskStatusEnum.FAILED) {
      // If already failed, check if task should be overdue based on date
      if (taskModel.taskDate != null) {
        final now = DateTime.now();
        final taskDateTime = taskModel.taskDate!.copyWith(
          hour: taskModel.time?.hour ?? 23,
          minute: taskModel.time?.minute ?? 59,
          second: 59,
        );

        if (taskDateTime.isBefore(now)) {
          // Task date is in the past, mark as overdue
          taskModel.status = TaskStatusEnum.OVERDUE;

          // Create log for overdue status
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: TaskStatusEnum.OVERDUE,
          );
        } else {
          // Task date is in the future or today, set to in progress
          taskModel.status = null;

          // Create log for the status change to null (in progress)
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: null, // null status means "in progress"
          );
        }
      } else {
        // Dateless task, set to in progress
        taskModel.status = null;

        // Create log for the status change to null (in progress)
        TaskLogProvider().addTaskLog(
          taskModel,
          customStatus: null, // null status means "in progress"
        );
      }

      // Update task in provider
      ServerManager().updateTask(taskModel: taskModel);
      TaskProvider().updateItems();
      HomeWidgetService.updateAllWidgets();
    } else {
      // Store the previous status before changing it
      TaskStatusEnum? previousStatus = taskModel.status;

      // Check if task was previously completed and subtract credit
      if (taskModel.status == TaskStatusEnum.COMPLETED && taskModel.remainingDuration != null) {
        AppHelper().addCreditByProgress(-taskModel.remainingDuration!);
      }

      // Set to failed, clearing any other status
      taskModel.status = TaskStatusEnum.FAILED;

      // Create log for failed task
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.FAILED,
      );

      // Update task in provider
      ServerManager().updateTask(taskModel: taskModel);
      TaskProvider().updateItems();
      HomeWidgetService.updateAllWidgets();

      // Show undo message with previous status
      TaskProvider().showTaskFailureUndoWithPreviousStatus(taskModel, previousStatus);
    }
  }

  /// Handles task cancellation action
  static void handleTaskCancellation(TaskModel taskModel) {
    if (taskModel.status == TaskStatusEnum.CANCEL) {
      // If already cancelled, check if task should be overdue based on date
      if (taskModel.taskDate != null) {
        final now = DateTime.now();
        final taskDateTime = taskModel.taskDate!.copyWith(
          hour: taskModel.time?.hour ?? 23,
          minute: taskModel.time?.minute ?? 59,
          second: 59,
        );

        if (taskDateTime.isBefore(now)) {
          // Task date is in the past, mark as overdue
          taskModel.status = TaskStatusEnum.OVERDUE;

          // Create log for overdue status
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: TaskStatusEnum.OVERDUE,
          );
        } else {
          // Task date is in the future or today, set to in progress
          taskModel.status = null;

          // Create log for the status change to null (in progress)
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: null, // null status means "in progress"
          );
        }
      } else {
        // Dateless task, set to in progress
        taskModel.status = null;

        // Create log for the status change to null (in progress)
        TaskLogProvider().addTaskLog(
          taskModel,
          customStatus: null, // null status means "in progress"
        );
      }

      // Update task in provider
      ServerManager().updateTask(taskModel: taskModel);
      TaskProvider().updateItems();
      HomeWidgetService.updateAllWidgets();
    } else {
      // Store the previous status before changing it
      TaskStatusEnum? previousStatus = taskModel.status;

      // Check if task was previously completed and subtract credit
      if (taskModel.status == TaskStatusEnum.COMPLETED && taskModel.remainingDuration != null) {
        AppHelper().addCreditByProgress(-taskModel.remainingDuration!);
      }

      // Set to cancelled, clearing any other status
      taskModel.status = TaskStatusEnum.CANCEL;

      // Create log for cancelled task
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.CANCEL,
      );

      // Update task in provider
      ServerManager().updateTask(taskModel: taskModel);
      TaskProvider().updateItems();
      HomeWidgetService.updateAllWidgets();

      // Show undo message with previous status
      TaskProvider().showTaskCancellationUndoWithPreviousStatus(taskModel, previousStatus);
    }
  }
}
