import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/create_trait_dialog.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/trait_item.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Provider/trait_provider.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Enum/trait_type_enum.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';

class SelectTraitList extends StatefulWidget {
  const SelectTraitList({
    super.key,
    required this.isSkill,
  });

  final bool isSkill;

  @override
  State<SelectTraitList> createState() => _SelectTraitListState();
}

class _SelectTraitListState extends State<SelectTraitList> {
  @override
  Widget build(BuildContext context) {
    context.watch<TraitProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Title
              Text(
                " ${widget.isSkill ? LocaleKeys.Skills.tr() : LocaleKeys.Attributes.tr()}",
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Add Button
              InkWell(
                borderRadius: AppColors.borderRadiusAll / 2,
                onTap: () async {
                  // Unfocus any text fields when opening dialog
                  context.read<AddTaskProvider>().unfocusAll();

                  await Get.dialog(
                    CreateTraitDialog(isSkill: widget.isSkill),
                  ).then(
                    (value) {
                      setState(() {});
                    },
                  );
                },
                child: const Icon(
                  Icons.add,
                  size: 30,
                ),
              ),
            ],
          ),
          // List of Traits
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: widget.isSkill
                  ? TraitProvider()
                      .traitList
                      .where((trait) => trait.type == TraitTypeEnum.SKILL)
                      .map((skill) => TraitItem(
                            trait: skill,
                          ))
                      .toList()
                  : TraitProvider()
                      .traitList
                      .where((trait) => trait.type == TraitTypeEnum.ATTRIBUTE)
                      .map((attirbute) => TraitItem(
                            trait: attirbute,
                          ))
                      .toList(),
            ),
          )
        ],
      ),
    );
  }
}
