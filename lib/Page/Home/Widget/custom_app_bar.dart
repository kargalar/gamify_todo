import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/day_item.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/vacation_mode_provider.dart';
import 'package:next_level/Service/debug_helper.dart';
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
    final selectedDate = context.watch<TaskProvider>().selectedDate;

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
                  // Debug button (temporary)
                  if (kDebugMode)
                    IconButton(
                      icon: const Icon(
                        Icons.bug_report,
                        size: 20,
                        color: AppColors.red,
                      ),
                      tooltip: 'Debug',
                      onPressed: () async {
                        await DebugHelper.runFullDebug();
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Vacation mode indicator
        Consumer<VacationModeProvider>(
          builder: (context, vacationModeProvider, child) {
            if (vacationModeProvider.isVacationModeEnabled) {
              return InkWell(
                onTap: () {
                  _showVacationModeDialog(context);
                },
                borderRadius: AppColors.borderRadiusAll,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.main,
                    borderRadius: AppColors.borderRadiusAll,
                  ),
                  child: const Icon(
                    Icons.beach_access,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
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
                onTap: () async {
                  await TaskProvider().changeShowCompleted();
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
                      "${TaskProvider().showCompleted ? LocaleKeys.Hide.tr() : LocaleKeys.Show.tr()} ${LocaleKeys.Done.tr()}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () {
                  // Defer action to after menu closes
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                    taskProvider.skipRoutinesForDate(taskProvider.selectedDate);
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

  void _showVacationModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text('Tatil Modu'),
          content: const Text('Tatil modunu kapatmak istiyor musunuz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Kapat',
                style: TextStyle(color: AppColors.red),
              ),
              onPressed: () {
                VacationModeProvider().toggleVacationMode();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
