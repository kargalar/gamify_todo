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
    final traitProvider = TraitProvider();
    final traits = widget.isSkill ? traitProvider.traitList.where((trait) => trait.type == TraitTypeEnum.SKILL).toList() : traitProvider.traitList.where((trait) => trait.type == TraitTypeEnum.ATTRIBUTE).toList();

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
                    widget.isSkill ? Icons.psychology_rounded : Icons.auto_awesome_rounded,
                    color: AppColors.main,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isSkill ? LocaleKeys.Skills.tr() : LocaleKeys.Attributes.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildAddTraitButton(context),
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

          // Traits content
          traits.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        Icon(
                          widget.isSkill ? Icons.psychology_alt_outlined : Icons.auto_awesome_outlined,
                          color: AppColors.text.withValues(alpha: 0.3),
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isSkill ? "No skills yet" : "No attributes yet",
                          style: TextStyle(
                            color: AppColors.text.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Traits description
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        widget.isSkill ? "Select skills that will improve with this task" : "Select attributes that this task requires",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    // Traits grid
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.text.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 1,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: traits.length,
                        itemBuilder: (context, index) {
                          return TraitItem(
                            trait: traits[index],
                          );
                        },
                      ),
                    ),
                  ],
                ),

          // Trait info
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
                    "Long press on a ${widget.isSkill ? 'skill' : 'attribute'} to view details. Tap to select/deselect.",
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

  Widget _buildAddTraitButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
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
