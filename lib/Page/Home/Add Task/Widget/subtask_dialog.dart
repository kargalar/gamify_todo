import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class SubtaskDialog extends StatefulWidget {
  final SubTaskModel? subtask; // If provided, we're editing an existing subtask
  final Function(String title, String? description) onSave;

  const SubtaskDialog({
    super.key,
    this.subtask,
    required this.onSave,
  });

  @override
  State<SubtaskDialog> createState() => _SubtaskDialogState();
}

class _SubtaskDialogState extends State<SubtaskDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // If editing an existing subtask, populate the fields
    if (widget.subtask != null) {
      _titleController.text = widget.subtask!.title;
      if (widget.subtask!.description != null) {
        _descriptionController.text = widget.subtask!.description!;
      }
    }

    // Auto-focus the title field when the dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _saveSubtask() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      Helper().getMessage(
        message: LocaleKeys.SubtaskEmpty.tr(),
        status: StatusEnum.WARNING,
      );
      return;
    }

    widget.onSave(title, description.isEmpty ? null : description);

    if (widget.subtask != null) {
      Navigator.of(context).pop();
    } else {
      _titleController.clear();
      _descriptionController.clear();
      _titleFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    widget.subtask == null ? Icons.add_task_rounded : Icons.edit_note_rounded,
                    color: AppColors.main,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.subtask == null ? LocaleKeys.AddSubtask.tr() : LocaleKeys.EditSubtask.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                  ),
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
          Container(
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.main.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task name input field
                TextField(
                  autofocus: true,
                  controller: _titleController,
                  focusNode: _titleFocus,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    _descriptionFocus.requestFocus();
                  },
                ),

                // Description input field
                TextField(
                  controller: _descriptionController,
                  focusNode: _descriptionFocus,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: LocaleKeys.EnterDescription.tr(),
                    hintStyle: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.4),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                  maxLines: 5,
                  minLines: 2,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onSubmitted: (_) {
                    _saveSubtask();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              // Cancel button
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Save button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saveSubtask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.main,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    LocaleKeys.Save.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
