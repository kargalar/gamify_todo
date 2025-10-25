import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Page/Home/Widget/weekly_streak_dialog.dart';
import 'package:next_level/Provider/vacation_mode_provider.dart';

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
        final isVacationModeActive = VacationModeProvider().isVacationModeEnabled;

        // Determine color based on new rules
        Color mainColor;
        if (!hasReachedDaily && !hasReachedStreak) {
          mainColor = Colors.grey; // Renksiz (grey)
        } else if (hasReachedDaily && hasReachedStreak) {
          mainColor = Colors.red; // Kırmızı
        } else if (hasReachedStreak) {
          mainColor = Colors.orange; // Turuncu
        } else {
          mainColor = Colors.green; // Yeşil
        }

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
                          Text('${(percent * 100).round()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mainColor)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(vm.todayTotalText, style: TextStyle(fontSize: 12, color: AppColors.text)),
                    if (isVacationModeActive) ...[
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
