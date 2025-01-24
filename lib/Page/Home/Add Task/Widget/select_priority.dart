import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';

class SelectPriority extends StatelessWidget {
  const SelectPriority({super.key});

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.Priority.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _PriorityOption(
                title: LocaleKeys.HighPriority.tr(),
                value: 1,
                color: Colors.red,
                isSelected: addTaskProvider.priority == 1,
              ),
              const SizedBox(width: 10),
              _PriorityOption(
                title: LocaleKeys.MediumPriority.tr(),
                value: 2,
                color: Colors.orange,
                isSelected: addTaskProvider.priority == 2,
              ),
              const SizedBox(width: 10),
              _PriorityOption(
                title: LocaleKeys.LowPriority.tr(),
                value: 3,
                color: Colors.green,
                isSelected: addTaskProvider.priority == 3,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityOption extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final bool isSelected;

  const _PriorityOption({
    required this.title,
    required this.value,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          context.read<AddTaskProvider>().updatePriority(value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : Colors.grey,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: AppColors.borderRadiusAll,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
