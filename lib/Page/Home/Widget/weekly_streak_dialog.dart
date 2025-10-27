import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/streak_calendar_dialog.dart';
import 'package:next_level/Page/Home/Widget/task_contributions_widget.dart';
import 'package:next_level/Page/Settings/streak_settings_page.dart';
import 'package:next_level/Page/Settings/vacation_day_settings_page.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Provider/vacation_mode_provider.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:provider/provider.dart';

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

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(widget.vm.todayTotalText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            Consumer<VacationModeProvider>(
                              builder: (context, vacationProvider, child) {
                                return Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close the dialog first
                                        NavigatorService().goTo(const VacationDaySettingsPage());
                                      },
                                      icon: const Icon(Icons.settings, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
                                      tooltip: 'Vacation Days',
                                    ),
                                    Switch(
                                      value: vacationProvider.isVacationModeEnabled,
                                      onChanged: (value) async {
                                        await vacationProvider.toggleVacationMode();
                                        // Trigger rebuild to update streak status
                                        setState(() {});
                                      },
                                      activeThumbColor: Colors.orange,
                                      activeTrackColor: Colors.orange.withValues(alpha: 0.3),
                                      inactiveThumbColor: Colors.grey,
                                      inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                                      thumbIcon: WidgetStateProperty.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return const Icon(Icons.beach_access, color: Colors.white, size: 16);
                                        }
                                        return const Icon(Icons.work, color: Colors.white, size: 16);
                                      }),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${'DailyTargetLabel'.tr()}: ${widget.vm.todayTargetDuration.textShort2hour()} | ${'StreakLabel'.tr()}: ${widget.vm.streakDuration.textShort2hour()}', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
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
                        Text('StreakStatus'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog first
                                NavigatorService().goTo(const StreakSettingsPage());
                              },
                              icon: const Icon(Icons.settings, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'StreakSettings'.tr(),
                            ),
                            TextButton(
                              onPressed: () => _showFullStreakCalendar(context),
                              child: Text('ShowAll'.tr(), style: const TextStyle(fontSize: 12)),
                            ),
                          ],
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
                        final isToday = dayName == 'Today'.tr();
                        final isTomorrow = dayName == 'Tomorrow'.tr();

                        // Renk mantığı:
                        // 1. Vacation günleri (geçmişte gerçekten tatil olanlar veya gelecekte weekday/mode'dan tatil olanlar): turuncu
                        // 2. Tomorrow ve vacation mode aktifse: mavi (weekday kontrolüne bakılmaz)
                        // 3. Diğer future günler: mavi
                        // 4. Geçmiş günler: yeşil (başarılı) veya kırmızı (başarısız)
                        final color = isVacation
                            ? Colors.orange // Gerçek vacation günleri
                            : isTomorrow
                                ? Colors.blue // Tomorrow her zaman mavi (vacation mode aktif olsa bile)
                                : isFuture
                                    ? Colors.blue // Diğer future günler
                                    : (isMet == null ? Colors.grey : (isMet == true ? Colors.green : Colors.red));

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
                                  width: isToday ? 3 : 2, // Today için daha kalın border
                                ),
                              ),
                              child: Icon(
                                isVacation
                                    ? Icons.beach_access // Vacation icon
                                    : isFuture
                                        ? Icons.schedule // Future icon (tomorrow dahil)
                                        : (isMet == null ? Icons.help_outline : (isMet == true ? Icons.check : Icons.close)),
                                size: 16,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 10,
                                color: isToday ? AppColors.text : AppColors.text.withAlpha(180),
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal, // Today için bold
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
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
}
