import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/task_model.dart';

class PriorityLine extends StatelessWidget {
  const PriorityLine({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  Widget build(BuildContext context) {
    if (taskModel.priority == 3) return const SizedBox();

    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (taskModel.priority == 1 ? AppColors.red : AppColors.orange2).withValues(alpha: 0.7),
            Colors.transparent,
          ],
          stops: const [0, 1],
        ),
      ),
    );
  }
}
