import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/progress_text.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/task_category.dart';
import 'package:next_level/Model/task_model.dart';

class TitleAndDescription extends StatelessWidget {
  const TitleAndDescription({
    super.key,
    required this.taskModel,
    this.displayCount,
  });

  final TaskModel taskModel;
  final int? displayCount; // Override count for UI-only updates during long press

  @override
  Widget build(BuildContext context) {
    final priorityColor = (taskModel.priority == 1
            ? AppColors.red
            : taskModel.priority == 2
                ? AppColors.orange2
                : AppColors.text)
        .withValues(alpha: 0.9);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AutoSizeText(
                  taskModel.title,
                  maxLines: 2,
                  minFontSize: 13,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: priorityColor,
                  ),
                ),
              ),
              // Attachment indicator
              if (taskModel.attachmentPaths != null && taskModel.attachmentPaths!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.attach_file_rounded,
                  size: 16,
                  color: priorityColor.withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
          if (taskModel.description != null && taskModel.description!.isNotEmpty)
            Text(
              taskModel.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: priorityColor.withValues(alpha: 0.7),
              ),
            ),
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ProgressText(taskModel: taskModel, displayCount: displayCount),
              if (taskModel.categoryId != null) TaskCategory(taskModel: taskModel),
            ],
          ),
        ],
      ),
    );
  }
}
