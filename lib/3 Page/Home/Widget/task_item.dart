import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/1%20Core/Enums/status_enum.dart';
import 'package:gamify_todo/1%20Core/extensions.dart';
import 'package:gamify_todo/1%20Core/helper.dart';
import 'package:gamify_todo/2%20General/app_colors.dart';
import 'package:gamify_todo/3%20Page/Home/Add%20Task/add_task_page.dart';
import 'package:gamify_todo/3%20Page/Home/Widget/Task%20Item/Widgets/priority_line.dart';
import 'package:gamify_todo/3%20Page/Home/Widget/Task%20Item/Widgets/title_and_decription.dart';
import 'package:gamify_todo/3%20Page/Home/Widget/Task%20Item/Widgets/task_time.dart';
import 'package:gamify_todo/3%20Page/Home/Widget/task_slide_actions.dart';
import 'package:gamify_todo/3%20Page/Task%20Detail%20Page/routine_detail_page.dart';
import 'package:gamify_todo/5%20Service/app_helper.dart';
import 'package:gamify_todo/5%20Service/global_timer.dart';
import 'package:gamify_todo/5%20Service/home_widget_service.dart';
import 'package:gamify_todo/5%20Service/locale_keys.g.dart';
import 'package:gamify_todo/5%20Service/navigator_service.dart';
import 'package:gamify_todo/5%20Service/server_manager.dart';
import 'package:gamify_todo/6%20Provider/task_provider.dart';
import 'package:gamify_todo/7%20Enum/task_status_enum.dart';
import 'package:gamify_todo/7%20Enum/task_type_enum.dart';
import 'package:gamify_todo/8%20Model/task_model.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';

class TaskItem extends StatefulWidget {
  const TaskItem({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  bool _isIncrementing = false;

  @override
  Widget build(BuildContext context) {
    return TaskSlideActinos(
      taskModel: widget.taskModel,
      child: Opacity(
        opacity: widget.taskModel.status != null && !(widget.taskModel.type == TaskTypeEnum.TIMER && widget.taskModel.isTimerActive!) ? 0.6 : 1.0,
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            // TaskProgressContainer(taskModel: widget.taskModel),
            InkWell(
              onTap: () {
                taskAction();
              },
              onLongPress: () async {
                await taskLongPressAction();
              },
              borderRadius: AppColors.borderRadiusAll,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: widget.taskModel.type == TaskTypeEnum.TIMER && widget.taskModel.isTimerActive! ? null : AppColors.borderRadiusAll,
                    ),
                    child: Row(
                      children: [
                        taskActionIcon(),
                        const SizedBox(width: 5),
                        TitleAndDescription(taskModel: widget.taskModel),
                        const SizedBox(width: 10),
                        TaskTime(taskModel: widget.taskModel),
                      ],
                    ),
                  ),
                  PriorityLine(taskModel: widget.taskModel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> taskLongPressAction() async {
    if (widget.taskModel.routineID != null) {
      await NavigatorService()
          .goTo(
        RoutineDetailPage(taskModel: widget.taskModel),
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
        AddTaskPage(editTask: widget.taskModel),
        transition: Transition.size,
      )
          .then(
        (value) {
          TaskProvider().updateItems();
        },
      );
    }
  }

  Widget taskActionIcon() {
    final priorityColor = (widget.taskModel.priority == 1
            ? AppColors.red
            : widget.taskModel.priority == 2
                ? AppColors.orange2
                : AppColors.text)
        .withValues(alpha: 0.9);

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
      ),
      child: widget.taskModel.type == TaskTypeEnum.COUNTER
          ? GestureDetector(
              onTap: () => taskAction(),
              onLongPressStart: (_) async {
                _isIncrementing = true;
                while (_isIncrementing && mounted) {
                  setState(() {
                    taskAction();
                  });
                  await Future.delayed(const Duration(milliseconds: 80));
                }
              },
              onLongPressEnd: (_) {
                _isIncrementing = false;
              },
              child: Icon(
                Icons.add,
                size: 27,
                color: priorityColor,
              ),
            )
          : Icon(
              widget.taskModel.type == TaskTypeEnum.CHECKBOX
                  ? widget.taskModel.status == TaskStatusEnum.COMPLETED
                      ? Icons.check_box
                      : Icons.check_box_outline_blank
                  : widget.taskModel.isTimerActive!
                      ? Icons.pause
                      : Icons.play_arrow,
              size: 27,
              color: priorityColor,
            ),
    );
  }

  void taskAction() {
    if (widget.taskModel.status == TaskStatusEnum.ARCHIVED) {
      return Helper().getMessage(
        status: StatusEnum.WARNING,
        // TODO: localization
        message: "Bu task arşivlendiği için etkileşimde bulunulamaz.",
      );
    } else if (widget.taskModel.routineID != null && !widget.taskModel.taskDate.isBeforeOrSameDay(DateTime.now())) {
      return Helper().getMessage(
        status: StatusEnum.WARNING,
        message: LocaleKeys.RoutineForFuture.tr(),
      );
    }

    if (widget.taskModel.type == TaskTypeEnum.CHECKBOX) {
      if (widget.taskModel.status == null || widget.taskModel.status != TaskStatusEnum.COMPLETED) {
        widget.taskModel.status = TaskStatusEnum.COMPLETED;
        AppHelper().addCreditByProgress(widget.taskModel.remainingDuration);
      } else {
        widget.taskModel.status = null;
        AppHelper().addCreditByProgress(widget.taskModel.remainingDuration != null ? -widget.taskModel.remainingDuration! : null);
      }

      HomeWidgetService.updateTaskCount();
    } else if (widget.taskModel.type == TaskTypeEnum.COUNTER) {
      widget.taskModel.currentCount = widget.taskModel.currentCount! + 1;

      AppHelper().addCreditByProgress(widget.taskModel.remainingDuration);

      if (widget.taskModel.currentCount! >= widget.taskModel.targetCount!) {
        widget.taskModel.status = TaskStatusEnum.COMPLETED;
        HomeWidgetService.updateTaskCount();
      }
    } else {
      GlobalTimer().startStopTimer(
        taskModel: widget.taskModel,
      );
    }

    ServerManager().updateTask(taskModel: widget.taskModel);

    if (!_isIncrementing) {
      TaskProvider().updateItems();
    }
  }
}
