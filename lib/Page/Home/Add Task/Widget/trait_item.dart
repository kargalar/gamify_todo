import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Trait%20Detail%20Page/trait_detail_page.dart';
import 'package:gamify_todo/Service/navigator_service.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Model/trait_model.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:provider/provider.dart';

class TraitItem extends StatefulWidget {
  const TraitItem({
    super.key,
    required this.trait,
    this.isStatisticsPage = false,
  });

  final TraitModel trait;
  final bool isStatisticsPage;

  @override
  State<TraitItem> createState() => _TraitItemState();
}

class _TraitItemState extends State<TraitItem> {
  late final addTaskProvider = context.read<AddTaskProvider>();

  late bool isSelected;

  @override
  void initState() {
    super.initState();
    if (widget.isStatisticsPage) {
      isSelected = true;
    } else {
      isSelected = addTaskProvider.selectedTraits.contains(widget.trait);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: SizedBox(
        width: 50,
        height: 50,
        child: InkWell(
          borderRadius: AppColors.borderRadiusAll,
          highlightColor: widget.trait.color,
          splashColor: isSelected ? null : widget.trait.color,
          onTap: () async {
            if (widget.isStatisticsPage) {
              await NavigatorService().goTo(
                TraitDetailPage(traitModel: widget.trait),
              );
            } else {
              if (isSelected) {
                addTaskProvider.selectedTraits.remove(widget.trait);
              } else {
                addTaskProvider.selectedTraits.add(widget.trait);
              }

              setState(() {
                isSelected = !isSelected;
              });
            }
          },
          onLongPress: () async {
            await NavigatorService().goTo(
              TraitDetailPage(
                traitModel: widget.trait,
              ),
              transition: Transition.rightToLeft,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? widget.trait.color : AppColors.panelBackground2,
              borderRadius: AppColors.borderRadiusAll,
            ),
            child: Center(
              child: Text(
                widget.trait.icon,
                style: const TextStyle(
                  fontSize: 25,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
