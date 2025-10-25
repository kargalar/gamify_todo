import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/day_item.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Widgets/progress_chip.dart';
import 'package:next_level/Widgets/filter_menu_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    final selectedDate = context.watch<HomeViewModel>().selectedDate;

    return AppBar(
      titleSpacing: 0,
      centerTitle: false,
      elevation: 0,
      toolbarHeight: 50,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous day
                Expanded(child: DayItem(date: selectedDate.subtract(const Duration(days: 1)))),
                // Current selected day
                Expanded(child: DayItem(date: selectedDate)),
                // Next day
                Expanded(child: DayItem(date: selectedDate.add(const Duration(days: 1)))),
                // Day after next
                Expanded(child: DayItem(date: selectedDate.add(const Duration(days: 2)))),
                // Today button
                Expanded(
                  child: InkWell(
                    borderRadius: AppColors.borderRadiusAll,
                    onTap: () {
                      context.read<HomeViewModel>().goToday();
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: DateTime.now().day == selectedDate.day && DateTime.now().month == selectedDate.month && DateTime.now().year == selectedDate.year ? AppColors.main : AppColors.transparent,
                        borderRadius: AppColors.borderRadiusAll,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.today, size: 16),
                          Text(
                            LocaleKeys.Today.tr(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // removed cramped in-title text; total will be shown as a chip in actions
        ],
      ),
      actions: const [
        SizedBox(width: 4),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.0),
          child: ProgressChip(),
        ),
        FilterMenuButton(),
        SizedBox(width: 4),
      ],
    );
  }
}
