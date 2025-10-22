import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/day_item.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Page/Home/Widget/weekly_streak_dialog.dart';

void _showWeeklyStreakDialog(BuildContext context, HomeViewModel vm) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (context) => WeeklyStreakDialog(vm: vm),
  );
}

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
      actions: [
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Consumer<HomeViewModel>(
            builder: (context, vm, child) {
              final percent = vm.todayProgressPercent;
              const Color start = Color(0xFFFFA726);
              const Color end = Color(0xFF66BB6A);
              final Color mainColor = percent > 1.0 ? const Color(0xFF42A5F5) : (Color.lerp(start, end, percent.clamp(0.0, 1.0)) ?? end);
              final bool hasReachedStreak = vm.todayTotalDuration >= vm.streakDuration;

              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 350),
                tween: Tween(begin: 0.92, end: 1.0),
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: GestureDetector(
                    onTap: () => _showWeeklyStreakDialog(context, vm),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: hasReachedStreak ? LinearGradient(colors: [Colors.orange.withValues(alpha: 0.3), Colors.red.withValues(alpha: 0.2)]) : LinearGradient(colors: [mainColor.withValues(alpha: 0.18), mainColor.withValues(alpha: 0.08)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: percent.clamp(0.0, 1.0)),
                                  duration: const Duration(milliseconds: 650),
                                  builder: (context, value, _) => CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation(mainColor),
                                    backgroundColor: mainColor.withValues(alpha: 0.12),
                                  ),
                                ),
                                Text('${(percent * 100).round()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mainColor)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(vm.todayTotalText, style: TextStyle(fontSize: 12, color: AppColors.text)),
                          if (hasReachedStreak) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.whatshot, size: 16, color: Colors.red),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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
