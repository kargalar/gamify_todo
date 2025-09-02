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
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.transparent,
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
                  gradient: LinearGradient(colors: [skill.color.withValues(alpha: 0.5), Theme.of(context).cardColor]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 3))],
                );

                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(skill.icon, style: TextStyle(fontSize: 26, color: skill.color)),
                    const Spacer(),
                    Text(skill.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(totalDuration.textShort2hour(), style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
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
            childAspectRatio: 3.8,
            children: attributes.map((attribute) {
              final traitTotals = viewModel.getTraitTotalsCombined(isSkill: false);
              final Duration totalDuration = traitTotals[attribute.id] ?? Duration.zero;

              return GestureDetector(
                onTap: () async {
                  await NavigatorService().goTo(TraitDetailPage(traitModel: attribute));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: attribute.color, borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text(attribute.icon, style: const TextStyle(fontSize: 18))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(attribute.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text(totalDuration.textShort2hour(), style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                          ],
                        ),
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
