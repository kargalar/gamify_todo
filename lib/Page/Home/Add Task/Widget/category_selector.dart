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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.label_rounded,
                    color: AppColors.main,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LocaleKeys.Category.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildAddCategoryButton(context),
            ],
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Categories content
          activeCategories.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          color: AppColors.text.withValues(alpha: 0.3),
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          LocaleKeys.NoCategory.tr(),
                          style: TextStyle(
                            color: AppColors.text.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tap + to add a category",
                          style: TextStyle(
                            color: AppColors.text.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground.withValues(alpha: 0.5),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: [
                      // Category Tags
                      ...activeCategories.map((category) => _buildCategoryTag(
                            context: context,
                            category: category,
                            isSelected: addTaskProvider.categoryId == category.id,
                            onTap: () {
                              // Unfocus any text fields before updating category
                              addTaskProvider.unfocusAll();
                              addTaskProvider.categoryId == category.id ? addTaskProvider.updateCategory(null) : addTaskProvider.updateCategory(category.id);
                            },
                            onLongPress: () {
                              // Unfocus any text fields before showing dialog
                              addTaskProvider.unfocusAll();
                              Get.dialog(CreateCategoryDialog(categoryModel: category));
                            },
                          )),
                    ],
                  ),
                ),

          // Category info
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.text.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Long press on a category to edit it. Tap to select/deselect.",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.7) : AppColors.text.withValues(alpha: 0.1),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color indicator with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),

                // Category name with animation
                Text(
                  "#$label",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : AppColors.text.withValues(alpha: 0.7),
                    letterSpacing: 0.2,
                  ),
                ),

                // Selected indicator
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: color,
                  ),
                ],
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
          // Unfocus any text fields before showing dialog
          context.read<AddTaskProvider>().unfocusAll();
          Get.dialog(const CreateCategoryDialog());
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.main.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 18,
                color: AppColors.main,
              ),
              const SizedBox(width: 4),
              Text(
                "Add",
                style: TextStyle(
                  color: AppColors.main,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
