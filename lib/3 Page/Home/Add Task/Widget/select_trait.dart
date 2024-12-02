import 'package:flutter/material.dart';
import 'package:gamify_todo/2%20General/accessible.dart';
import 'package:gamify_todo/2%20General/app_colors.dart';
import 'package:gamify_todo/3%20Page/Home/Add%20Task/Widget/create_trait_dialog.dart';
import 'package:gamify_todo/3%20Page/Home/Add%20Task/Widget/trait_item.dart';
import 'package:gamify_todo/7%20Enum/trait_type_enum.dart';
import 'package:get/route_manager.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Title
              Text(
                " ${widget.isSkill ? "Skill" : "Attirbute"}",
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
                  ? traitList
                      .where((trait) => trait.type == TraitTypeEnum.SKILL)
                      .map((skill) => TraitItem(
                            trait: skill,
                          ))
                      .toList()
                  : traitList
                      .where((trait) => trait.type == TraitTypeEnum.ATTIRBUTE)
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
