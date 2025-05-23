import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Trait%20Detail%20Page/trait_detail_page.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:get/route_manager.dart';

class TraitItemDetailed extends StatefulWidget {
  const TraitItemDetailed({
    super.key,
    required this.trait,
  });

  final TraitModel trait;

  @override
  State<TraitItemDetailed> createState() => _TraitItemDetailedState();
}

class _TraitItemDetailedState extends State<TraitItemDetailed> {
  late Duration totalDuration;

  @override
  void initState() {
    super.initState();

    // related tasks
    totalDuration = TaskProvider().taskList.fold(
      Duration.zero,
      (previousValue, element) {
        if (((element.skillIDList != null && element.skillIDList!.contains(widget.trait.id)) || (element.attributeIDList != null && element.attributeIDList!.contains(widget.trait.id))) && element.remainingDuration != null) {
          if (element.type == TaskTypeEnum.CHECKBOX && element.status != TaskStatusEnum.COMPLETED) {
            return previousValue;
          }
          return previousValue +
              (element.type == TaskTypeEnum.CHECKBOX
                  ? element.remainingDuration!
                  : element.type == TaskTypeEnum.COUNTER
                      ? element.remainingDuration! * element.currentCount!
                      : element.currentDuration!);
        }
        return previousValue;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: AppColors.borderRadiusAll,
        highlightColor: widget.trait.color,
        splashColor: widget.trait.color,
        onTap: () async {
          await NavigatorService().goTo(
            TraitDetailPage(
              traitModel: widget.trait,
            ),
            transition: Transition.rightToLeft,
          );
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
            borderRadius: AppColors.borderRadiusAll,
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(2),
                child: Center(
                  child: Text(
                    widget.trait.icon,
                    style: const TextStyle(
                      fontSize: 25,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trait.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    totalDuration.textShort2hour(),
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                totalDuration.toLevel(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
