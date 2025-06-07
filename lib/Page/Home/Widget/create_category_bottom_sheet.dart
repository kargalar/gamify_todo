import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';

class CreateCategoryBottomSheet extends StatefulWidget {
  final CategoryModel? categoryModel;

  const CreateCategoryBottomSheet({
    super.key,
    this.categoryModel,
  });

  @override
  State<CreateCategoryBottomSheet> createState() => _CreateCategoryBottomSheetState();
}

class _CreateCategoryBottomSheetState extends State<CreateCategoryBottomSheet> {
  final TextEditingController categoryTitleController = TextEditingController();
  Color selectedColor = AppColors.main;

  @override
  void initState() {
    super.initState();
    if (widget.categoryModel != null) {
      categoryTitleController.text = widget.categoryModel!.title;
      selectedColor = widget.categoryModel!.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: const Border(
          top: BorderSide(color: AppColors.dirtyWhite),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.text.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.categoryModel == null ? LocaleKeys.CreateCategory.tr() : LocaleKeys.EditCategory.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category Name Input
            TextField(
              controller: categoryTitleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: LocaleKeys.CategoryName.tr(),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: selectedColor),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Color Picker Label
            Text(
              LocaleKeys.SelectColor.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Color Picker
            _buildColorPicker(),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Delete Button (only for editing)
                if (widget.categoryModel != null)
                  TextButton.icon(
                    onPressed: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(LocaleKeys.Delete.tr()),
                          content: Text(LocaleKeys.DeleteCategoryConfirmation.tr()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(LocaleKeys.Cancel.tr()),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close dialog
                                context.read<CategoryProvider>().deleteCategory(widget.categoryModel!);
                                Navigator.pop(context); // Close bottom sheet
                              },
                              child: Text(
                                LocaleKeys.Delete.tr(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(
                      LocaleKeys.Delete.tr(),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const Spacer(),
                // Cancel Button
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(LocaleKeys.Cancel.tr()),
                ),
                const SizedBox(width: 12),
                // Save Button
                ElevatedButton(
                  onPressed: _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(LocaleKeys.Save.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final List<Color> colors = [
      AppColors.main,
      AppColors.red,
      AppColors.orange,
      AppColors.orange2,
      AppColors.yellow,
      AppColors.green,
      AppColors.blue,
      AppColors.purple,
      AppColors.deepPurple,
      AppColors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: colors.map((color) {
          final isSelected = selectedColor == color;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedColor = color;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 50 : 40,
                height: isSelected ? 50 : 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _saveCategory() {
    if (categoryTitleController.text.trim().isEmpty) {
      Helper().getMessage(
        message: LocaleKeys.CategoryNameEmpty.tr(),
        status: StatusEnum.WARNING,
      );
      return;
    }

    final categoryProvider = context.read<CategoryProvider>();

    if (widget.categoryModel == null) {
      // Create new category
      final newCategory = CategoryModel(
        title: categoryTitleController.text.trim(),
        color: selectedColor,
      );
      categoryProvider.addCategory(newCategory);

      // Auto-select the newly created category
      final addTaskProvider = Provider.of<AddTaskProvider>(context, listen: false);
      addTaskProvider.updateCategory(newCategory.id);
    } else {
      // Update existing category
      widget.categoryModel!.title = categoryTitleController.text.trim();
      widget.categoryModel!.color = selectedColor;
      categoryProvider.updateCategory(widget.categoryModel!);
    }

    Navigator.pop(context);
  }
}
