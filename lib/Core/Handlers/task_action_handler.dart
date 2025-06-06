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
  /// Determines if a task should be considered overdue based on its date and time
  static bool _shouldBeOverdue(TaskModel taskModel) {
    if (taskModel.taskDate == null) return false;

    final now = DateTime.now();
    final taskDate = taskModel.taskDate!;

    // If task has a specific time
    if (taskModel.time != null) {
      final taskDateTime = taskDate.copyWith(
        hour: taskModel.time!.hour,
        minute: taskModel.time!.minute,
        second: 0,
        millisecond: 0,
      );
      return taskDateTime.isBefore(now);
    } else {
      // If task has no specific time, consider it overdue if the date has passed
      final taskDateOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
      final nowDateOnly = DateTime(now.year, now.month, now.day);
      return taskDateOnly.isBefore(nowDateOnly);
    }
  }

  /// Handles the primary action for a task based on its type
  static void handleTaskAction(TaskModel taskModel, {Function? onStateChanged}) {
    final bool wasCompleted = taskModel.status == TaskStatusEnum.COMPLETED;

    if (taskModel.type == TaskTypeEnum.CHECKBOX) {
      // Toggle completion status for checkbox tasks
      if (taskModel.status == TaskStatusEnum.COMPLETED) {
        // When uncompleting a task, check if it should return to overdue status
        if (_shouldBeOverdue(taskModel)) {
          taskModel.status = TaskStatusEnum.OVERDUE;

          // Create log for overdue task
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: TaskStatusEnum.OVERDUE,
          );
        } else {
          // Change from completed to in progress (null)
          taskModel.status = null;

          // Create log for uncompleted checkbox task
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: null, // null status means "in progress"
          );
        }
      } else {
        // Clear any existing status before setting to COMPLETED
        taskModel.status = TaskStatusEnum.COMPLETED;

        // Create log for completed checkbox task
        TaskLogProvider().addTaskLog(
          taskModel,
          customStatus: TaskStatusEnum.COMPLETED,
        );
      }

      HomeWidgetService.updateAllWidgets();
    } else if (taskModel.type == TaskTypeEnum.COUNTER) {
      // Increment counter for counter tasks
      int previousCount = taskModel.currentCount!;
      taskModel.currentCount = previousCount + 1;

      // Create log for counter increment
      TaskLogProvider().addTaskLog(
        taskModel,
        customCount: 1, // Log the increment amount
      );

      AppHelper().addCreditByProgress(taskModel.remainingDuration);

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
      // If already failed, set to null (in progress)
      taskModel.status = null;

      // Create log for the status change to null (in progress)
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: null, // null status means "in progress"
      );
    } else {
      // Set to failed, clearing any other status
      taskModel.status = TaskStatusEnum.FAILED;

      // Create log for failed task
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.FAILED,
      );
    }

    // Update task in provider
    ServerManager().updateTask(taskModel: taskModel);
    TaskProvider().updateItems();
    HomeWidgetService.updateAllWidgets();
  }

  /// Handles task cancellation action
  static void handleTaskCancellation(TaskModel taskModel) {
    if (taskModel.status == TaskStatusEnum.CANCEL) {
      // If already cancelled, set to null (in progress)
      taskModel.status = null;

      // Create log for the status change to null (in progress)
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: null, // null status means "in progress"
      );
    } else {
      // Set to cancelled, clearing any other status
      taskModel.status = TaskStatusEnum.CANCEL;

      // Create log for cancelled task
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.CANCEL,
      );
    }

    // Update task in provider
    ServerManager().updateTask(taskModel: taskModel);
    TaskProvider().updateItems();
    HomeWidgetService.updateAllWidgets();
  }
}
