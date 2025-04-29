import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/add_task_page.dart';
import 'package:gamify_todo/Page/Task%20Detail%20Page/routine_detail_page.dart';
import 'package:gamify_todo/Provider/task_log_provider.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Service/app_helper.dart';
import 'package:gamify_todo/Service/global_timer.dart';
import 'package:gamify_todo/Service/home_widget_service.dart';
import 'package:gamify_todo/Service/navigator_service.dart';
import 'package:gamify_todo/Service/server_manager.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';

/// A centralized handler for task-related actions
class TaskActionHandler {
  /// Handles the primary action for a task based on its type
  static void handleTaskAction(TaskModel taskModel, {Function? onStateChanged}) {
    final bool wasCompleted = taskModel.status == TaskStatusEnum.COMPLETED;

    if (taskModel.type == TaskTypeEnum.CHECKBOX) {
      // Toggle completion status for checkbox tasks
      if (taskModel.status == TaskStatusEnum.COMPLETED) {
        // Change from completed to in progress (null)
        taskModel.status = null;

        // Create log for uncompleted checkbox task
        TaskLogProvider().addTaskLog(
          taskModel,
          customStatus: null, // null status means "in progress"
        );
      } else {
        // Clear any existing status before setting to COMPLETED
        taskModel.status = TaskStatusEnum.COMPLETED;

        // Create log for completed checkbox task
        TaskLogProvider().addTaskLog(
          taskModel,
          customStatus: TaskStatusEnum.COMPLETED,
        );
      }

      HomeWidgetService.updateTaskCount();
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

        HomeWidgetService.updateTaskCount();
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
    bool wasFailed = taskModel.status == TaskStatusEnum.FAILED;

    if (taskModel.status == TaskStatusEnum.FAILED) {
      // If already failed, set to null (in progress)
      taskModel.status = null;
    } else {
      // Set to failed, clearing any other status
      taskModel.status = TaskStatusEnum.FAILED;
    }

    // Create log for failed task only if status is changing to FAILED
    if (!wasFailed && taskModel.status == TaskStatusEnum.FAILED) {
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.FAILED,
      );
    }

    // Update task in provider
    ServerManager().updateTask(taskModel: taskModel);
    TaskProvider().updateItems();
    HomeWidgetService.updateTaskCount();
  }

  /// Handles task cancellation action
  static void handleTaskCancellation(TaskModel taskModel) {
    bool wasCancelled = taskModel.status == TaskStatusEnum.CANCEL;

    if (taskModel.status == TaskStatusEnum.CANCEL) {
      // If already cancelled, determine what to set it to
      if (taskModel.type == TaskTypeEnum.COUNTER && taskModel.currentCount! >= taskModel.targetCount!) {
        taskModel.status = TaskStatusEnum.COMPLETED;
      } else if (taskModel.type == TaskTypeEnum.TIMER && taskModel.currentDuration! >= taskModel.remainingDuration!) {
        taskModel.status = TaskStatusEnum.COMPLETED;
      } else {
        taskModel.status = null;
      }
    } else {
      // Set to cancelled, clearing any other status
      taskModel.status = TaskStatusEnum.CANCEL;
    }

    // Create log for cancelled task only if status is changing to CANCEL
    if (!wasCancelled && taskModel.status == TaskStatusEnum.CANCEL) {
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.CANCEL,
      );
    } else if (!wasCancelled && taskModel.status == TaskStatusEnum.COMPLETED) {
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.COMPLETED,
      );
    }

    // Update task in provider
    ServerManager().updateTask(taskModel: taskModel);
    TaskProvider().updateItems();
    HomeWidgetService.updateTaskCount();
  }
}
