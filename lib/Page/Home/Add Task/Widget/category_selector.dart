import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Model/category_model.dart';
import 'package:gamify_todo/Page/Home/Widget/create_category_bottom_sheet.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Provider/category_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Widgets/clickable_tooltip.dart';
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClickableTooltip(
                title: LocaleKeys.Category.tr(),
                bulletPoints: const ["Tap a category to select/deselect it", "Long press to edit a category", "Use + button to create a new category", "Categories help organize your tasks"],
                child: Container(
                  color: AppColors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        Icons.label_rounded,
                        color: AppColors.main,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        LocaleKeys.Category.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildAddCategoryButton(context),
            ],
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Categories content
          activeCategories.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          color: AppColors.text.withValues(alpha: 0.3),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LocaleKeys.NoCategory.tr(),
                          style: TextStyle(
                            color: AppColors.text.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground.withValues(alpha: 0.5),
                  ),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
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
                                // Unfocus any text fields before showing bottom sheet
                                addTaskProvider.unfocusAll();
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => CreateCategoryBottomSheet(categoryModel: category),
                                );
                              },
                            )),
                      ],
                    ),
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
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.7) : AppColors.text.withValues(alpha: 0.1),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color indicator with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 4),

                // Category name with animation
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : AppColors.text.withValues(alpha: 0.7),
                    letterSpacing: 0.1,
                  ),
                ),

                // Selected indicator
                if (isSelected) ...[
                  const SizedBox(width: 3),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 10,
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          // Unfocus any text fields before showing bottom sheet
          context.read<AddTaskProvider>().unfocusAll();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateCategoryBottomSheet(),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.main.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColors.main,
              ),
              const SizedBox(width: 4),
              Text(
                LocaleKeys.Add.tr(),
                style: TextStyle(
                  color: AppColors.main,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
