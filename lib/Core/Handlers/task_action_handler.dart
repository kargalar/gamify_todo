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
    bool shouldCreateLog = false;

    if (taskModel.type == TaskTypeEnum.CHECKBOX) {
      // Toggle completion status for checkbox tasks
      if (taskModel.status == TaskStatusEnum.COMPLETED) {
        taskModel.status = null;
      } else {
        taskModel.status = TaskStatusEnum.COMPLETED;
        shouldCreateLog = true;
      }

      HomeWidgetService.updateTaskCount();
    } else if (taskModel.type == TaskTypeEnum.COUNTER) {
      // Increment counter for counter tasks
      int previousCount = taskModel.currentCount!;
      taskModel.currentCount = previousCount + 1;

      AppHelper().addCreditByProgress(taskModel.remainingDuration);
      shouldCreateLog = true;

      if (taskModel.currentCount! >= taskModel.targetCount! && !wasCompleted) {
        taskModel.status = TaskStatusEnum.COMPLETED;
        HomeWidgetService.updateTaskCount();
      }
    } else if (taskModel.type == TaskTypeEnum.TIMER) {
      // Toggle timer for timer tasks
      // Toggle timer using startStopTimer
      GlobalTimer().startStopTimer(taskModel: taskModel);

      // If timer was active, we need to create a log
      if (taskModel.isTimerActive!) {
        shouldCreateLog = true;
      }
    }

    // Create log if needed
    if (shouldCreateLog) {
      TaskLogProvider().addTaskLog(
        taskModel,
        customCount: taskModel.type == TaskTypeEnum.COUNTER ? 1 : null,
        customDuration: taskModel.type == TaskTypeEnum.TIMER ? taskModel.currentDuration : null,
      );
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
    taskModel.status = TaskStatusEnum.FAILED;

    // Create log for failed task
    TaskLogProvider().addTaskLog(
      taskModel,
      customStatus: TaskStatusEnum.FAILED,
    );

    // Update task in provider
    ServerManager().updateTask(taskModel: taskModel);
    TaskProvider().updateItems();
    HomeWidgetService.updateTaskCount();
  }

  /// Handles task cancellation action
  static void handleTaskCancellation(TaskModel taskModel) {
    taskModel.status = TaskStatusEnum.CANCEL;

    // Create log for cancelled task
    TaskLogProvider().addTaskLog(
      taskModel,
      customStatus: TaskStatusEnum.CANCEL,
    );

    // Update task in provider
    ServerManager().updateTask(taskModel: taskModel);
    TaskProvider().updateItems();
    HomeWidgetService.updateTaskCount();
  }
}
