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
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                color: AppColors.main,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.Priority.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Priority selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              PriorityButton(
                title: LocaleKeys.HighPriority.tr(),
                value: 1,
                color: Colors.red,
                icon: Icons.priority_high_rounded,
                isSelected: addTaskProvider.priority == 1,
              ),
              const SizedBox(width: 12),
              PriorityButton(
                title: LocaleKeys.MediumPriority.tr(),
                value: 2,
                color: Colors.orange,
                icon: Icons.drag_handle_rounded,
                isSelected: addTaskProvider.priority == 2,
              ),
              const SizedBox(width: 12),
              PriorityButton(
                title: LocaleKeys.LowPriority.tr(),
                value: 3,
                color: Colors.green,
                icon: Icons.arrow_downward_rounded,
                isSelected: addTaskProvider.priority == 3,
              ),
            ],
          ),

          // Priority info
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.text.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getPriorityInfoText(addTaskProvider.priority),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPriorityInfoText(int priority) {
    switch (priority) {
      case 1:
        return "High priority tasks will appear at the top of your list.";
      case 2:
        return "Medium priority tasks will appear in the middle of your list.";
      case 3:
        return "Low priority tasks will appear at the bottom of your list.";
      default:
        return "Select a priority level for your task.";
    }
  }
}

class PriorityButton extends StatefulWidget {
  const PriorityButton({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    required this.isSelected,
  });

  final String title;
  final int value;
  final Color color;
  final IconData icon;
  final bool isSelected;

  @override
  State<PriorityButton> createState() => _PriorityButtonState();
}

class _PriorityButtonState extends State<PriorityButton> {
  late final addTaskProvider = context.read<AddTaskProvider>();
  late bool isSelected;

  @override
  void initState() {
    super.initState();
    isSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(PriorityButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      isSelected = widget.isSelected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Unfocus any text fields when selecting priority
            addTaskProvider.unfocusAll();

            setState(() {
              isSelected = true;
            });

            addTaskProvider.updatePriority(widget.value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? widget.color.withValues(alpha: 0.15) : AppColors.panelBackground.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? widget.color : AppColors.text.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? widget.color : AppColors.text.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
