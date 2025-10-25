import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class SelectDaysWidget extends StatefulWidget {
  final AddTaskProvider addTaskProvider;

  const SelectDaysWidget({
    super.key,
    required this.addTaskProvider,
  });

  @override
  State<SelectDaysWidget> createState() => _SelectDaysWidgetState();
}

class _SelectDaysWidgetState extends State<SelectDaysWidget> {
  // Build select days section for routine mode
  Widget _buildSelectDaysSection() {
    late List<String> days;

    days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        // Material(
        //   color: Colors.transparent,
        //   child: InkWell(
        //     borderRadius: BorderRadius.circular(6),
        //     onTap: () {
        //       // Unfocus any text fields
        //       widget.addTaskProvider.unfocusAll();

        //       // Tarihsiz seçiliyken rutin günü seçilmeye çalışıldığında uyarı
        //       if (widget.addTaskProvider.selectedDate == null && widget.addTaskProvider.selectedDays.length != 7) {
        //         Helper().getMessage(
        //           message: LocaleKeys.RoutineMustHaveDate.tr(),
        //           status: StatusEnum.WARNING,
        //         );
        //         debugPrint('SelectDaysWidget: Select all cancelled - no date selected for routine');
        //         return;
        //       }

        //       // Toggle select all functionality
        //       if (widget.addTaskProvider.selectedDays.length == 7) {
        //         // If all days are selected, clear selection
        //         widget.addTaskProvider.selectedDays.clear();
        //         debugPrint('SelectDaysWidget: All days cleared successfully');
        //       } else {
        //         // Select all days
        //         widget.addTaskProvider.selectedDays.clear();
        //         widget.addTaskProvider.selectedDays.addAll([0, 1, 2, 3, 4, 5, 6]);
        //         debugPrint('SelectDaysWidget: All days selected successfully');
        //       }
        //       setState(() {});
        //     },
        //     child: Container(
        //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        //       decoration: BoxDecoration(
        //         color: widget.addTaskProvider.selectedDays.length == 7 ? AppColors.main.withValues(alpha: 0.1) : AppColors.text.withValues(alpha: 0.05),
        //         borderRadius: BorderRadius.circular(6),
        //         border: Border.all(
        //           color: widget.addTaskProvider.selectedDays.length == 7 ? AppColors.main.withValues(alpha: 0.3) : AppColors.text.withValues(alpha: 0.1),
        //           width: 1,
        //         ),
        //       ),
        //       child: Text(
        //         widget.addTaskProvider.selectedDays.length == 7 ? LocaleKeys.Clear.tr() : LocaleKeys.All.tr(),
        //         style: TextStyle(
        //           fontSize: 12,
        //           fontWeight: FontWeight.w500,
        //           color: widget.addTaskProvider.selectedDays.length == 7 ? AppColors.main : AppColors.text.withValues(alpha: 0.7),
        //         ),
        //       ),
        //     ),
        //   ),
        // ),

        // Days selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            days.length,
            (index) => _buildDayButton(index, days[index]),
          ),
        ),

        // Warning message for routines without date
        if (widget.addTaskProvider.selectedDays.isNotEmpty && widget.addTaskProvider.selectedDate == null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.dirtyRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.dirtyRed,
                  width: 1,
                ),
              ),
              child: Text(
                LocaleKeys.RoutineRequiresStartDate.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.dirtyRed,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Build day button for select days section
  Widget _buildDayButton(int index, String name) {
    final isSelected = widget.addTaskProvider.selectedDays.contains(index);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Unfocus any text fields when selecting days
          widget.addTaskProvider.unfocusAll();

          // Tarihsiz seçiliyken rutin günü seçilmeye çalışıldığında uyarı
          if (widget.addTaskProvider.selectedDate == null && !widget.addTaskProvider.selectedDays.contains(index)) {
            Helper().getMessage(
              message: LocaleKeys.RoutineMustHaveDate.tr(),
              status: StatusEnum.WARNING,
            );
            debugPrint('SelectDaysWidget: Day $name selection cancelled - no date selected for routine');
            return;
          }

          if (widget.addTaskProvider.selectedDays.contains(index)) {
            widget.addTaskProvider.selectedDays.remove(index);
            debugPrint('SelectDaysWidget: Day $name deselected successfully');
          } else {
            widget.addTaskProvider.selectedDays.add(index);
            debugPrint('SelectDaysWidget: Day $name selected successfully');
          }

          // Force rebuild to show the updated state
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 45,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.main.withValues(alpha: 0.9) : AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.main : AppColors.text.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.text.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSelectDaysSection();
  }
}
