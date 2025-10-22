import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/create_category_bottom_sheet.dart';

/// Kategori seçimi için bottom sheet
class CategorySelectorBottomSheet extends StatelessWidget {
  final CategoryModel? selectedCategory;
  final List<CategoryModel> categories;
  final Future<void> Function(CategoryModel)? onCategoryAdded;
  final Future<void> Function(CategoryModel)? onCategoryDeleted;

  const CategorySelectorBottomSheet({
    super.key,
    required this.selectedCategory,
    required this.categories,
    this.onCategoryAdded,
    this.onCategoryDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Kategori Seç',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.text),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Kategori listesi
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Kategorisiz seçeneği
                _buildCategoryTile(
                  context: context,
                  category: null,
                  isSelected: selectedCategory == null,
                ),

                // Kategori listesi
                ...categories.map((category) {
                  return _buildCategoryTile(
                    context: context,
                    category: category,
                    isSelected: selectedCategory?.id == category.id,
                  );
                }),

                // Yeni Kategori Ekle butonu
                _buildAddCategoryButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile({
    required BuildContext context,
    required CategoryModel? category,
    required bool isSelected,
  }) {
    final color = category != null ? Color(category.colorValue) : AppColors.grey;
    final icon = category != null && category.iconCodePoint != null ? IconData(category.iconCodePoint!, fontFamily: 'MaterialIcons') : Icons.category_outlined;
    final name = category?.name ?? 'Kategorisiz';

    return InkWell(
      onTap: () {
        Navigator.pop(context, category);
      },
      onLongPress: category != null
          ? () async {
              // Kategori düzenleme bottom sheet'ini aç
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.transparent,
                builder: (context) => CreateCategoryBottomSheet(categoryModel: category),
              );

              // Eğer kategori güncellendiyse veya silindiyse, bottom sheet'i kapat ve callback'i çağır
              if (!context.mounted) return;

              if (result == true) {
                if (onCategoryDeleted != null) {
                  await onCategoryDeleted!(category);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } else if (result == false) {
                // Kategori güncellendi, callback'i çağır
                if (onCategoryAdded != null) await onCategoryAdded!(category);
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
        child: Row(
          children: [
            // İkon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            // İsim
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : AppColors.text,
                ),
              ),
            ),
            // Seçili işareti
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: () => _showAddCategoryDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.main,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppColors.main,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Yeni Kategori Oluştur',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.main,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final newCategory = await showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => const CreateCategoryBottomSheet(
        initialCategoryType: CategoryType.note,
      ),
    );

    if (newCategory != null) {
      debugPrint('✅ CategorySelectorBottomSheet: New category created: ${newCategory.name}');

      // Kategori zaten CreateCategoryBottomSheet içinde CategoryProvider'a eklendi
      // Sadece NotesProvider'ın kategoriler listesini güncellememiz gerekiyor
      // onCategoryAdded callback'i NotesProvider.loadData() çağırarak kategorileri yeniden yükleyecek
      if (onCategoryAdded != null) await onCategoryAdded!(newCategory);

      if (context.mounted) {
        // Yeni kategoriyi seçili olarak dön
        Navigator.pop(context, newCategory);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CategoryCreated'.tr(args: [newCategory.name])),
            backgroundColor: Color(newCategory.colorValue),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
