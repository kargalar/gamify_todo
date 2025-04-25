import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/Enums/status_enum.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/add_task_page.dart';
import 'package:gamify_todo/Page/Home/Widget/Task%20Item/Widgets/priority_line.dart';
import 'package:gamify_todo/Page/Home/Widget/Task%20Item/Widgets/subtask_list.dart';
import 'package:gamify_todo/Page/Home/Widget/Task%20Item/Widgets/task_location.dart';
import 'package:gamify_todo/Page/Home/Widget/Task%20Item/Widgets/title_and_decription.dart';
import 'package:gamify_todo/Page/Home/Widget/Task%20Item/Widgets/task_time.dart';
import 'package:gamify_todo/Page/Home/Widget/task_slide_actions.dart';
import 'package:gamify_todo/Page/Task%20Detail%20Page/routine_detail_page.dart';
import 'package:gamify_todo/Service/app_helper.dart';
import 'package:gamify_todo/Service/global_timer.dart';
import 'package:gamify_todo/Service/home_widget_service.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Service/navigator_service.dart';
import 'package:gamify_todo/Service/server_manager.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Provider/task_log_provider.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    if (widget.taskModel.routineID != null) {
      await NavigatorService()
          .goTo(
        RoutineDetailPage(
          taskModel: widget.taskModel,
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

    bool wasCompleted = widget.taskModel.status == TaskStatusEnum.COMPLETED;
    bool shouldCreateLog = false;

    if (widget.taskModel.type == TaskTypeEnum.CHECKBOX) {
      if (widget.taskModel.status == null || widget.taskModel.status != TaskStatusEnum.COMPLETED) {
        widget.taskModel.status = TaskStatusEnum.COMPLETED;
        AppHelper().addCreditByProgress(widget.taskModel.remainingDuration);
        shouldCreateLog = true; // Checkbox tamamlandığında log oluştur
      } else {
        widget.taskModel.status = null;
        AppHelper().addCreditByProgress(widget.taskModel.remainingDuration != null ? -widget.taskModel.remainingDuration! : null);
        // Görev tamamlanmadı olarak işaretlendiğinde alt görevlerin durumu değişmez
        // Alt görevler görünür hale gelecek (SubtaskList widget'ında didUpdateWidget metodu ile)
      }

      HomeWidgetService.updateTaskCount();
    } else if (widget.taskModel.type == TaskTypeEnum.COUNTER) {
      // Önceki değeri kaydet
      int previousCount = widget.taskModel.currentCount!;

      // Değeri 1 artır
      widget.taskModel.currentCount = previousCount + 1;

      AppHelper().addCreditByProgress(widget.taskModel.remainingDuration);

      // Counter arttırıldığında log oluştur (sadece +1 olarak)
      shouldCreateLog = true;

      // Log için değişim miktarını kaydet (+1)
      // Doğrudan TaskLogProvider.addTaskLog metoduna parametre olarak geçeceğiz

      if (widget.taskModel.currentCount! >= widget.taskModel.targetCount! && !wasCompleted) {
        widget.taskModel.status = TaskStatusEnum.COMPLETED;
        HomeWidgetService.updateTaskCount();
      }
    } else {
      // Timer başlatıldığında/durdurulduğunda
      bool wasActive = widget.taskModel.isTimerActive!;

      // Timer başlatılmadan önceki süreyi kaydet
      Duration previousDuration = widget.taskModel.currentDuration ?? Duration.zero;

      // Timer başlatma/durdurma işlemi
      GlobalTimer().startStopTimer(
        taskModel: widget.taskModel,
      );

      // Timer başlatıldığında, başlangıç zamanını kaydet
      if (!wasActive && widget.taskModel.isTimerActive!) {
        // Timer başlatıldığında, başlangıç zamanını kaydet
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('timer_start_time_${widget.taskModel.id}', DateTime.now().millisecondsSinceEpoch.toString());
          prefs.setString('timer_start_duration_${widget.taskModel.id}', previousDuration.inSeconds.toString());
        });
      }

      // Timer durduğunda log oluştur (aktifken durdurulduğunda)
      if (wasActive && !widget.taskModel.isTimerActive!) {
        shouldCreateLog = true;
      }
    }

    ServerManager().updateTask(taskModel: widget.taskModel);

    // Log oluştur
    if (shouldCreateLog) {
      if (widget.taskModel.type == TaskTypeEnum.COUNTER) {
        // Counter için +1 olarak log oluştur
        TaskLogProvider().addTaskLog(
          widget.taskModel,
          customCount: 1, // Her zaman +1 olarak logla
        );
      } else if (widget.taskModel.type == TaskTypeEnum.TIMER) {
        // Timer için durduğunda geçen süreyi logla
        if (!widget.taskModel.isTimerActive!) {
          // Shared Preferences'dan timer başlangıç zamanını ve başlangıç süresini al
          SharedPreferences.getInstance().then((prefs) {
            String? timerStartTimeStr = prefs.getString('timer_start_time_${widget.taskModel.id}');
            String? timerStartDurationStr = prefs.getString('timer_start_duration_${widget.taskModel.id}');

            if (timerStartTimeStr != null && timerStartDurationStr != null) {
              // Timer başlangıç zamanını hesapla
              DateTime timerStartTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timerStartTimeStr));

              // Timer çalışma süresini hesapla (şu anki zaman - başlangıç zamanı)
              Duration timerRunDuration = DateTime.now().difference(timerStartTime);

              // Sadece pozitif değişimleri logla
              if (timerRunDuration.inSeconds > 0) {
                TaskLogProvider().addTaskLog(
                  widget.taskModel,
                  customDuration: timerRunDuration, // Sadece timer çalışma süresini logla
                );

                // Timer başlangıç zamanını ve süresini temizle
                prefs.remove('timer_start_time_${widget.taskModel.id}');
                prefs.remove('timer_start_duration_${widget.taskModel.id}');
              }
            }
          });
        }
      } else {
        // Checkbox için normal log oluştur
        TaskLogProvider().addTaskLog(widget.taskModel);
      }
    }

    if (!_isIncrementing) {
      TaskProvider().updateItems();
    }
  }
}
