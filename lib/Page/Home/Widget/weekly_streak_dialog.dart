import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/streak_calendar_dialog.dart';
import 'package:next_level/Page/Home/Widget/task_contributions_widget.dart';
import 'package:next_level/Provider/home_view_model.dart';

class WeeklyStreakDialog extends StatefulWidget {
  final HomeViewModel vm;

  const WeeklyStreakDialog({super.key, required this.vm});

  @override
  State<WeeklyStreakDialog> createState() => _WeeklyStreakDialogState();
}

class _WeeklyStreakDialogState extends State<WeeklyStreakDialog> {
  @override
  Widget build(BuildContext context) {
    // Calculate initial size based on today's tasks
    final taskCount = widget.vm.todayContributions().length;
    final dynamicInitialSize = 0.2 + (taskCount * 0.10).clamp(0.4, 0.9);

    return DraggableScrollableSheet(
      initialChildSize: dynamicInitialSize,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: const Border(
              top: BorderSide(color: AppColors.dirtyWhite),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300]!.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.grey.withValues(alpha: 0.12),
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
                          value: widget.vm.todayProgressPercent.clamp(0.0, 1.0),
                          strokeWidth: 6,
                          valueColor: AlwaysStoppedAnimation(AppColors.main),
                          backgroundColor: AppColors.main.withValues(alpha: 0.12),
                        ),
                        Text('${(widget.vm.todayProgressPercent * 100).round()}%', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.main)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.vm.todayTotalText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Günlük hedef: ${widget.vm.todayTargetDuration.textShort2hour()} | Streak: ${widget.vm.streakDuration.textShort2hour()}', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Streak Status Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Streak Durumu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        TextButton(
                          onPressed: () => _showFullStreakCalendar(context),
                          child: const Text('Tümünü Göster', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: widget.vm.streakStatuses.map((status) {
                        final isMet = status['isMet'] as bool?;
                        final dayName = status['dayName'] as String;
                        final isFuture = status['isFuture'] as bool;
                        final isVacation = status['isVacation'] as bool? ?? false;
                        final color = isFuture
                            ? Colors.blue
                            : isVacation
                                ? Colors.orange
                                : (isMet == true ? Colors.green : Colors.red);
                        return Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withValues(alpha: 0.2),
                                border: Border.all(
                                  color: color,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                isFuture ? Icons.schedule : (isVacation ? Icons.beach_access : (isMet == true ? Icons.check : Icons.close)),
                                size: 16,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dayName,
                              style: TextStyle(fontSize: 10, color: AppColors.text),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.green, 'Ulaşıldı'),
                  const SizedBox(width: 12),
                  _buildLegendItem(Colors.red, 'Ulaşılamadı'),
                  const SizedBox(width: 12),
                  _buildLegendItem(Colors.orange, 'Tatil'),
                  const SizedBox(width: 12),
                  _buildLegendItem(Colors.blue, 'Gelecek'),
                ],
              ),
              const SizedBox(height: 12),
              // Today's Tasks Section
              TaskContributionsWidget(vm: widget.vm),
            ],
          ),
        );
      },
    );
  }

  void _showFullStreakCalendar(BuildContext context) {
    Navigator.of(context).pop(); // Close weekly dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreakCalendarDialog(vm: widget.vm),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.text)),
      ],
    );
  }
}
