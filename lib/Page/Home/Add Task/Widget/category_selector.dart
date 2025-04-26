import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/category_model.dart';
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
    final categoryProvider = context.watch<CategoryProvider>();
    final activeCategories = categoryProvider.getActiveCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
              child: Text(
                LocaleKeys.Category.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4.0, bottom: 8.0),
              child: _buildAddCategoryButton(context),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppColors.panelBackground.withValues(alpha: 0.3),
          ),
          padding: const EdgeInsets.all(12),
          child: activeCategories.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      LocaleKeys.NoCategory.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: [
                        // Category Tags
                        ...activeCategories.map((category) => _buildCategoryTag(
                              context: context,
                              category: category,
                              isSelected: addTaskProvider.categoryId == category.id,
                              onTap: () => addTaskProvider.categoryId == category.id ? addTaskProvider.updateCategory(null) : addTaskProvider.updateCategory(category.id),
                              onLongPress: () {
                                Get.dialog(CreateCategoryDialog(categoryModel: category));
                              },
                            )),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryTag({
    required BuildContext context,
    required CategoryModel category,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final String label = category.title;
    final Color color = category.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.panelBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "#$label",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : Colors.grey.shade700,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddCategoryButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          Get.dialog(const CreateCategoryDialog());
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.main.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add,
            size: 16,
            color: AppColors.main,
          ),
        ),
      ),
    );
  }
}
