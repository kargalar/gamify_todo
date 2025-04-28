import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Home/Widget/day_item.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    final selectedDate = context.watch<TaskProvider>().selectedDate;

    return AppBar(
      titleSpacing: 0,
      centerTitle: false,
      elevation: 0,
      toolbarHeight: 50,
      title: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: AppColors.borderRadiusAll,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous day
                  Expanded(
                    child: DayItem(date: selectedDate.subtract(const Duration(days: 1))),
                  ),
                  // Current selected day
                  Expanded(
                    child: DayItem(date: selectedDate),
                  ),
                  // Next day
                  Expanded(
                    child: DayItem(date: selectedDate.add(const Duration(days: 1))),
                  ),
                  // Day after next
                  Expanded(
                    child: DayItem(date: selectedDate.add(const Duration(days: 2))),
                  ),
                  // Today button
                  Expanded(
                    child: InkWell(
                      borderRadius: AppColors.borderRadiusAll,
                      onTap: () {
                        // Provider üzerinden erişim sağlayarak bugüne dön
                        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                        taskProvider.changeSelectedDate(DateTime.now());
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
                            const Icon(
                              Icons.today,
                              size: 16,
                            ),
                            Text(
                              LocaleKeys.Day.tr(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Filter menu
        PopupMenuButton(
          icon: Icon(
            Icons.filter_list,
            size: 20,
            color: AppColors.text,
          ),
          tooltip: LocaleKeys.Settings.tr(),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          shape: RoundedRectangleBorder(
            borderRadius: AppColors.borderRadiusAll,
          ),
          itemBuilder: (context) {
            return [
              PopupMenuItem(
                onTap: () {
                  TaskProvider().changeShowCompleted();
                },
                child: Row(
                  children: [
                    Icon(
                      TaskProvider().showCompleted ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: AppColors.text,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${TaskProvider().showCompleted ? LocaleKeys.Hide.tr() : LocaleKeys.Show.tr()} ${LocaleKeys.Completed.tr()}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
