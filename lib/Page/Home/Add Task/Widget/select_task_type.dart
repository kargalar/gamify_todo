import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/select_target_count.dart';
import 'package:gamify_todo/Provider/add_store_item_providerr.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
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
        borderRadius: AppColors.borderRadiusAll,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!widget.isStore) taskTypeButton(TaskTypeEnum.CHECKBOX),
              taskTypeButton(TaskTypeEnum.COUNTER),
              taskTypeButton(TaskTypeEnum.TIMER),
            ],
          ),
          if (provider.selectedTaskType == TaskTypeEnum.COUNTER) ...[
            const SizedBox(height: 5),
            SelectTargetCount(isStore: widget.isStore),
          ],
        ],
      ),
    );
  }

  InkWell taskTypeButton(TaskTypeEnum taskType) {
    return InkWell(
      borderRadius: AppColors.borderRadiusAll,
      onTap: () {
        setState(() {
          provider.selectedTaskType = taskType;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppColors.borderRadiusAll,
          color: provider.selectedTaskType == taskType ? AppColors.main : Colors.transparent,
        ),
        padding: const EdgeInsets.all(5),
        child: Icon(
          taskType == TaskTypeEnum.CHECKBOX
              ? Icons.check_box
              : taskType == TaskTypeEnum.COUNTER
                  ? Icons.add
                  : Icons.timer,
          size: 30,
          color: provider.selectedTaskType == taskType ? AppColors.white : null,
        ),
      ),
    );
  }
}
