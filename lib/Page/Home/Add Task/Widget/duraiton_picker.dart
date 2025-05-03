import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Provider/add_store_item_providerr.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';

class DurationPickerWidget extends StatefulWidget {
  const DurationPickerWidget({
    super.key,
    this.isStore = false,
  });

  final bool isStore;

  @override
  State<DurationPickerWidget> createState() => _DurationPickerWidgetState();
}

class _DurationPickerWidgetState extends State<DurationPickerWidget> {
  late final dynamic provider = widget.isStore ? context.read<AddStoreItemProvider>() : context.read<AddTaskProvider>();

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          Row(
            children: [
              Icon(
                Icons.timer_rounded,
                color: AppColors.main,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Duration",
                style: TextStyle(
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

          // Duration picker
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.panelBackground.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.main.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 150,
                height: 150,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: DurationPicker(
                    duration: provider.taskDuration,
                    baseUnit: BaseUnit.minute,
                    onChange: (selectedDuration) {
                      // Unfocus any text fields when changing duration
                      if (!widget.isStore) {
                        (provider as AddTaskProvider).unfocusAll();
                      } else {
                        (provider as AddStoreItemProvider).unfocusAll();
                      }
                      // Also unfocus using FocusScope for any other fields
                      FocusScope.of(context).unfocus();

                      late int duration;

                      if (selectedDuration.inMinutes > 5) {
                        duration = (selectedDuration.inMinutes / 5).round() * 5;
                      } else {
                        duration = selectedDuration.inMinutes;
                      }

                      setState(
                        () {
                          provider.taskDuration = Duration(minutes: duration);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Duration info
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.text.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  "Rotate to set task duration",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Selected duration display
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.main.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatDuration(provider.taskDuration),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.main,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));

    if (duration.inHours > 0) {
      return "${duration.inHours}h ${twoDigitMinutes}m";
    } else {
      return "${duration.inMinutes}m";
    }
  }
}
