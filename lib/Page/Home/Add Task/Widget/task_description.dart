import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';

class TaskDescription extends StatelessWidget {
  const TaskDescription({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AddTaskProvider>();

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
            controller: provider.descriptionController,
            focusNode: provider.descriptionFocus,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: LocaleKeys.TaskDescription.tr(),
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            maxLines: 30,
            minLines: 3,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onTap: () {
              // Ensure keyboard doesn't reopen automatically
              try {
                if (provider.descriptionFocus.hashCode != 0 && !provider.descriptionFocus.hasFocus) {
                  provider.descriptionFocus.requestFocus();
                }
              } catch (e) {
                // Focus node may have issues
              }
            },
          ),
        ),
      ),
    );
  }
}
