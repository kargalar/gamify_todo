import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Model/note_model.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Widgets/Notes/category_selector_bottom_sheet.dart';

/// Not ekleme ve düzenleme bottom sheet'i
class AddEditNoteBottomSheet extends StatefulWidget {
  final NoteModel? note;
  final VoidCallback? onDismiss;

  const AddEditNoteBottomSheet({super.key, this.note, this.onDismiss});

  @override
  State<AddEditNoteBottomSheet> createState() => _AddEditNoteBottomSheetState();
}

class _AddEditNoteBottomSheetState extends State<AddEditNoteBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final FocusNode _titleFocusNode = FocusNode();

  CategoryModel? _selectedCategory;
  late bool _isPinned;
  bool _isSaving = false;

  bool get isEditing => widget.note != null;

  /// Değişiklik olup olmadığını kontrol eder
  bool _hasChanges() {
    if (!isEditing) return false;

    return _titleController.text.trim() != (widget.note?.title ?? '') || _contentController.text.trim() != (widget.note?.content ?? '') || _selectedCategory?.id != widget.note?.categoryId || _isPinned != (widget.note?.isPinned ?? false);
  }

  /// Otomatik kaydetme (düzenleme modunda)
  Future<void> _autoSave() async {
    if (!isEditing || !_hasChanges()) return;

    debugPrint('💾 AddEditNoteBottomSheet: Auto-saving changes');

    try {
      final provider = context.read<NotesProvider>();
      final updatedNote = widget.note!.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        categoryId: _selectedCategory?.id,
        isPinned: _isPinned,
        updatedAt: DateTime.now(),
      );
      final success = await provider.updateNote(updatedNote);

      if (success) {
        debugPrint('✅ AddEditNoteBottomSheet: Auto-saved successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleKeys.NoteUpdated.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint('❌ AddEditNoteBottomSheet: Auto-save failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleKeys.NoteUpdateFailed.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ AddEditNoteBottomSheet: Auto-save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleKeys.ErrorOccurred.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');

    // Initialize state
    _isPinned = widget.note?.isPinned ?? false;

    // Kategoriyi yükle
    if (widget.note?.categoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<NotesProvider>(context, listen: false);
        _selectedCategory = provider.getCategoryById(widget.note!.categoryId);
        if (mounted) setState(() {});
      });
    }

    // Otomatik focus için (yeni not eklerken)
    if (!isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
      });
    }

    debugPrint('🔧 AddEditNoteBottomSheet:   Initialized ${isEditing ? "edit" : "add"} mode');
  }

  @override
  void dispose() {
    widget.onDismiss?.call();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: true,
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) {
        if (didPop && isEditing) {
          Future.microtask(() => _autoSave());
        }
      },
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.grey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          isEditing ? LocaleKeys.EditNote.tr() : LocaleKeys.NewNote.tr(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const Spacer(),
                        if (isEditing)
                          IconButton(
                            icon: Icon(
                              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              color: _isPinned ? AppColors.yellow : AppColors.text,
                            ),
                            onPressed: () async {
                              setState(() {
                                _isPinned = !_isPinned;
                              });
                              // Pin değişikliğini hemen kaydet
                              final provider = context.read<NotesProvider>();
                              await provider.togglePinNote(widget.note!.id, _isPinned);
                              debugPrint('📌 Note pin toggled to: $_isPinned');
                            },
                            tooltip: _isPinned ? LocaleKeys.Unpin.tr() : LocaleKeys.Pin.tr(),
                          ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.text),
                          onPressed: () async {
                            if (isEditing) await _autoSave();
                            widget.onDismiss?.call();
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Başlık ve İçerik (tek container'da)
                          _buildNoteFields(),
                          const SizedBox(height: 20),

                          // Kategori seçimi (kompakt buton)
                          _buildCategorySelectorButton(),
                          const SizedBox(height: 24),

                          // Kaydet butonu (sadece yeni not ekleme için)
                          if (!isEditing) _buildSaveButton(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Başlık ve içerik alanları (tek container'da - task'lardaki gibi)
  Widget _buildNoteFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.panelBackground2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          TextFormField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              hintText: LocaleKeys.Title.tr(),
              hintStyle: const TextStyle(color: AppColors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return LocaleKeys.TitleRequired.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.panelBackground2, height: 1),
          const SizedBox(height: 12),
          // İçerik (opsiyonel)
          TextFormField(
            controller: _contentController,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              hintText: LocaleKeys.ContentOptional.tr(),
              hintStyle: const TextStyle(color: AppColors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: 10,
            minLines: 5,
          ),
        ],
      ),
    );
  }

  /// Kategori seçici butonu (kompakt)
  Widget _buildCategorySelectorButton() {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.Category.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showCategorySelector(context, provider),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.panelBackground2),
                ),
                child: Row(
                  children: [
                    if (_selectedCategory != null) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _selectedCategory!.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _selectedCategory!.iconCodePoint != null ? IconData(_selectedCategory!.iconCodePoint!, fontFamily: 'MaterialIcons') : Icons.category,
                          size: 18,
                          color: _selectedCategory!.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedCategory!.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(_selectedCategory!.colorValue),
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.category_outlined, size: 20, color: AppColors.grey),
                      const SizedBox(width: 12),
                      Text(
                        LocaleKeys.NoCategory.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: AppColors.grey),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Kategori seçici bottom sheet'i göster
  Future<void> _showCategorySelector(BuildContext context, NotesProvider provider) async {
    final selected = await showModalBottomSheet<CategoryModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategorySelectorBottomSheet(
        selectedCategory: _selectedCategory,
        categories: provider.categories,
        onCategoryAdded: (category) async {
          debugPrint('➕ AddEditNoteBottomSheet: New category created ${category.name}');
          // Kategori zaten CreateCategoryBottomSheet içinde CategoryProvider'a eklendi
          // Sadece NotesProvider'ın kategoriler listesini güncellememiz gerekiyor
          await provider.loadData();
        },
        onCategoryDeleted: (category) async {
          debugPrint('🗑️ AddEditNoteBottomSheet: Deleting category ${category.name}');
          await provider.deleteCategory(category.id);
        },
      ),
    );

    if (selected != null || selected == null) {
      setState(() {
        _selectedCategory = selected;
      });
      debugPrint('📌 AddEditNoteBottomSheet: Category selected - ${selected?.name ?? "None"}');
    }
  }

  /// Kaydet butonu
  Widget _buildSaveButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveNote,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedCategory != null ? Color(_selectedCategory!.colorValue) : AppColors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(
          _isSaving
              ? LocaleKeys.Saving.tr()
              : isEditing
                  ? LocaleKeys.Update.tr()
                  : LocaleKeys.Save.tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = context.read<NotesProvider>();

      bool success;

      if (isEditing) {
        // Mevcut notu güncelle
        debugPrint('📝 AddEditNoteBottomSheet: Updating note ${widget.note!.id}');
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          categoryId: _selectedCategory?.id,
          isPinned: _isPinned,
          updatedAt: DateTime.now(),
        );
        success = await provider.updateNote(updatedNote);
      } else {
        // Yeni not ekle
        debugPrint('➕ AddEditNoteBottomSheet: Adding new note');
        success = await provider.addNote(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          categoryId: _selectedCategory?.id,
        );
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (success) {
          debugPrint('✅ AddEditNoteBottomSheet: Note saved successfully');
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing ? LocaleKeys.NoteUpdated.tr() : LocaleKeys.NoteAdded.tr(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          debugPrint('❌ AddEditNoteBottomSheet: Failed to save note');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing ? LocaleKeys.NoteUpdateFailed.tr() : LocaleKeys.NoteSaveFailed.tr(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ AddEditNoteBottomSheet: Error saving note: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ErrorOccurred'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
