import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/task_provider.dart';

class GoTodayButton extends StatelessWidget {
  const GoTodayButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppColors.borderRadiusAll,
      onTap: () {
        TaskProvider().changeSelectedDate(DateTime.now());
      },
      child: const Padding(
        padding: EdgeInsets.all(5),
        child: Icon(Icons.today),
      ),
    );
  }
}
