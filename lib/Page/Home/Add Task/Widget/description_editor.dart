import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Provider/add_store_item_provider.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:provider/provider.dart';

class DescriptionEditor extends StatefulWidget {
  const DescriptionEditor({
    super.key,
    this.isStore = false,
  });

  final bool isStore;

  @override
  State<DescriptionEditor> createState() => _DescriptionEditorState();
}

class _DescriptionEditorState extends State<DescriptionEditor> {
  late dynamic _provider;

  @override
  void initState() {
    super.initState();

    if (widget.isStore) {
      _provider = context.read<AddStoreItemProvider>();
    } else {
      _provider = context.read<AddTaskProvider>();
    }

    // Start the timer when the page opens
    _provider.startDescriptionTimer();
  }

  @override
  void dispose() {
    // Pause the timer when leaving the page (time is already being saved every second)
    _provider.pauseDescriptionTimer();
    super.dispose();
  }

  void _autoSave(String text) {
    if (!widget.isStore) {
      // For tasks, check if we're editing an existing task
      final taskProvider = _provider as AddTaskProvider;
      if (taskProvider.editTask != null) {
        // Update the existing task's description
        taskProvider.editTask!.description = text.isNotEmpty ? text : null;
        // Save to database
        ServerManager().updateTask(taskModel: taskProvider.editTask!);
      }
      // For new tasks, the description will be saved when the task is created
    } else {
      // For store items, check if we're editing an existing item
      final storeProvider = _provider as AddStoreItemProvider;
      if (storeProvider.editItem != null) {
        // Create a new ItemModel with updated description since description is final
        final updatedItem = ItemModel(
          id: storeProvider.editItem!.id,
          title: storeProvider.editItem!.title,
          description: text.isNotEmpty ? text : null,
          type: storeProvider.editItem!.type,
          credit: storeProvider.editItem!.credit,
          currentCount: storeProvider.editItem!.currentCount,
          currentDuration: storeProvider.editItem!.currentDuration,
          addDuration: storeProvider.editItem!.addDuration,
          addCount: storeProvider.editItem!.addCount,
          isTimerActive: storeProvider.editItem!.isTimerActive,
        );

        // Update the editItem reference
        storeProvider.editItem = updatedItem;

        // Save to database
        ServerManager().updateItem(itemModel: updatedItem);
      }
      // For new store items, the description will be saved when the item is created
    }
  }

  void _copyDescription() {
    final description = _provider.descriptionController.text;
    if (description.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: description));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.CopiedDescription.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () {
            Navigator.of(context).pop();
          },
          child: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          LocaleKeys.Description.tr(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Description input area
            Expanded(
              child: Container(
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
                child: TextField(
                  controller: _provider.descriptionController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: LocaleKeys.EnterDescription.tr(),
                    hintStyle: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.4),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(
                      left: 16,
                      top: 10,
                      bottom: 12,
                    ),
                  ),
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChanged: (value) {
                    setState(() {}); // Update UI to reflect changes
                    _autoSave(value); // Auto-save immediately
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Character count and tips
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.panelBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          widget.isStore
                              ? Consumer<AddStoreItemProvider>(
                                  builder: (context, provider, child) {
                                    return Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: AppColors.text.withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Time: ${provider.formatDescriptionTime()}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.text.withValues(alpha: 0.6),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            provider.resetDescriptionTimer();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.panelBackground,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: AppColors.text.withValues(alpha: 0.1),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              'Reset',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.text.withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : Consumer<AddTaskProvider>(
                                  builder: (context, provider, child) {
                                    return Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: AppColors.text.withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Time: ${provider.formatDescriptionTime()}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.text.withValues(alpha: 0.6),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: AppColors.text.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Characters: ${_provider.descriptionController.text.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.text.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _copyDescription,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.panelBackground,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.text.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: AppColors.text.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                LocaleKeys.Copy.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.text.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
