import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Service/logging_service.dart';
import '../Model/project_model.dart';
import '../Model/note_model.dart';
import '../Model/category_model.dart';
import '../Provider/projects_provider.dart';
import '../Provider/notes_provider.dart';
import '../Service/locale_keys.g.dart';
import '../General/app_colors.dart';
import '../General/category_icons.dart';
import 'Notes/category_selector_bottom_sheet.dart';
import 'Common/description_editor.dart';

/// Item türleri
enum ItemType {
  project,
  note,
}

/// Generic item ekleme ve düzenleme bottom sheet'i
/// Hem proje hem not için ortak kod
class AddEditItemBottomSheet extends StatefulWidget {
  final ItemType type;
  final dynamic item; // ProjectModel? veya NoteModel?
  final VoidCallback? onDismiss;

  const AddEditItemBottomSheet({
    super.key,
    required this.type,
    this.item,
    this.onDismiss,
  });

  @override
  State<AddEditItemBottomSheet> createState() => _AddEditItemBottomSheetState();
}

class _AddEditItemBottomSheetState extends State<AddEditItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final FocusNode _titleFocusNode = FocusNode();

  CategoryModel? _selectedCategory;
  late bool _isPinned;
  bool _isSaving = false;

  bool get isEditing => widget.item != null;

  /// Değişiklik olup olmadığını kontrol eder (sadece not için)
  bool _hasChanges() {
    if (!isEditing || widget.type != ItemType.note) return false;

    final note = widget.item as NoteModel;
    return _titleController.text.trim() != (note.title) || _contentController.text.trim() != (note.content) || _selectedCategory?.id != note.categoryId || _isPinned != note.isPinned;
  }

  /// Otomatik kaydetme (sadece not için)
  Future<void> _autoSave() async {
    if (!isEditing || widget.type != ItemType.note || !_hasChanges()) return;

    LogService.debug('💾 AddEditItemBottomSheet: Auto-saving changes');

    try {
      final provider = context.read<NotesProvider>();
      final note = widget.item as NoteModel;
      final updatedNote = note.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        categoryId: _selectedCategory?.id,
        isPinned: _isPinned,
        updatedAt: DateTime.now(),
      );
      final success = await provider.updateNote(updatedNote);

      if (success) {
        LogService.debug('✅ AddEditItemBottomSheet: Auto-saved successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleKeys.NoteUpdated.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        LogService.error('❌ AddEditItemBottomSheet: Auto-save failed');
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
      LogService.error('❌ AddEditItemBottomSheet: Auto-save error: $e');
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
    _titleController = TextEditingController(text: _getTitle());
    _contentController = TextEditingController(text: _getContent());

    // Initialize state
    _isPinned = _getIsPinned();

    // Kategoriyi yükle
    final categoryId = _getCategoryId();
    if (categoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = _getProvider(context, listen: false);
        _selectedCategory = provider.getCategoryById(categoryId);
        if (mounted) setState(() {});
      });
    }

    // Otomatik focus için (yeni item eklerken)
    if (!isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
      });
    }

    // Proje için autofocus
    if (widget.type == ItemType.project && !isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(FocusNode());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final titleFocus = FocusNode();
              FocusScope.of(context).requestFocus(titleFocus);
            }
          });
        }
      });
    }

    LogService.debug('🔧 AddEditItemBottomSheet: Initialized ${widget.type} ${isEditing ? "edit" : "add"} mode');
  }

  @override
  void dispose() {
    widget.onDismiss?.call();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  // Helper methods for type-specific data
  String _getTitle() {
    if (widget.item == null) return '';
    return widget.type == ItemType.project ? (widget.item as ProjectModel).title : (widget.item as NoteModel).title;
  }

  String _getContent() {
    if (widget.item == null) return '';
    return widget.type == ItemType.project ? (widget.item as ProjectModel).description : (widget.item as NoteModel).content;
  }

  bool _getIsPinned() {
    if (widget.item == null) return false;
    return widget.type == ItemType.project ? (widget.item as ProjectModel).isPinned : (widget.item as NoteModel).isPinned;
  }

  String? _getCategoryId() {
    if (widget.item == null) return null;
    return widget.type == ItemType.project ? (widget.item as ProjectModel).categoryId : (widget.item as NoteModel).categoryId;
  }

  dynamic _getProvider(BuildContext context, {bool listen = true}) {
    return widget.type == ItemType.project ? (listen ? context.watch<ProjectsProvider>() : context.read<ProjectsProvider>()) : (listen ? context.watch<NotesProvider>() : context.read<NotesProvider>());
  }

  String _getTitleHint() {
    return widget.type == ItemType.project ? LocaleKeys.ProjectTitle.tr() : LocaleKeys.Title.tr();
  }

  String _getContentHint() {
    return widget.type == ItemType.project ? LocaleKeys.ProjectDescriptionHint.tr() : LocaleKeys.ContentOptional.tr();
  }

  String _getHeaderTitle() {
    if (isEditing) {
      return widget.type == ItemType.project ? LocaleKeys.EditProject.tr() : LocaleKeys.EditNote.tr();
    } else {
      return widget.type == ItemType.project ? LocaleKeys.NewProject.tr() : LocaleKeys.NewNote.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: true,
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) {
        if (didPop && isEditing && widget.type == ItemType.note) {
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
              border: const Border(
                top: BorderSide(color: AppColors.dirtyWhite),
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
                          _getHeaderTitle(),
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
                              // Pin değişikliğini hemen kaydet (sadece not için)
                              if (widget.type == ItemType.note) {
                                final provider = context.read<NotesProvider>();
                                await provider.togglePinNote((widget.item as NoteModel).id, _isPinned);
                                LogService.debug('📌 Note pin toggled to: $_isPinned');
                              }
                            },
                            tooltip: _isPinned ? LocaleKeys.Unpin.tr() : LocaleKeys.Pin.tr(),
                          ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.text),
                          onPressed: () async {
                            if (isEditing && widget.type == ItemType.note) await _autoSave();
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
                          _buildItemFields(),
                          const SizedBox(height: 20),

                          // Kategori seçimi (kompakt buton)
                          _buildCategorySelectorButton(),
                          const SizedBox(height: 24),

                          // Kaydet butonu (not için sadece yeni ekleme, proje için her zaman)
                          if (widget.type == ItemType.project || !isEditing) _buildSaveButton(),
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

  /// Başlık ve içerik alanları (tek container'da)
  Widget _buildItemFields() {
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              hintText: _getTitleHint(),
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
          // İçerik (opsiyonel) - tam ekran iconu
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.fullscreen, size: 20),
                onPressed: () async {
                  LogService.debug('🔍 AddEditItemBottomSheet: Opening full screen editor');
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DescriptionEditor(
                        controller: _contentController,
                        onChanged: (value) => setState(() {}),
                        title: widget.type == ItemType.project ? LocaleKeys.EditProject.tr() : LocaleKeys.EditNote.tr(),
                      ),
                    ),
                  );
                  LogService.debug('✅ AddEditItemBottomSheet: Returned from full screen editor');
                },
                tooltip: 'Tam Ekran',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _contentController,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              hintText: _getContentHint(),
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
    if (widget.type == ItemType.project) {
      return Consumer<ProjectsProvider>(
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
                            color: widget.type == ItemType.project ? Color(_selectedCategory!.colorValue).withValues(alpha: 0.2) : _selectedCategory!.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.type == ItemType.project ? CategoryIcons.getIconByCodePoint(_selectedCategory!.iconCodePoint) ?? Icons.category : (CategoryIcons.getIconByCodePoint(_selectedCategory!.iconCodePoint) ?? Icons.category),
                            size: 18,
                            color: widget.type == ItemType.project ? Color(_selectedCategory!.colorValue) : _selectedCategory!.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.type == ItemType.project ? _selectedCategory!.name : _selectedCategory!.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.type == ItemType.project ? Color(_selectedCategory!.colorValue) : Color(_selectedCategory!.colorValue),
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.category_outlined, size: 20, color: AppColors.grey),
                        const SizedBox(width: 12),
                        Text(
                          widget.type == ItemType.project ? 'Uncategorized' : LocaleKeys.NoCategory.tr(),
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
    } else {
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
                            color: widget.type == ItemType.project ? Color(_selectedCategory!.colorValue).withValues(alpha: 0.2) : _selectedCategory!.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.type == ItemType.project ? CategoryIcons.getIconByCodePoint(_selectedCategory!.iconCodePoint) ?? Icons.category : (CategoryIcons.getIconByCodePoint(_selectedCategory!.iconCodePoint) ?? Icons.category),
                            size: 18,
                            color: widget.type == ItemType.project ? Color(_selectedCategory!.colorValue) : _selectedCategory!.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.type == ItemType.project ? _selectedCategory!.name : _selectedCategory!.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.type == ItemType.project ? Color(_selectedCategory!.colorValue) : Color(_selectedCategory!.colorValue),
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.category_outlined, size: 20, color: AppColors.grey),
                        const SizedBox(width: 12),
                        Text(
                          widget.type == ItemType.project ? "Uncategorized".tr() : LocaleKeys.NoCategory.tr(),
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
  }

  /// Kategori seçici bottom sheet'i göster
  Future<void> _showCategorySelector(BuildContext context, dynamic provider) async {
    LogService.debug('🔍 AddEditItemBottomSheet: Showing category selector for ${widget.type}');
    if (provider == null) {
      LogService.error('❌ AddEditItemBottomSheet: Provider is null, cannot show category selector');
      return;
    }
    final selected = await showModalBottomSheet<CategoryModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => widget.type == ItemType.project
          ? CategorySelectorBottomSheet(
              selectedCategory: _selectedCategory,
              categories: provider.categories,
              categoryType: CategoryType.project,
              onCategoryAdded: (category) async {
                LogService.debug('➕ AddEditItemBottomSheet: New category created ${category.name} for project');
                await provider.loadCategories();
              },
            )
          : CategorySelectorBottomSheet(
              selectedCategory: _selectedCategory,
              categories: provider.categories,
              categoryType: CategoryType.note,
              onCategoryAdded: (category) async {
                LogService.debug('➕ AddEditItemBottomSheet: New category created ${category.name}');
                await provider.loadData();
              },
              onCategoryDeleted: (category) async {
                LogService.debug('🗑️ AddEditItemBottomSheet: Deleting category ${category.name}');
                await provider.deleteCategory(category.id);
              },
            ),
    );

    // Proje için yeni kategori kontrolü
    if (widget.type == ItemType.project && selected != null && !provider.categories.any((cat) => cat.id == selected.id)) {
      LogService.debug('🔄 AddEditItemBottomSheet: New category detected, reloading categories');
      await provider.loadCategories();
    }

    if (mounted) {
      setState(() {
        _selectedCategory = selected;
      });
      LogService.debug('✅ AddEditItemBottomSheet: Category selected: ${selected?.name ?? "None"}');
    }
  }

  /// Kaydet butonu
  Widget _buildSaveButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.type == ItemType.note && _selectedCategory != null ? Color(_selectedCategory!.colorValue) : AppColors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isEditing ? 'Update'.tr() : 'Create'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Save operation
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = _getProvider(context, listen: false);
      final now = DateTime.now();

      bool success;
      if (widget.type == ItemType.project) {
        final project = ProjectModel(
          id: widget.item?.id ?? 'proj_${now.millisecondsSinceEpoch}',
          title: _titleController.text.trim(),
          description: _contentController.text.trim(),
          createdAt: widget.item?.createdAt ?? now,
          updatedAt: now,
          isPinned: _isPinned,
          isArchived: widget.item?.isArchived ?? false,
          colorIndex: widget.item?.colorIndex ?? 0,
          categoryId: _selectedCategory?.id,
        );

        if (isEditing) {
          success = await provider.updateProject(project);
          LogService.debug('✅ AddEditItemBottomSheet: Project updated');
        } else {
          success = await provider.addProject(project);
          LogService.debug('✅ AddEditItemBottomSheet: New project created');
        }
      } else {
        // Note
        if (isEditing) {
          final note = widget.item as NoteModel;
          final updatedNote = note.copyWith(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            categoryId: _selectedCategory?.id,
            isPinned: _isPinned,
            updatedAt: now,
          );
          success = await provider.updateNote(updatedNote);
          LogService.debug('✅ AddEditItemBottomSheet: Note updated');
        } else {
          success = await provider.addNote(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            categoryId: _selectedCategory?.id,
          );
          LogService.debug('✅ AddEditItemBottomSheet: New note created');
        }
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        if (widget.type == ItemType.note) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing ? LocaleKeys.NoteUpdated.tr() : LocaleKeys.NoteAdded.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      LogService.error('❌ AddEditItemBottomSheet: Error saving item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${'Error'.tr()}: $e"),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
