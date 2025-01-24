import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/create_trait_dialog.dart';
import 'package:gamify_todo/Page/Profile/Widget/trait_item_detailed.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Provider/trait_provider.dart';
import 'package:gamify_todo/Enum/trait_type_enum.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';

class TraitList extends StatefulWidget {
  const TraitList({
    super.key,
    required this.isSkill,
  });

  final bool isSkill;

  @override
  State<TraitList> createState() => _TraitListState();
}

class _TraitListState extends State<TraitList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Title
            Text(
              " ${widget.isSkill ? LocaleKeys.Skills.tr() : LocaleKeys.Attributes.tr()}",
              style: const TextStyle(
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
        Column(
          children: widget.isSkill
              ? Provider.of<TraitProvider>(context, listen: true).traitList.where((trait) => trait.type == TraitTypeEnum.SKILL).map((skill) => TraitItemDetailed(trait: skill)).toList()
              : Provider.of<TraitProvider>(context, listen: true).traitList.where((trait) => trait.type == TraitTypeEnum.ATTRIBUTE).map((attirbute) => TraitItemDetailed(trait: attirbute)).toList(),
        )
      ],
    );
  }
}
