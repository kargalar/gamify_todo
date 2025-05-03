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

          // Duration info
          Row(
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
        ],
      ),
    );
  }
}
