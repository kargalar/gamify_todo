import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Provider/add_store_item_providerr.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Widgets/clickable_tooltip.dart';
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
          ClickableTooltip(
            title: LocaleKeys.TaskName.tr(),
            bulletPoints: const ["Give your task a clear, descriptive name", "Use specific names to easily identify tasks", "Keep names concise but informative"],
            child: Container(
              color: AppColors.transparent,
              child: Row(
                children: [
                  Icon(
                    Icons.title_rounded,
                    color: AppColors.main,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LocaleKeys.TaskName.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Task name input field
          Container(
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withValues(alpha: 0.7),
            ),
            child: TextField(
              autofocus: autoFocus,
              controller: provider.taskNameController,
              focusNode: provider.taskNameFocus,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: LocaleKeys.TaskName.tr(),
                hintStyle: TextStyle(
                  color: AppColors.text.withValues(alpha: 0.4),
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: Icon(
                  Icons.edit_rounded,
                  color: AppColors.text.withValues(alpha: 0.4),
                  size: 20,
                ),
                suffixIcon: provider.taskNameController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppColors.text.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        onPressed: () {
                          provider.taskNameController.clear();
                          provider.notifyListeners();
                        },
                      )
                    : null,
              ),
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                provider.notifyListeners();
              },
              onEditingComplete: () {
                // Move focus to description when done
                if (provider.descriptionFocus.hashCode != 0) {
                  provider.descriptionFocus.requestFocus();
                }
              },
            ),
          ),

          // Description input field
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withValues(alpha: 0.7),
            ),
            child: TextField(
              controller: provider.descriptionController,
              focusNode: provider.descriptionFocus,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: LocaleKeys.EnterDescription.tr(),
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
                          provider.notifyListeners();
                        },
                      )
                    : null,
              ),
              maxLines: 3,
              minLines: 2,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: (value) {
                provider.notifyListeners();
              },
            ),
          ),
        ],
      ),
    );
  }
}
