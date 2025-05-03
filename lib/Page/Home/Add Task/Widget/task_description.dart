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
                Icons.description_rounded,
                color: AppColors.main,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.TaskDescription.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                " (Optional)",
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                  color: AppColors.text.withValues(alpha: 0.5),
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

          // Description input field
          Container(
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.main.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: provider.descriptionController,
              focusNode: provider.descriptionFocus,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: LocaleKeys.TaskDescription.tr(),
                hintStyle: TextStyle(
                  color: AppColors.text.withValues(alpha: 0.4),
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Icon(
                    Icons.notes_rounded,
                    color: AppColors.text.withValues(alpha: 0.4),
                    size: 20,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                suffixIcon: provider.descriptionController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppColors.text.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        onPressed: () {
                          provider.descriptionController.clear();
                        },
                      )
                    : null,
              ),
              maxLines: 5,
              minLines: 3,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: (value) {
                // Update description
              },
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

          // Description info
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
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
                    "Add details, notes, or instructions for your task",
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
}
