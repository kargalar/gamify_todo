import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/Enums/status_enum.dart';
import 'package:gamify_todo/Core/Handlers/task_action_handler.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Home/Widget/Task%20Item/Widgets/priority_line.dart';
import 'package:gamify_todo/Page/Home/Widget/Task%20Item/Widgets/subtask_list.dart';
import 'package:gamify_todo/Page/Home/Widget/Task%20Item/Widgets/task_location.dart';
import 'package:gamify_todo/Page/Home/Widget/Task%20Item/Widgets/task_time.dart';
import 'package:gamify_todo/Page/Home/Widget/Task%20Item/Widgets/title_and_decription.dart';
import 'package:gamify_todo/Page/Home/Widget/task_slide_actions.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/task_model.dart';

class TaskItem extends StatefulWidget {
  const TaskItem({
    super.key,
    required this.taskModel,
    this.isRoutine = false,
  });

  final TaskModel taskModel;
  final bool isRoutine;

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
                        Column(
                          children: [
                            TaskTime(taskModel: widget.taskModel),
                            if (widget.taskModel.location != null && widget.taskModel.location!.isNotEmpty) TaskLocation(taskModel: widget.taskModel),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.taskModel.subtasks != null && widget.taskModel.subtasks!.isNotEmpty) SubtaskList(taskModel: widget.taskModel),
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
    await TaskActionHandler.handleTaskLongPress(widget.taskModel);
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

    // Use the TaskActionHandler to handle the task action
    TaskActionHandler.handleTaskAction(
      widget.taskModel,
      onStateChanged: () {
        if (!_isIncrementing) {
          setState(() {});
        }
      },
    );
  }
}
