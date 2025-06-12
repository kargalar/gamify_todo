import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:next_level/Core/Handlers/task_action_handler.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:provider/provider.dart';

class TaskSlideActions extends StatefulWidget {
  const TaskSlideActions({
    super.key,
    required this.child,
    required this.taskModel,
    this.onFailAnimation,
    this.onCancelAnimation,
  });

  final Widget child;
  final TaskModel taskModel;
  final VoidCallback? onFailAnimation;
  final VoidCallback? onCancelAnimation;

  @override
  State<TaskSlideActions> createState() => _TaskSlideActionsState();
}

class _TaskSlideActionsState extends State<TaskSlideActions> {
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
          if (widget.taskModel.routineID == null) {
            taskProvider.changeTaskDate(
              context: context,
              taskModel: widget.taskModel,
            );
          }

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
        // Eğer task zaten cancel durumundaysa animasyon oynatma
        if (widget.taskModel.status == TaskStatusEnum.CANCEL) {
          // Direkt cancel işlemi yap (animasyon yok)
          TaskActionHandler.handleTaskCancellation(widget.taskModel);
          taskProvider.updateItems();
          return;
        }

        // Önce animasyonu çal, sonra task'ı cancel yap
        if (widget.onCancelAnimation != null) {
          widget.onCancelAnimation!();
        }

        // Animasyon bittikten sonra cancel işlemi yapılacak
        // Bu işlem artık task_item.dart'ta _playCancelAnimation içinde yapılacak
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
        // Eğer task zaten fail durumundaysa animasyon oynatma
        if (widget.taskModel.status == TaskStatusEnum.FAILED) {
          // Direkt fail işlemi yap (animasyon yok)
          TaskActionHandler.handleTaskFailure(widget.taskModel);
          taskProvider.updateItems();
          return;
        }

        // Önce animasyonu çal, sonra task'ı fail yap
        if (widget.onFailAnimation != null) {
          widget.onFailAnimation!();
        }

        // Animasyon bittikten sonra fail işlemi yapılacak
        // Bu işlem artık task_item.dart'ta _playFailAnimation içinde yapılacak
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
