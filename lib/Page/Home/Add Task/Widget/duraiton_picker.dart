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
        borderRadius: AppColors.borderRadiusAll,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: FittedBox(
              fit: BoxFit.contain,
              child: DurationPicker(
                duration: provider.taskDuration,
                onChange: (selectedDuration) {
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
        ],
      ),
    );
  }
}
