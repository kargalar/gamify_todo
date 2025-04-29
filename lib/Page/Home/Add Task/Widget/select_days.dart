import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';

class SelectDays extends StatefulWidget {
  const SelectDays({super.key});

  @override
  State<SelectDays> createState() => _SelectDaysState();
}

class _SelectDaysState extends State<SelectDays> {
  late final addTaskProvider = context.read<AddTaskProvider>();

  late List<String> days;

  @override
  Widget build(BuildContext context) {
    if (context.locale == const Locale('en', 'US')) {
      days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    } else {
      days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
      ),
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: days.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return DayButton(
              index: index,
              name: days[index],
            );
          },
        ),
      ),
    );
  }
}

class DayButton extends StatefulWidget {
  const DayButton({super.key, required this.index, required this.name});

  final int index;
  final String name;

  @override
  State<DayButton> createState() => _DayButtonState();
}

class _DayButtonState extends State<DayButton> {
  late final addTaskProvider = context.read<AddTaskProvider>();

  late bool isSelected;

  @override
  void initState() {
    super.initState();

    isSelected = addTaskProvider.selectedDays.contains(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: RoundedRectangleBorder(
        borderRadius: AppColors.borderRadiusCircular,
      ),
      onTap: () {
        // Unfocus any text fields when selecting days
        addTaskProvider.unfocusAll();

        setState(() {
          isSelected = !isSelected;
        });

        if (addTaskProvider.selectedDays.contains(widget.index)) {
          addTaskProvider.selectedDays.remove(widget.index);
        } else {
          addTaskProvider.selectedDays.add(widget.index);
        }
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.blue : AppColors.panelBackground4,
            borderRadius: AppColors.borderRadiusCircular,
          ),
          child: Center(
            child: Text(
              widget.name,
              style: const TextStyle(
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
