import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Provider/projects_provider.dart';

/// Yeni proje kategorisi oluşturma dialog'u
class AddProjectCategoryDialog extends StatefulWidget {
  final List<CategoryModel>? existingCategories;
  final Function(CategoryModel)? onDeleteCategory;
  final CategoryModel? editingCategory;

  const AddProjectCategoryDialog({
    super.key,
    this.existingCategories,
    this.onDeleteCategory,
    this.editingCategory,
  });

  @override
  State<AddProjectCategoryDialog> createState() => _AddProjectCategoryDialogState();
}

class _AddProjectCategoryDialogState extends State<AddProjectCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Seçilebilir renkler
  final List<Color> _availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.lime,
    Colors.deepOrange,
  ];

  // Seçilebilir iconlar
  final List<IconData> _availableIcons = [
    Icons.work,
    Icons.person,
    Icons.school,
    Icons.sports_esports,
    Icons.home,
    Icons.fitness_center,
    Icons.shopping_bag,
    Icons.flight,
    Icons.music_note,
    Icons.camera_alt,
    Icons.code,
    Icons.palette,
    Icons.star,
    Icons.favorite,
    Icons.lightbulb,
    Icons.rocket_launch,
  ];

  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Icons.work;

  @override
  void initState() {
    super.initState();
    if (widget.editingCategory != null) {
      _nameController.text = widget.editingCategory!.name;
      _selectedColor = widget.editingCategory!.color;
      _selectedIcon = IconData(widget.editingCategory!.iconCodePoint ?? 0xf03d, fontFamily: 'MaterialIcons');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ AddProjectCategoryDialog: Validation failed');
      return;
    }

    final provider = Provider.of<ProjectsProvider>(context, listen: false);

    final newCategory = CategoryModel(
      id: 'proj_cat_${DateTime.now().millisecondsSinceEpoch}',
      title: _nameController.text.trim(),
      color: _selectedColor,
      iconCodePoint: _selectedIcon.codePoint,
      createdAt: DateTime.now(),
    );

    final success = await provider.addCategory(newCategory);

    if (success && mounted) {
      debugPrint('✅ AddProjectCategoryDialog: Category created - ${newCategory.name}');
      Navigator.of(context).pop(newCategory);
    } else {
      debugPrint('❌ AddProjectCategoryDialog: Failed to create category');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.green,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.editingCategory != null ? 'Kategori Düzenle' : LocaleKeys.NewCategory.tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Kategori Adı
                Text(
                  LocaleKeys.CategoryName.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: LocaleKeys.EnterCategoryName.tr(),
                    hintStyle: const TextStyle(color: AppColors.grey),
                    filled: true,
                    fillColor: AppColors.panelBackground2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return LocaleKeys.CategoryNameEmpty.tr();
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 24),

                // Renk Seçimi
                Text(
                  LocaleKeys.Color.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableColors.map((color) {
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.white : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: AppColors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // İkon Seçimi
                Text(
                  LocaleKeys.Icon.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableIcons.map((icon) {
                    final isSelected = icon == _selectedIcon;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIcon = icon;
                        });
                      },
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: isSelected ? _selectedColor.withValues(alpha: 0.2) : AppColors.panelBackground2,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(
                                  color: _selectedColor,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Icon(
                          icon,
                          size: 24,
                          color: isSelected ? _selectedColor : AppColors.text,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        LocaleKeys.Cancel.tr(),
                        style: TextStyle(color: AppColors.text),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(widget.editingCategory != null ? LocaleKeys.Save.tr() : LocaleKeys.Create.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
