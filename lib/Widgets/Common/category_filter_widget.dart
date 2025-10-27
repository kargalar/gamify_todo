import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/General/category_icons.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Page/Home/Widget/create_category_bottom_sheet.dart';
import 'package:next_level/Service/logging_service.dart';

/// Common category filter widget used across Tasks, Notes, and Projects pages
class CategoryFilterWidget extends StatelessWidget {
  final List<dynamic> categories;
  final dynamic selectedCategoryId; // Can be int? or String?
  final Function(dynamic) onCategorySelected;
  final Map<dynamic, int>? itemCounts; // Optional count display
  final Function(BuildContext, dynamic)? onCategoryLongPress; // Optional long press handler
  final VoidCallback? onCategoryAdded; // Optional callback when a category is added
  final CategoryType? categoryType; // Category type for auto-detection when adding
  final bool showEmptyCategories; // Whether to show categories with 0 items

  const CategoryFilterWidget({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.itemCounts,
    this.onCategoryLongPress,
    this.onCategoryAdded,
    this.categoryType,
    this.showEmptyCategories = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // "All" option
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildAllChip(context),
          ),

          // Categories
          ...categories.map((category) {
            final count = itemCounts?[category.id] ?? 0;
            // Only show categories that have items (unless selected or showEmptyCategories is true)
            if (!showEmptyCategories && count == 0 && selectedCategoryId != category.id) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCategoryChip(context, category, count),
            );
          }),

          // Add category button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildAddChip(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAllChip(BuildContext context) {
    final isSelected = selectedCategoryId == null;
    final totalCount = itemCounts?.values.fold(0, (sum, count) => sum + count) ?? 0;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.all_inclusive,
            size: 16,
            color: isSelected ? Colors.black : AppColors.text,
          ),
          const SizedBox(width: 6),
          Text(
            LocaleKeys.All.tr(),
            style: TextStyle(
              color: isSelected ? Colors.black : AppColors.text,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (itemCounts != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black.withValues(alpha: 0.3) : AppColors.panelBackground2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$totalCount',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.text,
                ),
              ),
            ),
          ],
        ],
      ),
      selectedColor: AppColors.text,
      backgroundColor: AppColors.panelBackground,
      checkmarkColor: Colors.black,
      onSelected: (_) => onCategorySelected(null),
    );
  }

  Widget _buildAddChip(BuildContext context) {
    return FilterChip(
      selected: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add,
            size: 16,
            color: AppColors.main,
          ),
          const SizedBox(width: 4),
          Text(
            LocaleKeys.Add.tr(),
            style: TextStyle(
              color: AppColors.main,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.panelBackground,
      onSelected: (_) async {
        LogService.debug('➕ CategoryFilterWidget: Add category button pressed, type: $categoryType');
        // Otomatik olarak doğru tip ile kategori oluştur
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.transparent,
          builder: (context) => CreateCategoryBottomSheet(
            initialCategoryType: categoryType,
          ),
        );

        LogService.debug('✅ CategoryFilterWidget: Bottom sheet closed, result: $result');

        // Kategori eklendikten sonra callback'i çağır
        if (context.mounted) {
          onCategoryAdded?.call();
        }
      },
    );
  }

  Widget _buildCategoryChip(BuildContext context, dynamic category, int count) {
    final isSelected = selectedCategoryId == category.id;
    final categoryColor = category.colorValue != null ? Color(category.colorValue) : AppColors.main;

    final chip = FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (category.iconCodePoint != null) ...[
            Icon(
              CategoryIcons.getIconByCodePoint(category.iconCodePoint) ?? Icons.category,
              size: 16,
              color: isSelected ? Colors.white : categoryColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            category.name ?? (category.title ?? ''),
            style: TextStyle(
              color: isSelected ? Colors.white : categoryColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (itemCounts != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.panelBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.white.withValues(alpha: 0.3) : categoryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : categoryColor,
                ),
              ),
            ),
          ],
        ],
      ),
      selectedColor: categoryColor,
      backgroundColor: AppColors.panelBackground,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: categoryColor,
        width: isSelected ? 2 : 1.5,
      ),
      onSelected: (_) {
        LogService.debug('🏷️ CategoryFilterWidget: Category selected - ${category.name ?? category.title}');
        onCategorySelected(category.id);
      },
    );

    // Add long press handler if provided
    if (onCategoryLongPress != null) {
      return GestureDetector(
        onLongPress: () => onCategoryLongPress!(context, category),
        child: chip,
      );
    }

    return chip;
  }
}
