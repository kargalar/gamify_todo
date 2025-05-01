import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/Enums/status_enum.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/subtask_model.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';

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

    Navigator.of(context).pop();
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
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.subtask == null ? LocaleKeys.AddSubtask.tr() : LocaleKeys.EditSubtask.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title field
          Text(
            LocaleKeys.Title.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: AppColors.borderRadiusAll,
            ),
            child: TextField(
              controller: _titleController,
              focusNode: _titleFocus,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: LocaleKeys.EnterTitle.tr(),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                _descriptionFocus.requestFocus();
              },
            ),
          ),
          const SizedBox(height: 16),

          // Description field
          Text(
            LocaleKeys.Description.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: AppColors.borderRadiusAll,
            ),
            child: TextField(
              controller: _descriptionController,
              focusNode: _descriptionFocus,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: LocaleKeys.EnterDescription.tr(),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                _saveSubtask();
              },
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSubtask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.main,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: AppColors.borderRadiusAll,
                ),
              ),
              child: Text(
                LocaleKeys.Save.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
