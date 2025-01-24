import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/1%20Core/extensions.dart';
import 'package:gamify_todo/5%20Service/app_helper.dart';
import 'package:gamify_todo/5%20Service/home_widget_service.dart';
import 'package:gamify_todo/5%20Service/locale_keys.g.dart';
import 'package:gamify_todo/5%20Service/notification_services.dart';
import 'package:gamify_todo/5%20Service/server_manager.dart';
import 'package:gamify_todo/6%20Provider/store_provider.dart';
import 'package:gamify_todo/6%20Provider/task_provider.dart';
import 'package:gamify_todo/7%20Enum/task_status_enum.dart';
import 'package:gamify_todo/7%20Enum/task_type_enum.dart';
import 'package:gamify_todo/8%20Model/store_item_model.dart';
import 'package:gamify_todo/8%20Model/task_model.dart';
import 'package:provider/provider.dart';

class EditProgressWidget extends StatefulWidget {
  final TaskModel? taskModel;
  final ItemModel? itemModel;

  const EditProgressWidget.forTask({
    super.key,
    required TaskModel task,
  })  : taskModel = task,
        itemModel = null;

  const EditProgressWidget.forStoreItem({
    super.key,
    required ItemModel item,
  })  : itemModel = item,
        taskModel = null;

  @override
  State<EditProgressWidget> createState() => _EditProgressWidgetState();
}

class _EditProgressWidgetState extends State<EditProgressWidget> {
  bool _isIncrementing = false;
  bool _isDecrementing = false;

  bool get isTask => widget.taskModel != null;
  TaskTypeEnum get type => isTask ? widget.taskModel!.type : widget.itemModel!.type;
  int get currentCount => isTask ? widget.taskModel!.currentCount! : widget.itemModel!.currentCount!;
  Duration? get currentDuration => isTask ? widget.taskModel!.currentDuration : widget.itemModel!.currentDuration;
  Duration? get targetDuration => isTask ? widget.taskModel!.remainingDuration : widget.itemModel!.addDuration;

  void updateProgress(value) {
    if (isTask) {
      late Duration progressDifference;
      if (widget.taskModel!.type == TaskTypeEnum.COUNTER) {
        int previousCount = widget.taskModel!.currentCount ?? 0;
        widget.taskModel!.currentCount = value;

        // Calculate progress difference for credit adjustment
        int difference = value - previousCount;
        progressDifference = widget.taskModel!.remainingDuration! * difference ~/ widget.taskModel!.targetCount!;
      } else {
        Duration previousDuration = widget.taskModel!.currentDuration ?? Duration.zero;
        widget.taskModel!.currentDuration = value;

        // Calculate progress difference for credit adjustment
        progressDifference = value - previousDuration;
      }

      ServerManager().updateTask(taskModel: widget.taskModel!);
      AppHelper().addCreditByProgress(progressDifference);

      HomeWidgetService.updateTaskCount();
    } else {
      ServerManager().updateItem(itemModel: widget.itemModel!);
    }
  }

  void setCount(int value) {
    setState(() {
      if (isTask) {
        if (value >= widget.taskModel!.targetCount! && widget.taskModel!.status != TaskStatusEnum.COMPLETED) {
          widget.taskModel!.status = TaskStatusEnum.COMPLETED;
        } else if (value < widget.taskModel!.targetCount! && widget.taskModel!.status == TaskStatusEnum.COMPLETED) {
          widget.taskModel!.status = null;
        }
      } else {
        widget.itemModel!.currentCount = value;
      }
    });
    updateProgress(value);
  }

  void setDuration(Duration value) {
    setState(() {
      if (isTask) {
        if (value >= widget.taskModel!.remainingDuration! && widget.taskModel!.status != TaskStatusEnum.COMPLETED) {
          widget.taskModel!.status = TaskStatusEnum.COMPLETED;
        } else if (value < widget.taskModel!.remainingDuration! && widget.taskModel!.status == TaskStatusEnum.COMPLETED) {
          widget.taskModel!.status = null;
        }
        _checkAndUpdateNotificationStatusForTask();
      } else {
        widget.itemModel!.currentDuration = value;
        _checkAndUpdateNotificationStatusForStoreItem();
      }
    });
    updateProgress(value);
  }

  @override
  Widget build(BuildContext context) {
    if (isTask) {
      context.watch<TaskProvider>();
    } else {
      context.watch<StoreProvider>();
    }

    if (type == TaskTypeEnum.CHECKBOX) {
      return Text(
        _getCheckboxStatus(),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      );
    } else if (type == TaskTypeEnum.COUNTER) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (currentCount > 0 || !isTask) {
                setCount(currentCount - 1);
              }
            },
            onLongPressStart: (_) async {
              _isDecrementing = true;
              while (_isDecrementing && mounted) {
                if (currentCount > 0 || !isTask) {
                  setCount(currentCount - 1);
                }
                await Future.delayed(const Duration(milliseconds: 60));
              }
            },
            onLongPressEnd: (_) {
              _isDecrementing = false;
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.remove, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            isTask ? "$currentCount / ${widget.taskModel!.targetCount!}" : "$currentCount",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              setCount(currentCount + 1);
            },
            onLongPressStart: (_) async {
              _isIncrementing = true;
              while (_isIncrementing && mounted) {
                setCount(currentCount + 1);
                await Future.delayed(const Duration(milliseconds: 60));
              }
            },
            onLongPressEnd: (_) {
              _isIncrementing = false;
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.add, size: 30),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDurationControl(
            label: LocaleKeys.Hour.tr(),
            value: (currentDuration?.isNegative ?? false) ? -((-currentDuration!.inHours) % 24) : currentDuration?.inHours ?? 0,
            onIncrease: () {
              setDuration((currentDuration ?? Duration.zero) + const Duration(hours: 1));
            },
            onDecrease: () {
              if ((currentDuration?.inHours ?? 0) > 0 || !isTask) {
                setDuration((currentDuration ?? Duration.zero) - const Duration(hours: 1));
              }
            },
            onLongIncrease: () {
              setDuration((currentDuration ?? Duration.zero) + const Duration(hours: 1));
            },
            onLongDecrease: () {
              if ((currentDuration?.inHours ?? 0) > 0 || !isTask) {
                setDuration((currentDuration ?? Duration.zero) - const Duration(hours: 1));
              }
            },
          ),
          const SizedBox(width: 16),
          _buildDurationControl(
            label: LocaleKeys.Minute.tr(),
            value: (currentDuration?.isNegative ?? false) ? -((-currentDuration!.inMinutes) % 60) : (currentDuration?.inMinutes ?? 0) % 60,
            onIncrease: () {
              setDuration((currentDuration ?? Duration.zero) + const Duration(minutes: 1));
            },
            onDecrease: () {
              if ((currentDuration?.inMinutes ?? 0) > 0 || !isTask) {
                setDuration((currentDuration ?? Duration.zero) - const Duration(minutes: 1));
              }
            },
            onLongIncrease: () {
              setDuration((currentDuration ?? Duration.zero) + const Duration(minutes: 1));
            },
            onLongDecrease: () {
              if ((currentDuration?.inMinutes ?? 0) > 0 || !isTask) {
                setDuration((currentDuration ?? Duration.zero) - const Duration(minutes: 1));
              }
            },
          ),
          const SizedBox(width: 16),
          _buildDurationControl(
            label: LocaleKeys.Second.tr(),
            value: (currentDuration?.isNegative ?? false) ? -((-currentDuration!.inSeconds) % 60) : (currentDuration?.inSeconds ?? 0) % 60,
            onIncrease: () {
              setDuration((currentDuration ?? Duration.zero) + const Duration(seconds: 1));
            },
            onDecrease: () {
              if ((currentDuration?.inSeconds ?? 0) > 0 || !isTask) {
                setDuration((currentDuration ?? Duration.zero) - const Duration(seconds: 1));
              }
            },
            onLongIncrease: () {
              setDuration((currentDuration ?? Duration.zero) + const Duration(seconds: 1));
            },
            onLongDecrease: () {
              if ((currentDuration?.inSeconds ?? 0) > 0 || !isTask) {
                setDuration((currentDuration ?? Duration.zero) - const Duration(seconds: 1));
              }
            },
          ),
          if (isTask) ...[
            const SizedBox(width: 16),
            Text(
              "/ ${targetDuration?.textShort3() ?? "0"}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      );
    }
  }

  Widget _buildDurationControl({
    required String label,
    required int value,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
    required VoidCallback onLongIncrease,
    required VoidCallback onLongDecrease,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onIncrease,
          onLongPressStart: (_) async {
            _isIncrementing = true;
            while (_isIncrementing && mounted) {
              onLongIncrease();
              await Future.delayed(const Duration(milliseconds: 60));
            }
          },
          onLongPressEnd: (_) {
            _isIncrementing = false;
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.keyboard_arrow_up, size: 24),
          ),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: onDecrease,
          onLongPressStart: (_) async {
            _isDecrementing = true;
            while (_isDecrementing && mounted) {
              onLongDecrease();
              await Future.delayed(const Duration(milliseconds: 60));
            }
          },
          onLongPressEnd: (_) {
            _isDecrementing = false;
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.keyboard_arrow_down, size: 24),
          ),
        ),
      ],
    );
  }

  String _getCheckboxStatus() {
    if (!isTask) return "";

    switch (widget.taskModel!.status) {
      case TaskStatusEnum.COMPLETED:
        return LocaleKeys.Completed.tr();
      case TaskStatusEnum.FAILED:
        return LocaleKeys.Failed.tr();
      case TaskStatusEnum.CANCEL:
        return LocaleKeys.Cancelled.tr();
      default:
        return LocaleKeys.InProgress.tr();
    }
  }

  // TODO: buradalar notificaitonService de yapılsın
  // check notifiaciaton status for task
  void _checkAndUpdateNotificationStatusForTask() {
    final task = widget.taskModel!;
    final remainingDuration = task.remainingDuration!;
    final currentDuration = task.currentDuration!;
    final isTimerActive = task.isTimerActive ?? false;

    if (currentDuration < remainingDuration && isTimerActive) {
      // Zamanlanmış bildirimi yeniden hesapla
      final int secondsUntilCompletion = remainingDuration.inSeconds - currentDuration.inSeconds;
      NotificationService().scheduleNotification(
        id: task.id,
        title: '🎉 ${task.title} Tamamlandı',
        desc: 'Toplam süre: ${task.remainingDuration!.textLongDynamicWithoutZero()}',
        scheduledDate: DateTime.now().add(Duration(seconds: secondsUntilCompletion)),
        isAlarm: task.isAlarmOn,
      );
    } else if (isTimerActive && currentDuration >= remainingDuration) {
      // Halihazırdaki zamanlanmış bildirimi iptal et
      NotificationService().cancelNotificationOrAlarm(task.id);
    }
  }

  // check notifiaciaton status for store item
  void _checkAndUpdateNotificationStatusForStoreItem() {
    final item = widget.itemModel!;
    final currentDuration = item.currentDuration!;
    final isTimerActive = item.isTimerActive ?? false;

    if (currentDuration.inSeconds > 0 && isTimerActive) {
      // Zamanlanmış bildirimi yeniden hesapla
      final int secondsUntilCompletion = currentDuration.inSeconds;
      NotificationService().scheduleNotification(
        id: item.id,
        title: '⚠️ ${item.title} Süre Doldu',
        desc: 'Sınırı Aşma!',
        scheduledDate: DateTime.now().add(Duration(seconds: secondsUntilCompletion)),
        isAlarm: true,
      );
    } else if (isTimerActive && currentDuration.inSeconds <= 0) {
      // Halihazırdaki zamanlanmış bildirimi iptal et
      NotificationService().cancelNotificationOrAlarm(item.id);
    }
  }
}
