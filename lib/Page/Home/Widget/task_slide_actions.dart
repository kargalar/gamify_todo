import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gamify_todo/Core/Handlers/task_action_handler.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:provider/provider.dart';

class TaskSlideActinos extends StatefulWidget {
  const TaskSlideActinos({
    super.key,
    required this.child,
    required this.taskModel,
  });

  final Widget child;
  final TaskModel taskModel;

  @override
  State<TaskSlideActinos> createState() => _TaskSlideActinosState();
}

class _TaskSlideActinosState extends State<TaskSlideActinos> {
  late final taskProvider = context.read<TaskProvider>();
  final actionItemPadding = const EdgeInsets.symmetric(horizontal: 5);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(widget.taskModel.id),
      endActionPane: endPane(),
      startActionPane: startPane(),
      child: widget.child,
    );
  }

  ActionPane? startPane() {
    if (widget.taskModel.routineID != null && (widget.taskModel.taskDate == null || !widget.taskModel.taskDate!.isSameDay(DateTime.now()))) return null;

    return ActionPane(
      motion: const ScrollMotion(),
      extentRatio: 0.5,
      closeThreshold: 0.1,
      openThreshold: 0.1,
      dismissible: DismissiblePane(
        dismissThreshold: 0.01,
        closeOnCancel: true,
        confirmDismiss: () async {
          TaskActionHandler.handleTaskFailure(widget.taskModel);
          taskProvider.updateItems();
          return false;
        },
        onDismissed: () {},
      ),
      children: [
        failedAction(),
        cancelAction(),
      ],
    );
  }

  ActionPane? endPane() {
    return ActionPane(
      motion: const ScrollMotion(),
      extentRatio: 0.5,
      closeThreshold: 0.1,
      openThreshold: 0.1,
      dismissible: DismissiblePane(
        dismissThreshold: 0.3,
        closeOnCancel: true,
        confirmDismiss: () async {
          taskProvider.changeTaskDate(
            context: context,
            taskModel: widget.taskModel,
          );

          return false;
        },
        onDismissed: () {},
      ),
      children: [
        deleteAction(),
        if (widget.taskModel.routineID == null) changeDateAction(),
      ],
    );
  }

  SlidableAction cancelAction() {
    return SlidableAction(
      onPressed: (context) {
        TaskActionHandler.handleTaskCancellation(widget.taskModel);
        taskProvider.updateItems();
      },
      backgroundColor: AppColors.purple,
      icon: Icons.block,
      label: LocaleKeys.Cancel.tr(),
      padding: actionItemPadding,
    );
  }

  SlidableAction failedAction() {
    return SlidableAction(
      onPressed: (context) {
        TaskActionHandler.handleTaskFailure(widget.taskModel);
        taskProvider.updateItems();
      },
      backgroundColor: AppColors.red,
      icon: Icons.close,
      label: LocaleKeys.Failed.tr(),
      padding: actionItemPadding,
    );
  }

  SlidableAction changeDateAction() {
    return SlidableAction(
      onPressed: (context) {
        taskProvider.changeTaskDate(
          context: context,
          taskModel: widget.taskModel,
        );
      },
      backgroundColor: AppColors.orange,
      icon: Icons.calendar_month,
      label: LocaleKeys.ChangeDate.tr(),
      padding: actionItemPadding,
    );
  }

  SlidableAction deleteAction() {
    return SlidableAction(
      onPressed: (context) async {
        if (widget.taskModel.routineID == null) {
          await taskProvider.deleteTask(widget.taskModel.id);
        } else {
          await taskProvider.deleteRoutine(widget.taskModel.routineID!);
        }
      },
      backgroundColor: AppColors.red,
      icon: Icons.delete,
      label: LocaleKeys.Delete.tr(),
      padding: actionItemPadding,
    );
  }
}
