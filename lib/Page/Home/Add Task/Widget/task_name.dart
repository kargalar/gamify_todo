import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Provider/add_store_item_providerr.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';

class TaskName extends StatelessWidget {
  const TaskName({
    super.key,
    this.isStore = false,
    required this.autoFocus,
  });

  final bool isStore;
  final bool autoFocus;

  @override
  Widget build(BuildContext context) {
    late final dynamic provider = isStore ? context.read<AddStoreItemProvider>() : context.read<AddTaskProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Center(
        child: SizedBox(
          width: 375,
          child: TextField(
            autofocus: autoFocus,
            controller: provider.taskNameController,
            decoration: InputDecoration(
              hintText: LocaleKeys.TaskName.tr(),
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            textInputAction: TextInputAction.next,
          ),
        ),
      ),
    );
  }
}
