import 'package:flutter/material.dart';
import 'package:next_level/Core/duration_calculator.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';

class StreakCalendarDialog extends StatefulWidget {
  final HomeViewModel vm;

  const StreakCalendarDialog({super.key, required this.vm});

  @override
  State<StreakCalendarDialog> createState() => _StreakCalendarDialogState();
}

class _StreakCalendarDialogState extends State<StreakCalendarDialog> {
  late DateTime _minDate;
  late DateTime _maxDate;
  late PageController _pageController;
  late int _currentPageIndex;

  @override
  void initState() {
    super.initState();
    _calculateDateRange();
    _currentPageIndex = _calculatePageIndex(DateTime.now());
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  void _calculateDateRange() {
    final logs = TaskLogProvider().taskLogList;
    if (logs.isEmpty) {
      final now = DateTime.now();
      _minDate = DateTime(now.year, now.month, 1);
      _maxDate = DateTime(now.year, now.month + 1, 0);
      return;
    }

    DateTime minDate = logs.first.logDate;
    DateTime maxDate = logs.first.logDate;

    for (final log in logs) {
      if (log.logDate.isBefore(minDate)) minDate = log.logDate;
      if (log.logDate.isAfter(maxDate)) maxDate = log.logDate;
    }

    _minDate = DateTime(minDate.year, minDate.month, 1);
    _maxDate = DateTime(maxDate.year, maxDate.month + 1, 0);
  }

  int _calculatePageIndex(DateTime date) {
    final minYear = _minDate.year;
    final minMonth = _minDate.month;
    final targetYear = date.year;
    final targetMonth = date.month;

    return (targetYear - minYear) * 12 + (targetMonth - minMonth);
  }

  DateTime _getDateFromPageIndex(int pageIndex) {
    final minYear = _minDate.year;
    final minMonth = _minDate.month;

    final totalMonths = minMonth - 1 + pageIndex;
    final year = minYear + (totalMonths ~/ 12);
    final month = (totalMonths % 12) + 1;

    return DateTime(year, month);
  }

  int _getTotalPages() {
    final minYear = _minDate.year;
    final minMonth = _minDate.month;
    final maxYear = _maxDate.year;
    final maxMonth = _maxDate.month;

    return (maxYear - minYear) * 12 + (maxMonth - minMonth) + 1;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
          child: Column(
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300]!.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Streak Takvimi',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Month/Year Navigation
              Container(
                height: 60,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (pageIndex) {
                    setState(() {
                      _currentPageIndex = pageIndex;
                    });
                  },
                  itemCount: _getTotalPages(),
                  itemBuilder: (context, index) {
                    final date = _getDateFromPageIndex(index);
                    final isCurrentPage = index == _currentPageIndex;

                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrentPage ? AppColors.main.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_getMonthName(date.month)} ${date.year}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isCurrentPage ? AppColors.main : AppColors.text,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Calendar Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCalendarGrid(_getDateFromPageIndex(_currentPageIndex)),
                ),
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Colors.green, 'Ulaşıldı'),
                    const SizedBox(width: 12),
                    _buildLegendItem(Colors.red, 'Ulaşılamadı'),
                    const SizedBox(width: 12),
                    _buildLegendItem(Colors.orange, 'Tatil'),
                    const SizedBox(width: 12),
                    _buildLegendItem(Colors.blue, 'Gelecek'),
                    const SizedBox(width: 12),
                    _buildLegendItem(Colors.grey, 'Veri Yok'),
                  ],
                ),
              ),

              // Statistics
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildStatistics(_getDateFromPageIndex(_currentPageIndex)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarGrid(DateTime selectedDate) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Calculate starting weekday (0 = Monday, 6 = Sunday)
    final startWeekday = (firstDayOfMonth.weekday - 1) % 7;

    return Column(
      children: [
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar days
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: 42, // 6 weeks * 7 days
            itemBuilder: (context, index) {
              final dayNumber = index - startWeekday + 1;
              final isValidDay = dayNumber > 0 && dayNumber <= daysInMonth;

              if (!isValidDay) {
                return const SizedBox.shrink();
              }

              final date = DateTime(selectedDate.year, selectedDate.month, dayNumber);
              final now = DateTime.now();
              final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
              final isVacation = DurationCalculator.isVacationDay(date);
              debugPrint('StreakCalendarDialog: Date $date, isFuture: $isFuture, isVacation: $isVacation');
              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

              Color statusColor;
              IconData? statusIcon;

              if (isFuture) {
                statusColor = Colors.blue;
                statusIcon = Icons.schedule;
              } else if (isVacation) {
                statusColor = Colors.orange;
                statusIcon = Icons.beach_access;
              } else {
                try {
                  final isMet = DurationCalculator.calculateStreakStatusForDate(date);
                  if (isMet) {
                    statusColor = Colors.green;
                    statusIcon = Icons.check;
                  } else {
                    statusColor = Colors.red;
                    statusIcon = Icons.close;
                  }
                } catch (e) {
                  statusColor = Colors.grey;
                  statusIcon = Icons.help_outline;
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isToday ? 0.3 : 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: isToday ? Border.all(color: Colors.orange, width: 1.5) : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: statusColor,
                      ),
                    ),
                    if (!isToday)
                      Positioned(
                        bottom: 1,
                        right: 1,
                        child: Icon(
                          statusIcon,
                          size: 6,
                          color: statusColor,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(DateTime selectedDate) {
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final now = DateTime.now();

    int totalDays = 0;
    int successfulDays = 0;

    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(selectedDate.year, selectedDate.month, day);
      if (date.isAfter(DateTime(now.year, now.month, now.day))) continue;

      final isVacation = DurationCalculator.isVacationDay(date);
      if (isVacation) continue; // Tatil günlerini istatistiklere dahil etme

      totalDays++;
      try {
        final isMet = DurationCalculator.calculateStreakStatusForDate(date);
        if (isMet) {
          successfulDays++;
        }
      } catch (e) {
        // Veri yok
      }
    }

    final successRate = totalDays > 0 ? (successfulDays / totalDays * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            '${_getMonthName(selectedDate.month)} ${selectedDate.year} İstatistikleri',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Toplam', '$totalDays'),
              _buildStatItem('Başarılı', '$successfulDays'),
              _buildStatItem('Oran', '%$successRate'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.text.withValues(alpha: 0.7),
          ),
        ),
      ],
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

  String _getMonthName(int month) {
    const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return months[month - 1];
  }
}
