import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';

/// Generic bottom sheet for adding/editing subtasks
/// Can be used for both TaskModel subtasks and ProjectModel subtasks
class AddSubtaskBottomSheet extends StatefulWidget {
  /// If provided, we're editing an existing subtask
  final String? initialTitle;
  final String? initialDescription;

  /// Callback when save button is pressed
  final Function(String title, String? description) onSave;

  /// Custom title for the sheet (defaults to "Add Subtask" / "Edit Subtask")
  final String? customTitle;

  const AddSubtaskBottomSheet({
    super.key,
    this.initialTitle,
    this.initialDescription,
    required this.onSave,
    this.customTitle,
  });

  @override
  State<AddSubtaskBottomSheet> createState() => _AddSubtaskBottomSheetState();
}

class _AddSubtaskBottomSheetState extends State<AddSubtaskBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // If editing an existing subtask, populate the fields
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
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

    // If adding new subtask, clear and keep sheet open
    // If editing, close the sheet (handled by parent)
    if (widget.initialTitle == null) {
      _titleController.clear();
      _descriptionController.clear();
      _titleFocus.requestFocus();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTitle != null;
    final title = widget.customTitle ?? (isEditing ? LocaleKeys.EditSubtask.tr() : LocaleKeys.AddSubtask.tr());

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
        border: const Border(
          top: BorderSide(color: AppColors.dirtyWhite),
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
                    isEditing ? Icons.edit_note_rounded : Icons.add_task_rounded,
                    color: AppColors.main,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: AppColors.dirtyWhite,
              thickness: 1,
              height: 1,
            ),
          ),

          const SizedBox(height: 8),

          // Title and Description in same container (like project creation)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.panelBackground2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                TextField(
                  controller: _titleController,
                  focusNode: _titleFocus,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: LocaleKeys.Title.tr(),
                    hintStyle: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.4),
                      fontWeight: FontWeight.normal,
                    ),
                    filled: true,
                    fillColor: AppColors.dirtyWhite.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: Icon(
                      Icons.title_rounded,
                      color: AppColors.main.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    _descriptionFocus.requestFocus();
                  },
                ),

                const SizedBox(height: 12),

                // Description field (optional)
                TextField(
                  controller: _descriptionController,
                  focusNode: _descriptionFocus,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: "${LocaleKeys.Description.tr()} (Optional)",
                    hintStyle: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: AppColors.dirtyWhite.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: Icon(
                        Icons.description_outlined,
                        color: AppColors.main.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveSubtask(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveSubtask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.main,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    LocaleKeys.Save.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
