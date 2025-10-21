import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';

/// Bottom sheet for adding/editing project notes with title and description
class AddProjectNoteBottomSheet extends StatefulWidget {
  /// If provided, we're editing an existing note
  final String? initialTitle;
  final String? initialContent;

  /// Callback when save button is pressed
  final Function(String? title, String? content) onSave;

  const AddProjectNoteBottomSheet({
    super.key,
    this.initialTitle,
    this.initialContent,
    required this.onSave,
  });

  @override
  State<AddProjectNoteBottomSheet> createState() => _AddProjectNoteBottomSheetState();
}

class _AddProjectNoteBottomSheetState extends State<AddProjectNoteBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // If editing an existing note, populate the fields
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }

    // Auto-focus the title field when the sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Title veya content'ten en az biri dolu olmalı
    if (title.isEmpty && content.isEmpty) {
      Helper().getMessage(
        message: LocaleKeys.NoteValidationMessage.tr(),
        status: StatusEnum.WARNING,
      );
      return;
    }

    widget.onSave(
      title.isEmpty ? null : title,
      content.isEmpty ? null : content,
    );

    // If adding new note, clear and keep sheet open
    // If editing, close the sheet (handled by parent)
    if (widget.initialContent == null) {
      _titleController.clear();
      _contentController.clear();
      _titleFocus.requestFocus();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialContent != null;

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
                    isEditing ? Icons.edit_note_rounded : Icons.note_add_rounded,
                    color: AppColors.main,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? "Edit Note" : "Add Note",
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

          // Title and Content in same container (like project creation)
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
                // Title field (optional)
                TextField(
                  controller: _titleController,
                  focusNode: _titleFocus,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: "${LocaleKeys.Title.tr()} (Optional)",
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
                    _contentFocus.requestFocus();
                  },
                ),

                const SizedBox(height: 12),

                // Content field
                TextField(
                  controller: _contentController,
                  focusNode: _contentFocus,
                  maxLines: 5,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: "Content",
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
                      padding: const EdgeInsets.only(bottom: 80),
                      child: Icon(
                        Icons.notes_rounded,
                        color: AppColors.main.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveNote(),
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
              onPressed: _saveNote,
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
