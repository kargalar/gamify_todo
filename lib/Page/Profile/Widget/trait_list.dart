import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/create_trait_bottom_sheet.dart';
import 'package:next_level/Page/Trait Detail Page/trait_detail_page.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Enum/trait_type_enum.dart';
// Removed direct task imports; totals are now computed via ProfileViewModel task logs
import 'package:next_level/Core/extensions.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Provider/profile_view_model.dart';

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
    debugPrint("TraitList: Building trait list successfully - colors updated from AppColors");
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
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.transparent,
                  barrierColor: AppColors.transparent,
                  builder: (context) => CreateTraitBottomSheet(isSkill: widget.isSkill),
                ).then((value) => setState(() {}));
              },
              child: const Icon(
                Icons.add,
                size: 30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Builder(builder: (context) {
          final traitProvider = Provider.of<TraitProvider>(context);
          final skills = traitProvider.traitList.where((t) => t.type == TraitTypeEnum.SKILL && !t.isArchived).toList();
          final attributes = traitProvider.traitList.where((t) => t.type == TraitTypeEnum.ATTRIBUTE && !t.isArchived).toList();

          if (widget.isSkill) {
            // Use combined totals to include TIMER, COUNTER, and CHECKBOX (reactive)
            final viewModel = context.watch<ProfileViewModel>();
            final traitTotals = viewModel.getTraitTotalsCombined(isSkill: true);
            // Single preferred design: gradient-tinted 2-column grid
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: skills.map((skill) {
                final Duration totalDuration = traitTotals[skill.id] ?? Duration.zero;

                final decoration = BoxDecoration(
                  color: skill.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: skill.color.withValues(alpha: 0.4), width: 2),
                  boxShadow: [BoxShadow(color: skill.color.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
                );

                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(skill.icon, style: TextStyle(fontSize: 26, color: skill.color)),
                    const Spacer(),
                    Text(skill.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(totalDuration.textShort2hour(), style: const TextStyle(color: AppColors.grey)),
                  ],
                );

                return GestureDetector(
                  onTap: () async {
                    await NavigatorService().goTo(TraitDetailPage(traitModel: skill));
                  },
                  child: Container(padding: const EdgeInsets.all(12), decoration: decoration, child: content),
                );
              }).toList(),
            );
          }

          // Attributes: show compact 2-column grid
          final viewModel = context.watch<ProfileViewModel>();
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.8,
            children: attributes.map((attribute) {
              final traitTotals = viewModel.getTraitTotalsCombined(isSkill: false);
              final Duration totalDuration = traitTotals[attribute.id] ?? Duration.zero;

              // Calculate progress (mock data for now - you can implement real progress logic)

              return GestureDetector(
                onTap: () async {
                  await NavigatorService().goTo(TraitDetailPage(traitModel: attribute));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: attribute.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: attribute.color.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [BoxShadow(color: attribute.color.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: attribute.color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: attribute.color.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            attribute.icon,
                            style: const TextStyle(
                              fontSize: 20,
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attribute.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            totalDuration.textShort2hour(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        })
      ],
    );
  }
}
