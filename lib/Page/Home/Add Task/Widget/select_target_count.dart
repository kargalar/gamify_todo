import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Provider/add_store_item_providerr.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';

class SelectTargetCount extends StatefulWidget {
  const SelectTargetCount({
    super.key,
    this.isStore = false,
  });

  final bool isStore;

  @override
  State<SelectTargetCount> createState() => _SelectTargetCountState();
}

class _SelectTargetCountState extends State<SelectTargetCount> {
  late final dynamic provider = widget.isStore ? context.read<AddStoreItemProvider>() : context.read<AddTaskProvider>();
  late int targetCount;

  @override
  Widget build(BuildContext context) {
    if (widget.isStore) {
      targetCount = context.read<AddStoreItemProvider>().addCount;
    } else {
      targetCount = context.read<AddTaskProvider>().targetCount;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () {
            // Unfocus any text fields when changing target count
            if (!widget.isStore) {
              (provider as AddTaskProvider).unfocusAll();
            } else {
              (provider as AddStoreItemProvider).unfocusAll();
            }
            // Also unfocus using FocusScope for any other fields
            FocusScope.of(context).unfocus();
            if (targetCount > 1) {
              provider.updateTargetCount(targetCount - 1);
            }
            setState(() {});
          },
          onLongPress: () {
            // Unfocus any text fields when changing target count
            if (!widget.isStore) {
              (provider as AddTaskProvider).unfocusAll();
            } else {
              (provider as AddStoreItemProvider).unfocusAll();
            }
            // Also unfocus using FocusScope for any other fields
            FocusScope.of(context).unfocus();
            if (targetCount > 20) {
              provider.updateTargetCount(targetCount - 20);
            } else {
              provider.updateTargetCount(1);
            }
            setState(() {});
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppColors.borderRadiusAll,
            ),
            padding: const EdgeInsets.all(5),
            child: const Icon(
              Icons.remove,
              size: 30,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: AppColors.borderRadiusAll,
          ),
          padding: const EdgeInsets.all(5),
          child: Text(
            targetCount.toString(),
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
        ),
        InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () {
            // Unfocus any text fields when changing target count
            if (!widget.isStore) {
              (provider as AddTaskProvider).unfocusAll();
            } else {
              (provider as AddStoreItemProvider).unfocusAll();
            }
            // Also unfocus using FocusScope for any other fields
            FocusScope.of(context).unfocus();
            provider.updateTargetCount(targetCount + 1);

            setState(() {});
          },
          onLongPress: () {
            // Unfocus any text fields when changing target count
            if (!widget.isStore) {
              (provider as AddTaskProvider).unfocusAll();
            } else {
              (provider as AddStoreItemProvider).unfocusAll();
            }
            // Also unfocus using FocusScope for any other fields
            FocusScope.of(context).unfocus();
            provider.updateTargetCount(targetCount + 20);

            setState(() {});
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppColors.borderRadiusAll,
            ),
            padding: const EdgeInsets.all(5),
            child: const Icon(
              Icons.add,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}
