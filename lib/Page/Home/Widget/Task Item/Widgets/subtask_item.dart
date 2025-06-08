import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:provider/provider.dart';

class SubtaskItem extends StatefulWidget {
  final SubTaskModel subtask;
  final TaskModel taskModel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SubtaskItem({
    super.key,
    required this.subtask,
    required this.taskModel,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<SubtaskItem> createState() => _SubtaskItemState();
}

class _SubtaskItemState extends State<SubtaskItem> with TickerProviderStateMixin {
  late AnimationController _completionAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  bool _isAnimationRunning = false;
  bool _isVisuallyCompleted = false;

  Duration animationDuration() => const Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();

    // Animation controller for completion effect
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

    // Background color animation for completion effect
    _backgroundColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: const Color.fromARGB(255, 90, 255, 49).withValues(alpha: 0.2),
    ).animate(CurvedAnimation(
      parent: _completionAnimationController,
      curve: Curves.fastLinearToSlowEaseIn,
    ));
  }

  @override
  void dispose() {
    _completionAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if this subtask is visually completed (for animation state)
    final bool isVisuallyCompleted = _isVisuallyCompleted || widget.subtask.isCompleted;

    return AnimatedBuilder(
      animation: Listenable.merge([_completionAnimationController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedContainer(
            duration: animationDuration(),
            decoration: BoxDecoration(
              color: _backgroundColorAnimation.value,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Dismissible(
              key: Key('subtask_${widget.subtask.id}'),
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 10),
                child: const Icon(
                  Icons.delete_rounded,
                  color: AppColors.red,
                  size: 16,
                ),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                if (widget.onDelete != null) {
                  widget.onDelete!();
                }
              },
              child: InkWell(
                onTap: () {
                  if (widget.onEdit != null) {
                    widget.onEdit!();
                  }
                },
                onLongPress: () {
                  if (widget.onEdit != null) {
                    widget.onEdit!();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isVisuallyCompleted ? AppColors.main.withValues(alpha: 0.05) : AppColors.panelBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isVisuallyCompleted ? AppColors.main.withValues(alpha: 0.2) : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Checkbox with animation
                      InkWell(
                        onTap: () {
                          _toggleSubtaskCompletion();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isVisuallyCompleted ? AppColors.main : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isVisuallyCompleted ? AppColors.main : AppColors.text.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: isVisuallyCompleted
                                ? const Center(
                                    child: Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),

                      // Title and description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title with animation
                            Text(
                              widget.subtask.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isVisuallyCompleted ? FontWeight.normal : FontWeight.bold,
                                decoration: isVisuallyCompleted ? TextDecoration.lineThrough : null,
                                color: isVisuallyCompleted ? AppColors.text.withValues(alpha: 0.5) : AppColors.text,
                              ),
                            ),

                            // Description if available
                            if (widget.subtask.description != null && widget.subtask.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  widget.subtask.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.text.withValues(alpha: 0.6),
                                    decoration: isVisuallyCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleSubtaskCompletion() {
    // Check if animation is running
    if (_isAnimationRunning) {
      // Cancel the animation and revert the visual state
      _completionAnimationController.stop();
      _completionAnimationController.reset();
      _isAnimationRunning = false;
      _isVisuallyCompleted = false;

      setState(() {});
      return;
    }

    // Check if this subtask is being completed (not already completed)
    final bool isSubtaskBeingCompleted = !widget.subtask.isCompleted;

    if (isSubtaskBeingCompleted) {
      // First, immediately update the visual state (checkbox appears checked)
      _isVisuallyCompleted = true;
      setState(() {});

      // Then play the animation, and complete the subtask when animation finishes
      _playCompletionAnimation(() {
        // Actually complete the subtask after animation
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        taskProvider.toggleSubtaskCompletion(widget.taskModel, widget.subtask);
      });
    } else {
      // For uncompleting subtasks, handle the action immediately
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.toggleSubtaskCompletion(widget.taskModel, widget.subtask);
      setState(() {});
    }
  }

  void _playCompletionAnimation([VoidCallback? onAnimationComplete]) {
    _isAnimationRunning = true;

    // First, play the completion effect (scale + background color)
    _completionAnimationController.forward().then((_) {
      // After completion effect, reverse it and then complete the action
      _completionAnimationController.reverse().then((_) {
        _isAnimationRunning = false;
        _isVisuallyCompleted = false; // Reset visual state after animation

        // Execute completion callback (actually complete the subtask)
        if (onAnimationComplete != null) {
          onAnimationComplete();
        }
      });
    });
  }
}
