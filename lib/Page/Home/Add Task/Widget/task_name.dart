import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/description_editor.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/add_store_item_provider.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/select_priority.dart';
import 'package:provider/provider.dart';

class TaskName extends StatelessWidget {
  const TaskName({
    super.key,
    this.isStore = false,
    required this.autoFocus,
    this.onTaskSubmit,
  });

  final bool isStore;
  final bool autoFocus;
  final VoidCallback? onTaskSubmit;

  @override
  Widget build(BuildContext context) {
    dynamic provider = isStore ? context.watch<AddStoreItemProvider>() : context.watch<AddTaskProvider>();

    // Get priority info if not store
    Color? priorityColor;
    IconData? priorityIcon;
    String? priorityText;
    if (!isStore) {
      final addTaskProvider = provider as AddTaskProvider;
      switch (addTaskProvider.priority) {
        case 1:
          priorityColor = Colors.red;
          priorityIcon = Icons.priority_high_rounded;
          priorityText = LocaleKeys.HighPriority.tr();
          break;
        case 2:
          priorityColor = Colors.orange;
          priorityIcon = Icons.drag_handle_rounded;
          priorityText = LocaleKeys.MediumPriority.tr();
          break;
        default:
          priorityColor = Colors.green;
          priorityIcon = Icons.arrow_downward_rounded;
          priorityText = LocaleKeys.LowPriority.tr();
      }
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              children: [
                Container(
                  color: AppColors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        Icons.text_fields_rounded,
                        color: AppColors.main,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isStore ? "Item Name" : LocaleKeys.TaskName.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isStore) ...[
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            (provider as AddTaskProvider).unfocusAll();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              barrierColor: Colors.transparent,
                              builder: (context) => const PriorityBottomSheet(),
                            );
                          },
                          child: Container(
                            color: AppColors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  priorityIcon!,
                                  color: priorityColor!,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  priorityText!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: priorityColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Divider
                Divider(
                  color: AppColors.text.withValues(alpha: 0.1),
                  height: 1,
                ),
              ],
            ),
          ),

          // Combined task name and description container
          Container(
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task name input field
                TextField(
                  autofocus: autoFocus,
                  controller: provider.taskNameController,
                  focusNode: provider.taskNameFocus,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: LocaleKeys.TaskName.tr(),
                    hintStyle: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.4),
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    // prefixIcon: Icon(
                    //   Icons.edit_rounded,
                    //   color: AppColors.text.withValues(alpha: 0.4),
                    //   size: 20,
                    // ),
                    // suffixIcon: provider.taskNameController.text.isNotEmpty
                    //     ? IconButton(
                    //         icon: Icon(
                    //           Icons.clear_rounded,
                    //           color: AppColors.text.withValues(alpha: 0.6),
                    //           size: 20,
                    //         ),
                    //         onPressed: () {
                    //           provider.taskNameController.clear();
                    //           provider.notifyListeners();
                    //         },
                    //       )
                    //     : null,
                  ),
                  textInputAction: TextInputAction.done,
                  onChanged: (value) {
                    provider.notifyListeners();
                  },
                  onEditingComplete: () {
                    // Add task when editing is complete
                    if (!isStore && onTaskSubmit != null) {
                      onTaskSubmit!();
                    }
                  },
                ),

                // Description clickable field
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Unfocus any text fields before showing full-screen editor
                      provider.unfocusAll();

                      // Show the full-screen description editor
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          builder: (context) => DescriptionEditor(isStore: isStore),
                          fullscreenDialog: true,
                        ),
                      )
                          .then((_) {
                        provider.notifyListeners();
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(
                        minHeight: 50, // Minimum height for the description field
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: provider.descriptionController.text.isNotEmpty
                                ? Text(
                                    provider.descriptionController.text,
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : Text(
                                    LocaleKeys.EnterDescription.tr(),
                                    style: TextStyle(
                                      color: AppColors.text.withValues(alpha: 0.4),
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),

                          // Arrow icon to indicate it opens a full-screen editor
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.text.withValues(alpha: 0.3),
                            size: 14,
                          ),
                        ],
                      ),
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
