import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/category_selector.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/location_input.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/select_priority.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';

class CompactTaskOptions extends StatelessWidget {
  const CompactTaskOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    // Get selected category if any
    CategoryModel? selectedCategory;
    if (addTaskProvider.categoryId != null) {
      selectedCategory = categoryProvider.categoryList.firstWhere(
        (category) => category.id == addTaskProvider.categoryId,
        orElse: () => CategoryModel(title: LocaleKeys.NoCategory.tr(), color: AppColors.main),
      );
    } // Get priority color, icon and text
    Color priorityColor;
    IconData priorityIcon;
    String priorityText;

    switch (addTaskProvider.priority) {
      case 1:
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high_rounded;
        priorityText = LocaleKeys.HighPriority.tr();
        break;
      case 2:
        priorityColor = Colors.orange;
        priorityIcon = Icons.drag_handle_rounded;
        priorityText = LocaleKeys.MediumPriority.tr();
        break;
      default:
        priorityColor = Colors.green;
        priorityIcon = Icons.arrow_downward_rounded;
        priorityText = LocaleKeys.LowPriority.tr();
    }

    // Get location info
    final hasLocation = addTaskProvider.locationController.text.isNotEmpty;

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
          // Header
          Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: AppColors.main,
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                "Task Options",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

          // Options grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Location option
              _buildOptionItem(
                context: context,
                icon: Icons.location_on_rounded,
                iconColor: hasLocation ? AppColors.main : AppColors.text.withValues(alpha: 0.5),
                label: LocaleKeys.Location.tr(),
                value: hasLocation ? addTaskProvider.locationController.text : null,
                onTap: () {
                  addTaskProvider.unfocusAll();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    barrierColor: Colors.transparent,
                    builder: (context) => const LocationBottomSheet(),
                  );
                },
              ),

              // Priority option
              _buildOptionItem(
                context: context,
                icon: priorityIcon,
                iconColor: priorityColor,
                label: LocaleKeys.Priority.tr(),
                value: priorityText,
                valueColor: priorityColor,
                onTap: () {
                  addTaskProvider.unfocusAll();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    barrierColor: Colors.transparent,
                    builder: (context) => const PriorityBottomSheet(),
                  );
                },
              ),

              // Category option
              _buildOptionItem(
                context: context,
                icon: Icons.label_rounded,
                iconColor: selectedCategory != null ? selectedCategory.color : AppColors.text.withValues(alpha: 0.5),
                label: LocaleKeys.Category.tr(),
                value: selectedCategory?.title,
                valueColor: selectedCategory?.color,
                onTap: () {
                  addTaskProvider.unfocusAll();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    barrierColor: Colors.transparent,
                    builder: (context) => const CategoryBottomSheet(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    String? value,
    Color? valueColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.42, // Approximately 2 items per row
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.text.withValues(alpha: 0.1),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text.withValues(alpha: 0.7),
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: valueColor ?? AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.text.withValues(alpha: 0.3),
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
