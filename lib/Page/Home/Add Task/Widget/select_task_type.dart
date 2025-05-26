import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/select_target_count.dart';
import 'package:next_level/Provider/add_store_item_provider.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';

class SelectTaskType extends StatefulWidget {
  const SelectTaskType({
    super.key,
    this.isStore = false,
  });

  final bool isStore;

  @override
  State<SelectTaskType> createState() => _SelectTaskTypeState();
}

class _SelectTaskTypeState extends State<SelectTaskType> {
  late final dynamic provider = widget.isStore ? context.read<AddStoreItemProvider>() : context.read<AddTaskProvider>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          ClickableTooltip(
            title: "Task Type",
            bulletPoints: const ["Checkbox: Simple task that can be marked as completed", "Counter: Task with a target count that can be incremented", "Timer: Task with a timer that counts down from a set duration"],
            child: Container(
              color: AppColors.transparent,
              child: Row(
                children: [
                  Icon(
                    Icons.category_rounded,
                    color: AppColors.main,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Task Type",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Task type buttons
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              if (!widget.isStore) taskTypeButton(TaskTypeEnum.CHECKBOX),
              taskTypeButton(TaskTypeEnum.COUNTER),
              taskTypeButton(TaskTypeEnum.TIMER),
            ],
          ),

          // Target count selector (if counter type is selected)
          if (provider.selectedTaskType == TaskTypeEnum.COUNTER) ...[
            const SizedBox(height: 16),
            SelectTargetCount(isStore: widget.isStore),
          ],
        ],
      ),
    );
  }

  Widget taskTypeButton(TaskTypeEnum taskType) {
    final bool isSelected = provider.selectedTaskType == taskType;

    String taskTypeName;
    IconData taskTypeIcon;

    switch (taskType) {
      case TaskTypeEnum.CHECKBOX:
        taskTypeName = "Checkbox";
        taskTypeIcon = Icons.check_box_rounded;
        break;
      case TaskTypeEnum.COUNTER:
        taskTypeName = "Counter";
        taskTypeIcon = Icons.add_circle_rounded;
        break;
      case TaskTypeEnum.TIMER:
        taskTypeName = "Timer";
        taskTypeIcon = Icons.timer_rounded;
        break;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Unfocus any text fields when selecting task type
          if (!widget.isStore) {
            (provider as AddTaskProvider).unfocusAll();
          } else {
            (provider as AddStoreItemProvider).unfocusAll();
          }
          // Also unfocus using FocusScope for any other fields
          FocusScope.of(context).unfocus();
          setState(() {
            provider.selectedTaskType = taskType;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.main.withValues(alpha: 0.9) : AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.main : AppColors.text.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.main.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  taskTypeIcon,
                  size: 24,
                  color: isSelected ? Colors.white : AppColors.text.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 6),
                Text(
                  taskTypeName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.text.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
