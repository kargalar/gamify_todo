import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Enum/trait_type_enum.dart';
import 'package:next_level/Model/trait_model.dart';

class CreateTraitBottomSheet extends StatefulWidget {
  const CreateTraitBottomSheet({
    super.key,
    required this.isSkill,
  });

  final bool isSkill;

  @override
  State<CreateTraitBottomSheet> createState() => _CreateTraitBottomSheetState();
}

class _CreateTraitBottomSheetState extends State<CreateTraitBottomSheet> {
  TextEditingController traitTitleController = TextEditingController();
  String traitIcon = "🎯";
  Color selectedColor = AppColors.main;

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
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.text.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with title and icon
            Row(
              children: [
                Icon(
                  widget.isSkill ? Icons.psychology_rounded : Icons.auto_awesome_rounded,
                  color: selectedColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.isSkill ? LocaleKeys.CreateSkill.tr() : LocaleKeys.CreateAttribute.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

            // Name input field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.main.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    autofocus: true,
                    controller: traitTitleController,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: LocaleKeys.Name.tr(),
                      hintStyle: TextStyle(
                        color: AppColors.text.withValues(alpha: 0.4),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Icon and color selection
            Row(
              children: [
                // Icon selection
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        traitIcon = await Helper().showEmojiPicker(context);
                        setState(() {});
                      },
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.panelBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.main.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            traitIcon,
                            style: const TextStyle(
                              fontSize: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Color selection
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        selectedColor = await Helper().selectColor();
                        setState(() {});
                      },
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.main.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: selectedColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      LocaleKeys.Cancel.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Create button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (traitTitleController.text.trim().isEmpty) {
                        traitTitleController.clear();

                        Helper().getMessage(
                          message: LocaleKeys.TraitNameEmpty.tr(),
                          status: StatusEnum.WARNING,
                        );

                        return;
                      }

                      final newTrait = TraitModel(
                        title: traitTitleController.text,
                        icon: traitIcon,
                        color: selectedColor,
                        type: widget.isSkill ? TraitTypeEnum.SKILL : TraitTypeEnum.ATTRIBUTE,
                      );

                      TraitProvider().addTrait(newTrait);

                      // Auto-select the newly created trait
                      final addTaskProvider = Provider.of<AddTaskProvider>(context, listen: false);
                      addTaskProvider.selectedTraits.add(newTrait);

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      LocaleKeys.Create.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
