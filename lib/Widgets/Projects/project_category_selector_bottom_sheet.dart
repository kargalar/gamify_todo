import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/create_category_bottom_sheet.dart';

/// Proje kategorisi seçimi için bottom sheet
class ProjectCategorySelectorBottomSheet extends StatelessWidget {
  final CategoryModel? currentCategory;
  final List<CategoryModel> categories;

  const ProjectCategorySelectorBottomSheet({
    super.key,
    required this.currentCategory,
    required this.categories,
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
                  LocaleKeys.SelectCategory.tr(),
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
                  isSelected: currentCategory == null,
                ),

                // Kategori listesi
                ...categories.map((category) {
                  return _buildCategoryTile(
                    context: context,
                    category: category,
                    isSelected: currentCategory?.id == category.id,
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
    final icon = category != null ? IconData(category.iconCodePoint ?? 0xf03d, fontFamily: 'MaterialIcons') : Icons.category_outlined;
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

              // Eğer kategori güncellendiyse veya silindiyse, bottom sheet'i kapat
              if (!context.mounted) return;

              if (result != null) {
                // Kategori güncellendi veya silindi, bottom sheet'i kapat
                Navigator.pop(context);
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
    return InkWell(
      onTap: () async {
        final newCategory = await showModalBottomSheet<CategoryModel>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.transparent,
          builder: (context) => const CreateCategoryBottomSheet(
            initialCategoryType: CategoryType.project,
          ),
        );

        if (newCategory != null && context.mounted) {
          Navigator.pop(context, newCategory);
          debugPrint('✅ ProjectCategorySelectorBottomSheet: New category created: ${newCategory.name}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.panelBackground2,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: AppColors.green,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Yeni Kategori Ekle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
