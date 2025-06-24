import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/Handlers/task_action_handler.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/description_editor.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/priority_line.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/subtasks_bottom_sheet.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/task_location.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/task_time.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/title_and_decription.dart';
import 'package:next_level/Page/Home/Widget/task_slide_actions.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Enum/task_item_style_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Provider/task_style_provider.dart';
import 'package:provider/provider.dart';

enum AnimationType { completion, fail, cancel }

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

class _TaskItemState extends State<TaskItem> with TickerProviderStateMixin {
  Timer? _longPressTimer;
  int _longPressStartValue = 0;
  bool _isLongPressing = false;
  int _displayCount = 0; // For UI-only updates during long press
  late AnimationController _completionAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<Color?> _failBackgroundColorAnimation;
  late Animation<Color?> _cancelBackgroundColorAnimation;
  bool _isAnimationRunning = false; // Track if completion animation is running
  bool _isVisuallyCompleted = false; // Track visual state for checkbox UI
  AnimationType _currentAnimationType = AnimationType.completion; // Track current animation type
  animationDuration() => const Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();

    // Animation controller for completion effect (quick)
    _completionAnimationController = AnimationController(
      duration: animationDuration(),
      vsync: this,
    );

    // Scale animation for completion effect
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _completionAnimationController,
      curve: Curves.fastLinearToSlowEaseIn,
    ));

    // Background color animation for completion effect (green)
    _backgroundColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: const Color.fromARGB(255, 90, 255, 49).withValues(alpha: 0.2),
    ).animate(CurvedAnimation(
      parent: _completionAnimationController,
      curve: Curves.fastLinearToSlowEaseIn,
    ));

    // Background color animation for fail effect (red)
    _failBackgroundColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.red.withValues(alpha: 0.2),
    ).animate(CurvedAnimation(
      parent: _completionAnimationController,
      curve: Curves.fastLinearToSlowEaseIn,
    ));

    // Background color animation for cancel effect (orange)
    _cancelBackgroundColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.orange.withValues(alpha: 0.2),
    ).animate(CurvedAnimation(
      parent: _completionAnimationController,
      curve: Curves.fastLinearToSlowEaseIn,
    ));
  }

  @override
  void dispose() {
    _completionAnimationController.dispose();
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _startLongPress() {
    _isLongPressing = true;
    _longPressStartValue = widget.taskModel.currentCount ?? 0;
    _displayCount = _longPressStartValue; // Initialize display count
  }

  void _endLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;

    if (_isLongPressing) {
      _isLongPressing = false;
      final change = _displayCount - _longPressStartValue;
      if (change > 0) {
        // Apply the actual changes to the model
        _createBatchLog(change);
      }
      setState(() {});
    }
  }

  void _createBatchLog(int change) {
    // Create a single batch log entry
    TaskActionHandler.handleTaskAction(
      widget.taskModel,
      batchChange: change,
      onStateChanged: () {
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskStyleProvider>(
      builder: (context, styleProvider, child) {
        return AnimatedBuilder(
          animation: Listenable.merge([_completionAnimationController]),
          builder: (context, child) {
            // Get the appropriate background color based on animation type
            Color? backgroundColor;
            switch (_currentAnimationType) {
              case AnimationType.completion:
                backgroundColor = _backgroundColorAnimation.value;
                break;
              case AnimationType.fail:
                backgroundColor = _failBackgroundColorAnimation.value;
                break;
              case AnimationType.cancel:
                backgroundColor = _cancelBackgroundColorAnimation.value;
                break;
            }

            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: animationDuration(),
                margin: _getMarginForStyle(styleProvider.currentStyle),
                decoration: _getDecorationForStyle(styleProvider.currentStyle, backgroundColor),
                child: TaskSlideActions(
                  taskModel: widget.taskModel,
                  onFailAnimation: _playFailAnimation,
                  onCancelAnimation: _playCancelAnimation,
                  child: Opacity(
                    opacity: !(widget.taskModel.status == null || widget.taskModel.status == TaskStatusEnum.OVERDUE) && !(widget.taskModel.type == TaskTypeEnum.TIMER && widget.taskModel.isTimerActive!) ? 0.75 : 1.0,
                    child: InkWell(
                      onTap: () {
                        // eğer subtask var ise subtask bottom sheet açılır
                        if (widget.taskModel.subtasks != null && widget.taskModel.subtasks!.isNotEmpty) {
                          _showSubtasksBottomSheet();
                        }
                        // eğer description varsa description editor aç
                        else if (widget.taskModel.description != null && widget.taskModel.description!.isNotEmpty) {
                          _showDescriptionEditor();
                        } else {
                          taskAction();
                        }
                      },
                      onLongPress: () async {
                        await taskLongPressAction();
                      },
                      borderRadius: _getBorderRadiusForStyle(styleProvider.currentStyle),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: widget.taskModel.type == TaskTypeEnum.TIMER && widget.taskModel.isTimerActive! ? null : _getBorderRadiusForStyle(styleProvider.currentStyle),
                            ),
                            child: Row(
                              children: [
                                taskActionIcon(),
                                TitleAndDescription(
                                  taskModel: widget.taskModel,
                                  displayCount: _isLongPressing ? _displayCount : null,
                                ),
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
                          if (widget.taskModel.subtasks != null && widget.taskModel.subtasks!.isNotEmpty) _buildSubtasksButton(),
                          PriorityLine(taskModel: widget.taskModel),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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

    return widget.taskModel.type == TaskTypeEnum.COUNTER
        ? GestureDetector(
            onTap: () => taskAction(),
            onLongPressStart: (_) {
              _startLongPress();

              // Timer ile sadece UI güncellemesi
              _longPressTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
                if (!mounted || !_isLongPressing) {
                  timer.cancel();
                  return;
                }
                // Sadece display count'u artır, gerçek veriyi değiştirme
                _displayCount++;
                setState(() {});
              });
            },
            onLongPressEnd: (_) {
              _endLongPress();
            },
            onLongPressCancel: () {
              _endLongPress();
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(5),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground,
                  borderRadius: AppColors.borderRadiusAll,
                ),
                child: Icon(
                  Icons.add,
                  size: 27,
                  color: priorityColor,
                ),
              ),
            ),
          )
        : GestureDetector(
            onTap: () => taskAction(),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(5),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground,
                  borderRadius: AppColors.borderRadiusAll,
                ),
                child: Icon(
                  widget.taskModel.type == TaskTypeEnum.CHECKBOX
                      ? (_isVisuallyCompleted || widget.taskModel.status == TaskStatusEnum.COMPLETED)
                          ? Icons.check_box
                          : Icons.check_box_outline_blank
                      : widget.taskModel.isTimerActive!
                          ? Icons.pause
                          : Icons.play_arrow,
                  size: 27,
                  color: priorityColor,
                ),
              ),
            ),
          );
  }

  void taskAction({bool skipLogging = false}) {
    if (widget.taskModel.status == TaskStatusEnum.ARCHIVED) {
      // Play fail animation for archived tasks
      _playFailAnimation();
      return Helper().getMessage(
        status: StatusEnum.WARNING,
        // TODO: localization
        message: "Bu task arşivlendiği için etkileşimde bulunulamaz.",
      );
    } else if (widget.taskModel.routineID != null && (widget.taskModel.taskDate == null || !widget.taskModel.taskDate!.isBeforeOrSameDay(DateTime.now()))) {
      return Helper().getMessage(
        status: StatusEnum.WARNING,
        message: LocaleKeys.RoutineForFuture.tr(),
      );
    }

    // Check if animation is running and this is a checkbox task
    if (_isAnimationRunning && widget.taskModel.type == TaskTypeEnum.CHECKBOX) {
      // Cancel the animation and revert the visual state
      _completionAnimationController.stop();
      _completionAnimationController.reset();
      _isAnimationRunning = false;
      _isVisuallyCompleted = false;

      setState(() {});
      return;
    }

    // Check if this is a checkbox task being completed
    final bool isCheckboxTaskBeingCompleted = widget.taskModel.type == TaskTypeEnum.CHECKBOX && widget.taskModel.status != TaskStatusEnum.COMPLETED;

    if (isCheckboxTaskBeingCompleted) {
      // First, immediately update the visual state (checkbox appears checked)
      _isVisuallyCompleted = true;
      setState(() {});

      // Then play the completion animation, and complete the task when animation finishes
      _playCompletionAnimation(() {
        // Actually complete the task after animation
        TaskActionHandler.handleTaskAction(
          widget.taskModel,
          skipLogging: skipLogging,
          onStateChanged: () {
            setState(() {});
          },
        );
      });
    } else {
      // For other task types, handle the action immediately
      TaskActionHandler.handleTaskAction(
        widget.taskModel,
        skipLogging: skipLogging,
        onStateChanged: () {
          if (!_isLongPressing) {
            setState(() {});
          }
        },
      );
    }
  }

  void _playAnimation(AnimationType animationType, [VoidCallback? onAnimationComplete]) {
    if (_isAnimationRunning) return; // Prevent multiple animations

    _isAnimationRunning = true;
    _currentAnimationType = animationType;
    _completionAnimationController.reset();

    // First, play the animation effect (scale + background color)
    _completionAnimationController.forward().then((_) {
      // After animation effect, reverse it
      _completionAnimationController.reverse().then((_) {
        _isAnimationRunning = false;
        _isVisuallyCompleted = false; // Reset visual state after animation

        // Execute completion callback
        if (onAnimationComplete != null) {
          onAnimationComplete();
        }
      });
    });
  }

  void _playCompletionAnimation([VoidCallback? onAnimationComplete]) {
    _playAnimation(AnimationType.completion, onAnimationComplete);
  }

  void _playFailAnimation() {
    _playAnimation(AnimationType.fail, () {
      // Animasyon bittikten sonra task'ı fail olarak işaretle
      TaskActionHandler.handleTaskFailure(widget.taskModel);
      setState(() {});
    });
  }

  void _playCancelAnimation() {
    _playAnimation(AnimationType.cancel, () {
      // Animasyon bittikten sonra task'ı cancel olarak işaretle
      TaskActionHandler.handleTaskCancellation(widget.taskModel);
      setState(() {});
    });
  }

  // Style helper methods
  EdgeInsets _getMarginForStyle(TaskItemStyle style) {
    switch (style) {
      case TaskItemStyle.card:
        return const EdgeInsets.symmetric(vertical: 3, horizontal: 4);
      case TaskItemStyle.minimal:
        return const EdgeInsets.symmetric(vertical: 1, horizontal: 2);
      case TaskItemStyle.flat:
        return const EdgeInsets.symmetric(vertical: 1, horizontal: 0);
      case TaskItemStyle.glass:
        return const EdgeInsets.symmetric(vertical: 3, horizontal: 3);
      case TaskItemStyle.modern:
        return const EdgeInsets.symmetric(vertical: 2, horizontal: 4);
    }
  }

  BorderRadius _getBorderRadiusForStyle(TaskItemStyle style) {
    switch (style) {
      case TaskItemStyle.card:
        return AppColors.borderRadiusAll;
      case TaskItemStyle.minimal:
        return BorderRadius.circular(8);
      case TaskItemStyle.flat:
        return BorderRadius.zero;
      case TaskItemStyle.glass:
        return BorderRadius.circular(10);
      case TaskItemStyle.modern:
        return BorderRadius.circular(10);
    }
  }

  BoxDecoration _getDecorationForStyle(TaskItemStyle style, Color? backgroundColor) {
    switch (style) {
      case TaskItemStyle.card:
        return BoxDecoration(
          color: AppColors.panelBackground.withAlpha(180),
          borderRadius: _getBorderRadiusForStyle(style),
        );
      case TaskItemStyle.minimal:
        return BoxDecoration(
          color: backgroundColor ?? AppColors.panelBackground.withAlpha(100),
          borderRadius: _getBorderRadiusForStyle(style),
        );

      case TaskItemStyle.flat:
        return BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          border: Border(
            bottom: BorderSide(color: AppColors.grey.withAlpha(50), width: 1),
          ),
        );

      case TaskItemStyle.glass:
        return BoxDecoration(
          color: backgroundColor ?? AppColors.panelBackground.withAlpha(100),
          borderRadius: _getBorderRadiusForStyle(style),
          border: Border.all(
            color: Colors.white.withAlpha(50),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        );

      case TaskItemStyle.modern:
        return BoxDecoration(
          color: backgroundColor ?? AppColors.panelBackground.withAlpha(200),
          borderRadius: _getBorderRadiusForStyle(style),
          border: Border.all(
            color: AppColors.grey.withAlpha(30),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        );
    }
  }

  Widget _buildSubtasksButton() {
    final subtaskCount = widget.taskModel.subtasks?.length ?? 0;
    final completedCount = widget.taskModel.subtasks?.where((subtask) => subtask.isCompleted).length ?? 0;

    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
      child: GestureDetector(
        onTap: () {
          // Allow subtask editing for future routines - they should be editable
          _showSubtasksBottomSheet();
        },
        child: Row(
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 16,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              LocaleKeys.ShowSubtasks.tr(),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.text.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.main.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$completedCount/$subtaskCount",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.main,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubtasksBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => SubtasksBottomSheet(taskModel: widget.taskModel),
    );
  }

  void _showDescriptionEditor() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) {
          final provider = AddTaskProvider();
          provider.editTask = widget.taskModel;
          // Description controller'ı manuel olarak doldur
          provider.descriptionController.text = widget.taskModel.description ?? '';

          return ChangeNotifierProvider.value(
            value: provider,
            child: const DescriptionEditor(),
          );
        },
        fullscreenDialog: true,
      ),
    )
        .then((_) {
      // Description editor'dan geri geldiğinde state'i güncelle
      setState(() {});
    });
  }
}
