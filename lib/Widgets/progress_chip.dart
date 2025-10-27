import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Provider/vacation_date_provider.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Page/Home/Widget/weekly_streak_dialog.dart';
import 'package:next_level/Service/logging_service.dart';

void _showWeeklyStreakDialog(BuildContext context, HomeViewModel vm) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (context) => WeeklyStreakDialog(vm: vm),
  );
}

class ProgressChip extends StatelessWidget {
  const ProgressChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, vm, child) {
        final percent = vm.todayProgressPercent;
        final hasReachedDaily = percent >= 1.0;
        final hasReachedStreak = vm.todayTotalDuration >= vm.streakDuration;

        // Check if today is vacation (vacation mode, vacation weekday, or specific date)
        final today = DateTime.now();
        final isTodayVacation = VacationDateProvider().isVacationDay(today);

        // Determine color based on four states
        Color mainColor;
        String statusMessage;
        if (!hasReachedDaily && !hasReachedStreak) {
          // 1. Durum: Ne daily ne streak - Renksiz (grey)
          mainColor = Colors.grey;
          statusMessage = 'Neither daily nor streak goals have been reached yet';
        } else if (hasReachedStreak && !hasReachedDaily) {
          // 2. Durum: Streak var ama daily yok - Turuncu
          mainColor = Colors.orange;
          statusMessage = 'Streak goal has been reached but daily goal has not been reached';
        } else if (hasReachedDaily && !hasReachedStreak) {
          // 3. Durum: Daily var ama streak yok - Yeşil
          mainColor = Colors.green;
          statusMessage = 'Daily goal has been reached but streak goal has not been reached';
        } else {
          // 4. Durum: Hem daily hem streak - Kırmızı
          mainColor = Colors.red;
          statusMessage = 'Both daily and streak goals have been reached! 🔥';
        }

        LogService.debug('📊 Progress Chip Status: $statusMessage (Daily: ${(percent * 100).round()}%, Streak: ${vm.todayTotalDuration.inMinutes}/${vm.streakDuration.inMinutes}min, Vacation: $isTodayVacation)');

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 350),
          tween: Tween(begin: 0.92, end: 1.0),
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: () => _showWeeklyStreakDialog(context, vm),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [mainColor.withValues(alpha: 0.18), mainColor.withValues(alpha: 0.08)]),
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
                          Text('${(percent * 100).round()}%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: mainColor)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(vm.todayTotalText, style: TextStyle(fontSize: 12, color: AppColors.text)),
                    if (isTodayVacation) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.beach_access, size: 16, color: Colors.orange),
                    ],
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
    );
  }
}
