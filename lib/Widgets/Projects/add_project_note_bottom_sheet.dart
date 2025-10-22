import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/Common/add_item_dialog.dart';

/// Bottom sheet for adding/editing project notes with title and description
class AddProjectNoteBottomSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isEditing = initialContent != null;

    return AddItemDialog(
      title: isEditing ? "Edit Note" : "Add Note",
      icon: isEditing ? Icons.edit_note_rounded : Icons.note_add_rounded,
      titleLabel: "${LocaleKeys.Title.tr()} (Optional)",
      titleHint: "${LocaleKeys.Title.tr()} (Optional)",
      titleRequired: false,
      initialTitle: initialTitle,
      descriptionLabel: "Content",
      descriptionHint: "Content",
      descriptionRequired: false,
      initialDescription: initialContent,
      descriptionMaxLines: 5,
      descriptionMinLines: 3,
      showCancelButton: false,
      emptyValidationMessage: LocaleKeys.NoteValidationMessage.tr(),
      onSave: onSave,
      isEditing: isEditing,
    );
  }
}
