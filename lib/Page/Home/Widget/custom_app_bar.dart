import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/day_item.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
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
    final selectedDate = context.watch<HomeViewModel>().selectedDate;

    return AppBar(
      titleSpacing: 0,
      centerTitle: false,
      elevation: 0,
      toolbarHeight: 50,
      title: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
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
                            const Icon(
                              Icons.today,
                              size: 16,
                            ),
                            Text(
                              LocaleKeys.Today.tr(),
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
            final homeViewModel = context.read<HomeViewModel>();
            return [
              PopupMenuItem(
                onTap: () async {
                  await context.read<HomeViewModel>().toggleShowCompleted();
                },
                child: Row(
                  children: [
                    Icon(
                      homeViewModel.showCompleted ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: AppColors.text,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${homeViewModel.showCompleted ? LocaleKeys.Hide.tr() : LocaleKeys.Show.tr()} ${LocaleKeys.Done.tr()}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () {
                  // Defer action to after menu closes
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<HomeViewModel>().skipRoutinesForSelectedDate();
                  });
                },
                child: Row(
                  children: [
                    const Icon(Icons.skip_next, size: 18),
                    const SizedBox(width: 8),
                    Text(LocaleKeys.SkipRoutine.tr()),
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
