import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gamify_todo/1%20Core/Enums/status_enum.dart';
import 'package:gamify_todo/1%20Core/extensions.dart';
import 'package:gamify_todo/1%20Core/helper.dart';
import 'package:gamify_todo/2%20General/app_colors.dart';
import 'package:gamify_todo/3%20Page/Home/Widget/task_slide_actions.dart';
import 'package:gamify_todo/5%20Service/global_timer.dart';
import 'package:gamify_todo/6%20Provider/task_provider.dart';
import 'package:gamify_todo/7%20Enum/task_type_enum.dart';
import 'package:gamify_todo/8%20Model/task_model.dart';

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
  @override
  Widget build(BuildContext context) {
    return TaskSlideActinos(
      taskModel: widget.taskModel,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          progress(),
          InkWell(
            onTap: () {
              // rutin bugüne ait olmadığı için etkilşime bulunulamaz
              if (widget.taskModel.rutinID != null && !Helper().isSameDay(widget.taskModel.taskDate, DateTime.now())) {
                Helper().getMessage(
                  status: StatusEnum.WARNING,
                  message: "Rutin bugüne ait olmadığı için etkilşime bulunulamaz" "${widget.taskModel.rutinID}",
                );
              } else {
                taskAction();
              }
            },
            onLongPress: () {
              // task detaylarına git ordan da düzenlemek için ayrı gidecek
            },
            borderRadius: AppColors.borderRadiusAll,
            child: Container(
              height: 70,
              padding: const EdgeInsets.all(8),
              color: AppColors.transparent,
              child: Row(
                children: [
                  taskActionIcon(),
                  const SizedBox(width: 10),
                  titleAndProgressWidgets(),
                  const Spacer(),
                  notificationWidgets(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  AnimatedContainer progress() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 2,
      width: widget.taskModel.isCompleted
          ? 1.sw
          : widget.taskModel.type == TaskTypeEnum.TIMER
              ? widget.taskModel.currentDuration!.inMilliseconds / widget.taskModel.remainingDuration!.inMilliseconds * 1.sw
              : widget.taskModel.type == TaskTypeEnum.COUNTER
                  ? widget.taskModel.currentCount! / widget.taskModel.targetCount! * 1.sw
                  : 0.sw,
      decoration: BoxDecoration(
        color: AppColors.deepMain,
      ),
    );
  }

  Widget taskActionIcon() {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Icon(
        widget.taskModel.type == TaskTypeEnum.CHECKBOX
            ? widget.taskModel.isCompleted
                ? Icons.check_box
                : Icons.check_box_outline_blank
            : widget.taskModel.type == TaskTypeEnum.COUNTER
                ? Icons.add
                : widget.taskModel.isTimerActive!
                    ? Icons.pause
                    : Icons.play_arrow,
        size: 30,
      ),
    );
  }

  void taskAction() {
    if (widget.taskModel.type == TaskTypeEnum.CHECKBOX) {
      widget.taskModel.isCompleted = !widget.taskModel.isCompleted;
    } else if (widget.taskModel.type == TaskTypeEnum.COUNTER) {
      widget.taskModel.currentCount = widget.taskModel.currentCount! + 1;

      if (widget.taskModel.currentCount! >= widget.taskModel.targetCount!) {
        widget.taskModel.isCompleted = true;
      }
    } else {
      GlobalTimer().startStopTimer(
        taskModel: widget.taskModel,
      );
    }

    TaskProvider().updateItems();
  }

  Widget titleAndProgressWidgets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.taskModel.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            decoration: widget.taskModel.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        widget.taskModel.type == TaskTypeEnum.CHECKBOX
            ? const SizedBox()
            : widget.taskModel.type == TaskTypeEnum.COUNTER
                ? Text(
                    "${widget.taskModel.currentCount ?? 0}/${widget.taskModel.targetCount ?? 0}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Text(
                    "${widget.taskModel.remainingDuration!.inHours > 0 ? widget.taskModel.currentDuration!.textShort3() : widget.taskModel.currentDuration!.textShort2()}/${widget.taskModel.remainingDuration!.textShortDynamic()}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
      ],
    );
  }

  Widget notificationWidgets() {
    return Row(
      children: [
        if (widget.taskModel.time != null) ...[
          Text(
            widget.taskModel.time!.to24hours(),
          ),
          const SizedBox(width: 5),
        ],
        if (widget.taskModel.isNotificationOn) ...[
          Icon(
            Icons.alarm,
            color: AppColors.deepMain,
          ),
        ],
      ],
    );
  }
}