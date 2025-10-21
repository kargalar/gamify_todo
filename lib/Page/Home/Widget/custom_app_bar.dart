import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/day_item.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Page/Task Detail Page/routine_detail_page.dart';
import 'package:next_level/Page/Home/Add Task/add_task_page.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Enum/task_type_enum.dart';

void _showContributionsSheet(BuildContext context, List<Map<String, dynamic>> contributions, double percent, Color mainColor, HomeViewModel vm) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final routines = contributions.where((c) => c['task'] != null && c['task'].routineID != null).toList();
          final tasks = contributions.where((c) => c['task'] == null || c['task'].routineID == null).toList();

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                // Top divider under handle
                Container(
                  height: 1,
                  width: double.infinity,
                  color: Colors.grey.withOpacity(0.12),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: percent.clamp(0.0, 1.0),
                            strokeWidth: 6,
                            valueColor: AlwaysStoppedAnimation(mainColor),
                            backgroundColor: mainColor.withOpacity(0.12),
                          ),
                          Text('${(percent * 100).round()}%', style: TextStyle(fontWeight: FontWeight.bold, color: mainColor)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vm.todayTotalText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Günlük hedef: ${vm.todayTargetDuration.textShort2hour()} | Streak: ${vm.streakDuration.textShort2hour()}', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      if (routines.isNotEmpty) ...[
                        Text(LocaleKeys.Routines.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...routines.map((c) {
                          final TaskModel? task = c['task'] as TaskModel?;
                          final Duration duration = (c['duration'] as Duration?) ?? Duration.zero;
                          final Duration target = (task?.type == TaskTypeEnum.COUNTER && task?.targetCount != null) ? (task!.remainingDuration ?? Duration.zero) * task.targetCount! : (task?.remainingDuration ?? Duration.zero);
                          final progress = target.inSeconds > 0 ? (duration.inSeconds / target.inSeconds).clamp(0.0, 1.0) : 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.of(context).pop();
                                if (task != null && task.routineID != null) {
                                  NavigatorService().goTo(RoutineDetailPage(taskModel: task));
                                } else {
                                  NavigatorService().goTo(AddTaskPage(editTask: task));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor.withOpacity(0.96),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.withOpacity(0.08)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(task?.title ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(duration.compactFormat(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                            if (target > Duration.zero) Text(' / ${target.compactFormat()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (target > Duration.zero) ...[
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 6,
                                          valueColor: AlwaysStoppedAnimation(mainColor),
                                          backgroundColor: mainColor.withOpacity(0.12),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const Divider(),
                      ],
                      if (tasks.isNotEmpty) ...[
                        Text(LocaleKeys.Tasks.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...tasks.map((c) {
                          final TaskModel? task = c['task'] as TaskModel?;
                          final Duration duration = (c['duration'] as Duration?) ?? Duration.zero;
                          final Duration target = (task?.type == TaskTypeEnum.COUNTER && task?.targetCount != null) ? (task!.remainingDuration ?? Duration.zero) * task.targetCount! : (task?.remainingDuration ?? Duration.zero);
                          final progress = target.inSeconds > 0 ? (duration.inSeconds / target.inSeconds).clamp(0.0, 1.0) : 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.of(context).pop();
                                if (task != null && task.routineID != null) {
                                  NavigatorService().goTo(RoutineDetailPage(taskModel: task));
                                } else {
                                  NavigatorService().goTo(AddTaskPage(editTask: task));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor.withOpacity(0.96),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.withOpacity(0.08)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(task?.title ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(duration.compactFormat(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                            if (target > Duration.zero) Text(' / ${target.compactFormat()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (target > Duration.zero) ...[
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 6,
                                          valueColor: AlwaysStoppedAnimation(mainColor),
                                          backgroundColor: mainColor.withOpacity(0.12),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
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
                    onTap: () {
                      final contributions = vm.todayContributions();
                      _showContributionsSheet(context, contributions, percent, mainColor, vm);
                    },
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: hasReachedStreak ? LinearGradient(colors: [Colors.orange.withOpacity(0.3), Colors.red.withOpacity(0.2)]) : LinearGradient(colors: [mainColor.withOpacity(0.18), mainColor.withOpacity(0.08)]),
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
                                    backgroundColor: mainColor.withOpacity(0.12),
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
