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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Unfocus any text fields when selecting trait
          if (!widget.isStatisticsPage) {
            addTaskProvider.unfocusAll();
          }

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
          // Unfocus any text fields when long pressing trait
          if (!widget.isStatisticsPage) {
            addTaskProvider.unfocusAll();
          }

          await NavigatorService().goTo(
            TraitDetailPage(
              traitModel: widget.trait,
            ),
            transition: Transition.rightToLeft,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? widget.trait.color.withValues(alpha: 0.9) : AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? widget.trait.color : AppColors.text.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: widget.trait.color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Main icon
              Center(
                child: Text(
                  widget.trait.icon,
                  style: TextStyle(
                    fontSize: 28,
                    shadows: isSelected
                        ? [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),

              // Selected indicator
              if (isSelected && !widget.isStatisticsPage)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.trait.color,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check,
                        size: 12,
                        color: widget.trait.color,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
