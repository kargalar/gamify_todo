import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/note_category_model.dart';

/// Kategori yönetimi dialog'u - ekleme ve silme
class AddCategoryDialog extends StatefulWidget {
  final List<NoteCategoryModel> existingCategories;
  final Function(NoteCategoryModel) onDeleteCategory;
  final NoteCategoryModel? editingCategory;

  const AddCategoryDialog({
    super.key,
    required this.existingCategories,
    required this.onDeleteCategory,
    this.editingCategory,
  });

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
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
    Icons.note,
    Icons.lightbulb,
    Icons.format_quote,
    Icons.work,
    Icons.school,
    Icons.home,
    Icons.favorite,
    Icons.star,
    Icons.bookmark,
    Icons.calendar_today,
    Icons.shopping_bag,
    Icons.fitness_center,
    Icons.restaurant,
    Icons.flight,
    Icons.music_note,
    Icons.camera_alt,
    Icons.code,
    Icons.palette,
  ];

  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Icons.note;

  @override
  void initState() {
    super.initState();
    if (widget.editingCategory != null) {
      _nameController.text = widget.editingCategory!.name;
      _selectedColor = Color(widget.editingCategory!.colorValue);
      _selectedIcon = IconData(widget.editingCategory!.iconCodePoint, fontFamily: 'MaterialIcons');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      debugPrint('✅ AddCategoryDialog: Category created - Name: ${_nameController.text}, Color: ${_selectedColor.toARGB32()}, Icon: ${_selectedIcon.codePoint}');

      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'colorValue': _selectedColor.toARGB32(),
        'iconCodePoint': _selectedIcon.codePoint,
      });
    } else {
      debugPrint('❌ AddCategoryDialog: Validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Dialog(
        backgroundColor: AppColors.panelBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık ve TabBar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        color: AppColors.main,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.editingCategory != null ? 'Kategori Düzenle' : 'Kategoriler',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    labelColor: AppColors.main,
                    unselectedLabelColor: AppColors.grey,
                    indicatorColor: AppColors.main,
                    tabs: const [
                      Tab(text: 'Yeni Ekle'),
                      Tab(text: 'Kategorilerim'),
                    ],
                  ),
                ],
              ),
            ),

            // TabBarView
            SizedBox(
              height: 500,
              child: TabBarView(
                children: [
                  // Yeni kategori ekleme tab'ı
                  _buildAddCategoryTab(),
                  // Mevcut kategorileri listeleme tab'ı
                  _buildCategoryListTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori Adı
              Text(
                'Kategori Adı',
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
                  hintText: 'Kategori adını girin',
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
                    return 'Kategori adı boş olamaz';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 24),

              // Renk Seçimi
              Text(
                'Renk',
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
                      debugPrint('🎨 AddCategoryDialog: Color selected - ${color.toARGB32()}');
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
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
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

              // Icon Seçimi
              Text(
                'İkon',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableIcons.map((icon) {
                      final isSelected = icon == _selectedIcon;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIcon = icon;
                          });
                          debugPrint('📌 AddCategoryDialog: Icon selected - ${icon.codePoint}');
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? _selectedColor.withValues(alpha: 0.2) : AppColors.panelBackground2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? _selectedColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? _selectedColor : AppColors.grey,
                            size: 24,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Butonlar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      debugPrint('❌ AddCategoryDialog: Cancelled');
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.grey,
                    ),
                    child: Text(LocaleKeys.Cancel.tr()),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.main,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
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
    );
  }

  Widget _buildCategoryListTab() {
    if (widget.existingCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category_outlined,
                size: 64,
                color: AppColors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Henüz kategori eklenmemiş',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.existingCategories.length,
      itemBuilder: (context, index) {
        final category = widget.existingCategories[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Color(category.colorValue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(category.colorValue).withValues(alpha: 0.3),
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(category.colorValue).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: Color(category.colorValue),
                size: 24,
              ),
            ),
            title: Text(
              category.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.red),
              onPressed: () {
                widget.onDeleteCategory(category);
              },
            ),
          ),
        );
      },
    );
  }
}
