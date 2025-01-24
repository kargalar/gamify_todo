import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/Enums/status_enum.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Provider/trait_provider.dart';
import 'package:gamify_todo/Enum/trait_type_enum.dart';
import 'package:gamify_todo/Model/trait_model.dart';
import 'package:get/route_manager.dart';

class CreateTraitDialog extends StatefulWidget {
  const CreateTraitDialog({
    super.key,
    required this.isSkill,
  });

  final bool isSkill;

  @override
  State<CreateTraitDialog> createState() => _CreateTraitDialogState();
}

class _CreateTraitDialogState extends State<CreateTraitDialog> {
  TextEditingController traitTitleController = TextEditingController();
  String traitIcon = "🎯";
  Color selectedColor = AppColors.main;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Title
      title: Center(
        child: Text(
          widget.isSkill ? LocaleKeys.CreateSkill.tr() : LocaleKeys.CreateAttribute.tr(),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: AppColors.borderRadiusAll,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: TextField(
                autofocus: true,
                controller: traitTitleController,
                decoration: InputDecoration(
                  hintText: LocaleKeys.Name.tr(),
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              InkWell(
                borderRadius: AppColors.borderRadiusAll,
                onTap: () async {
                  traitIcon = await Helper().showEmojiPicker(context);
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground2,
                      borderRadius: AppColors.borderRadiusAll,
                    ),
                    child: Center(
                      child: Text(
                        traitIcon,
                        style: const TextStyle(
                          fontSize: 25,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Color
              InkWell(
                borderRadius: AppColors.borderRadiusAll,
                onTap: () async {
                  selectedColor = await Helper().selectColor();
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: AppColors.borderRadiusAll,
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
      actions: [
        // Camcel
        InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () {
            Get.back();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.transparent,
              borderRadius: AppColors.borderRadiusAll,
            ),
            child: Text(LocaleKeys.Cancel.tr()),
          ),
        ),
        // Create
        InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () async {
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

            Get.back();
          },
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.main,
                borderRadius: AppColors.borderRadiusAll,
              ),
              child: Text(LocaleKeys.Create.tr()),
            ),
          ),
        ),
      ],
    );
  }
}
