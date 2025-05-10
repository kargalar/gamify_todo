import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Provider/add_store_item_providerr.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Widgets/clickable_tooltip.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Target count title
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClickableTooltip(
            title: "Target Count",
            bulletPoints: const ["Set how many times this task needs to be completed", "Tap +/- to change by 1", "Long press +/- to change by 20", "Counter will track your progress"],
            child: Row(
              children: [
                Icon(
                  Icons.format_list_numbered_rounded,
                  size: 18,
                  color: AppColors.main.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  "Target Count",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Target count selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decrease button
            _buildCountButton(
              icon: Icons.remove_rounded,
              onTap: () {
                _unfocusFields();
                if (targetCount > 1) {
                  provider.updateTargetCount(targetCount - 1);
                }
                setState(() {});
              },
              onLongPress: () {
                _unfocusFields();
                if (targetCount > 20) {
                  provider.updateTargetCount(targetCount - 20);
                } else {
                  provider.updateTargetCount(1);
                }
                setState(() {});
              },
            ),

            // Count display
            Container(
              width: 80,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.main.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.main.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  targetCount.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),

            // Increase button
            _buildCountButton(
              icon: Icons.add_rounded,
              onTap: () {
                _unfocusFields();
                provider.updateTargetCount(targetCount + 1);
                setState(() {});
              },
              onLongPress: () {
                _unfocusFields();
                provider.updateTargetCount(targetCount + 20);
                setState(() {});
              },
            ),
          ],
        ),
      ],
    );
  }

  void _unfocusFields() {
    // Unfocus any text fields when changing target count
    if (!widget.isStore) {
      (provider as AddTaskProvider).unfocusAll();
    } else {
      (provider as AddStoreItemProvider).unfocusAll();
    }
    // Also unfocus using FocusScope for any other fields
    FocusScope.of(context).unfocus();
  }

  Widget _buildCountButton({
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.main.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
