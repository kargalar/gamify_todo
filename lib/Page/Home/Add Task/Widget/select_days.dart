import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
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
    // Listen to changes in selectedDays and selectedDate to rebuild the widget
    context.watch<AddTaskProvider>();

    if (context.locale == const Locale('en', 'US')) {
      days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    } else {
      days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    }

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
        children: [          // Header with title and icon
          Row(
            children: [
              Expanded(
                child: ClickableTooltip(
                  title: "Repeat Days",
                  bulletPoints: const ["Select days for recurring tasks", "No selection means one-time task", "Routines require a start date", "Tasks will repeat on selected days"],
                  child: Container(
                    color: AppColors.transparent,
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.main,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Repeat Days",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Select All button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    // Unfocus any text fields
                    addTaskProvider.unfocusAll();
                    
                    // Toggle select all functionality
                    if (addTaskProvider.selectedDays.length == 7) {
                      // If all days are selected, clear selection
                      addTaskProvider.selectedDays.clear();
                    } else {
                      // Select all days
                      addTaskProvider.selectedDays.clear();
                      addTaskProvider.selectedDays.addAll([0, 1, 2, 3, 4, 5, 6]);
                    }
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: addTaskProvider.selectedDays.length == 7 
                          ? AppColors.main.withValues(alpha: 0.1)
                          : AppColors.text.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: addTaskProvider.selectedDays.length == 7 
                            ? AppColors.main.withValues(alpha: 0.3)
                            : AppColors.text.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      addTaskProvider.selectedDays.length == 7 ? "Clear" : "All",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: addTaskProvider.selectedDays.length == 7 
                            ? AppColors.main
                            : AppColors.text.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
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

          // Days selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              days.length,
              (index) => DayButton(
                index: index,
                name: days[index],
              ),
            ),
          ),

          // Warning message for routines without date
          if (addTaskProvider.selectedDays.isNotEmpty && addTaskProvider.selectedDate == null)
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
                child: const Text(
                  "Rutin oluşturmak için başlangıç tarihi seçmelisiniz.",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.dirtyRed,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
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

  @override
  Widget build(BuildContext context) {
    // Listen to provider changes to update the button state
    context.watch<AddTaskProvider>();
    final isSelected = addTaskProvider.selectedDays.contains(widget.index);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),        onTap: () {
          // Unfocus any text fields when selecting days
          addTaskProvider.unfocusAll();

          if (addTaskProvider.selectedDays.contains(widget.index)) {
            addTaskProvider.selectedDays.remove(widget.index);
          } else {
            addTaskProvider.selectedDays.add(widget.index);
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
              widget.name,
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
}
