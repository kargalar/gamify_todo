import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          LocaleKeys.Description.tr(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    contentPadding: const EdgeInsets.all(16),
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
            ),
          ],
        ),
      ),
    );
  }
}
