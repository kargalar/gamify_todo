import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Home/Widget/create_category_dialog.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Provider/category_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();
    final categoryProvider = CategoryProvider();
    final activeCategories = categoryProvider.getActiveCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            LocaleKeys.Category.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // No Category Chip
                _buildCategoryChip(
                  context: context,
                  label: LocaleKeys.NoCategory.tr(),
                  color: Colors.grey.shade300,
                  isSelected: addTaskProvider.categoryId == null,
                  onTap: () => addTaskProvider.updateCategory(null),
                ),

                // Category Chips
                ...activeCategories.map((category) => _buildCategoryChip(
                      context: context,
                      label: category.title,
                      color: category.color,
                      isSelected: addTaskProvider.categoryId == category.id,
                      onTap: () => addTaskProvider.updateCategory(category.id),
                      onLongPress: () => Get.dialog(CreateCategoryDialog(categoryModel: category)),
                    )),

                // Add Category Button
                _buildAddCategoryButton(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != LocaleKeys.NoCategory.tr()) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCategoryButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => Get.dialog(const CreateCategoryDialog()),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.main.withValues(alpha: 0.5),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 16,
                color: AppColors.main,
              ),
              const SizedBox(width: 4),
              Text(
                LocaleKeys.CreateNewCategory.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.main,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
