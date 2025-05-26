import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Page/Home/Widget/create_category_bottom_sheet.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';

class InboxCategoriesSection extends StatelessWidget {
  final CategoryModel? selectedCategory;
  final Function(CategoryModel?) onCategorySelected;

  const InboxCategoriesSection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryContent(context),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.getActiveCategories();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All tasks option
          _buildCategoryTag(
            context,
            null,
            isSelected: selectedCategory == null,
          ),
          const SizedBox(width: 8),

          // Category tags
          ...categories.map((category) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildCategoryTag(
                  context,
                  category,
                  isSelected: selectedCategory?.id == category.id,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(BuildContext context, CategoryModel? category, {required bool isSelected}) {
    final color = category?.color ?? AppColors.main;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onCategorySelected(category),
        onLongPress: category != null
            ? () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.transparent,
                  builder: (context) => CreateCategoryBottomSheet(categoryModel: category),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.panelBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color indicator
              if (category != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Category name
              Text(
                category?.title ?? LocaleKeys.AllTasks.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppColors.text.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
