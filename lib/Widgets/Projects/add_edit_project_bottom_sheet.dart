import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Model/project_model.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Provider/projects_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Widgets/Projects/project_category_selector_bottom_sheet.dart';

/// Proje ekleme ve düzenleme bottom sheet'i
class AddEditProjectBottomSheet extends StatefulWidget {
  final ProjectModel? project;

  const AddEditProjectBottomSheet({super.key, this.project});

  @override
  State<AddEditProjectBottomSheet> createState() => _AddEditProjectBottomSheetState();
}

class _AddEditProjectBottomSheetState extends State<AddEditProjectBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  CategoryModel? _selectedCategory;
  late bool _isPinned;
  bool _isSaving = false;

  bool get isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _titleController = TextEditingController(text: widget.project?.title ?? '');
    _descriptionController = TextEditingController(text: widget.project?.description ?? '');

    // Initialize state
    _isPinned = widget.project?.isPinned ?? false;

    // Kategoriyi yükle
    if (widget.project?.categoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<ProjectsProvider>(context, listen: false);
        _selectedCategory = provider.getCategoryById(widget.project!.categoryId);
        if (mounted) setState(() {});
      });
    }

    debugPrint('🔧 AddEditProjectBottomSheet: Initialized ${isEditing ? "edit" : "add"} mode');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
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
                        isEditing ? LocaleKeys.EditProject.tr() : LocaleKeys.NewProject.tr(),
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
                          onPressed: () {
                            setState(() {
                              _isPinned = !_isPinned;
                            });
                          },
                          tooltip: _isPinned ? LocaleKeys.UnpinTask.tr() : LocaleKeys.Pin.tr(),
                        ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.text),
                        onPressed: () => Navigator.pop(context),
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
                        // Başlık ve Açıklama (tek container'da)
                        _buildProjectFields(),
                        const SizedBox(height: 20),

                        // Kategori seçimi (kompakt buton)
                        _buildCategorySelectorButton(),
                        const SizedBox(height: 24),

                        // Kaydet butonu
                        _buildSaveButton(),
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
    );
  }

  /// Başlık ve açıklama alanları (tek container'da)
  Widget _buildProjectFields() {
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
              hintText: LocaleKeys.ProjectTitle.tr(),
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
          // Açıklama (opsiyonel)
          TextFormField(
            controller: _descriptionController,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              hintText: LocaleKeys.ProjectDescriptionHint.tr(),
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
    return Consumer<ProjectsProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori',
              style: TextStyle(
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
                          color: Color(_selectedCategory!.colorValue).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          IconData(_selectedCategory!.iconCodePoint ?? 0xf03d, fontFamily: 'MaterialIcons'),
                          size: 18,
                          color: Color(_selectedCategory!.colorValue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedCategory!.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(_selectedCategory!.colorValue),
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.category_outlined, size: 20, color: AppColors.grey),
                      const SizedBox(width: 12),
                      const Text(
                        'Kategorisiz',
                        style: TextStyle(
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
  Future<void> _showCategorySelector(BuildContext context, ProjectsProvider provider) async {
    final selected = await showModalBottomSheet<CategoryModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProjectCategorySelectorBottomSheet(
        currentCategory: _selectedCategory,
        categories: provider.categories,
      ),
    );

    // Allow both category selection and null (Kategorisiz) selection
    if (mounted) {
      setState(() {
        _selectedCategory = selected;
      });
      debugPrint('✅ AddEditProjectBottomSheet: Category selected: ${selected?.name ?? "Kategorisiz"}');
    }
  }

  /// Kaydet butonu
  Widget _buildSaveButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
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
                isEditing ? 'Güncelle' : 'Oluştur',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Kaydet işlemi
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = Provider.of<ProjectsProvider>(context, listen: false);
      final now = DateTime.now();

      final project = ProjectModel(
        id: widget.project?.id ?? 'proj_${now.millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: widget.project?.createdAt ?? now,
        updatedAt: now,
        isPinned: _isPinned,
        isArchived: widget.project?.isArchived ?? false,
        colorIndex: widget.project?.colorIndex ?? 0,
        categoryId: _selectedCategory?.id,
      );

      bool success;
      if (isEditing) {
        success = await provider.updateProject(project);
        debugPrint('✅ AddEditProjectBottomSheet: Project updated');
      } else {
        success = await provider.addProject(project);
        debugPrint('✅ AddEditProjectBottomSheet: New project created');
      }

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ AddEditProjectBottomSheet: Error saving project: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
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
