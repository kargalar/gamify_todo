import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';

class ProfilePageTopSection extends StatefulWidget {
  const ProfilePageTopSection({
    super.key,
  });

  @override
  State<ProfilePageTopSection> createState() => _ProfilePageTopSectionState();
}

class _ProfilePageTopSectionState extends State<ProfilePageTopSection> {
  late Duration totalDuration;

  @override
  void initState() {
    super.initState();

    // ? her açıldığında tüm taskalrdan çekmek yerine direkt uygulama açılırken bir defa hesaplayıp bir değişkene atayıp gerisini oradan güncellemek iyi olur mu bilmiyorum. 1500 task olduğunda nasıl oalcak bundan şüpheliyim. galiba bir cache yapısı da kurmak lazım
    totalDuration = TaskProvider().taskList.fold(
      Duration.zero,
      (previousValue, element) {
        if (element.remainingDuration != null) {
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
    return Row(
      children: [
        Column(
          children: [
            Text(
              totalDuration.toLevel(),
              style: const TextStyle(
                fontSize: 25,
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
        // const Spacer(),
        // const Text(
        //   // TODO: karma eklenince gelecek
        //   'Karma -57',
        //   style: TextStyle(
        //     fontSize: 18,
        //   ),
        // ),
      ],
    );
  }
}
