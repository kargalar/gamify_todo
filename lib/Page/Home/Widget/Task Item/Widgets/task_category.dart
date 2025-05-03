import 'package:flutter/material.dart';
import 'package:gamify_todo/Model/category_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Provider/category_provider.dart';

class TaskCategory extends StatelessWidget {
  const TaskCategory({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  Widget build(BuildContext context) {
    if (taskModel.categoryId == null) {
      return const SizedBox.shrink();
    }

    final CategoryModel? category = CategoryProvider().getCategoryById(taskModel.categoryId);
    if (category == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: category.color.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            category.title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: category.color,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 0.5,
                  offset: const Offset(0, 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
