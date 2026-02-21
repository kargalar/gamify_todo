import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Page/Task%20Detail%20Page/routine_detail_page.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class DayDetailBottomSheet extends StatelessWidget {
  final DateTime date;
  final bool isDp;

  const DayDetailBottomSheet({
    super.key,
    required this.date,
    this.isDp = false,
  });

  /// Shows the day detail bottom sheet
  static void show({required BuildContext context, required DateTime date, bool isDp = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayDetailBottomSheet(date: date, isDp: isDp),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayData = _getDayData();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.panelBackground.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.main.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.calendar_month_rounded, color: AppColors.main, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(context),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          isDp ? LocaleKeys.DisciplinePoints.tr() : LocaleKeys.TotalDuration.tr(),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.text.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Summary cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (!isDp) ...[
                      _buildSummaryCard(
                        icon: Icons.timer_rounded,
                        label: LocaleKeys.TotalDuration.tr(),
                        value: dayData.totalDuration.textShort2hour(),
                        color: AppColors.main,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryCard(
                        icon: Icons.check_circle_rounded,
                        label: LocaleKeys.Done.tr(),
                        value: '${dayData.doneCount}',
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryCard(
                        icon: Icons.cancel_rounded,
                        label: LocaleKeys.Failed.tr(),
                        value: '${dayData.failedCount}',
                        color: AppColors.red,
                      ),
                    ] else ...[
                      _buildSummaryCard(
                        icon: Icons.stars_rounded,
                        label: "Total DP",
                        value: '${dayData.totalDp > 0 ? '+' : ''}${dayData.totalDp}',
                        color: AppColors.main,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryCard(
                        icon: Icons.trending_up_rounded,
                        label: "Gained",
                        value: '+${dayData.dpGained}',
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryCard(
                        icon: Icons.trending_down_rounded,
                        label: "Lost",
                        value: '${dayData.dpLost}',
                        color: AppColors.red,
                      ),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Task list
              if (dayData.taskDetails.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.inbox_rounded, size: 56, color: AppColors.grey.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        LocaleKeys.NoTaskForToday.tr(),
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: dayData.taskDetails.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = dayData.taskDetails[index];
                      return _buildTaskItem(task);
                    },
                  ),
                ),

              // Bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return LocaleKeys.Today.tr();
    } else if (dateOnly == yesterday) {
      return LocaleKeys.Yesterday.tr();
    } else {
      return DateFormat('d MMMM yyyy', context.locale.languageCode).format(date);
    }
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(_TaskDetailData task) {
    final statusColor = task.status == TaskStatusEnum.DONE
        ? AppColors.green
        : task.status == TaskStatusEnum.FAILED
            ? AppColors.red
            : task.status == TaskStatusEnum.CANCEL
                ? AppColors.orange
                : AppColors.text;

    final statusIcon = task.status == TaskStatusEnum.DONE
        ? Icons.check_circle_rounded
        : task.status == TaskStatusEnum.FAILED
            ? Icons.cancel_rounded
            : task.status == TaskStatusEnum.CANCEL
                ? Icons.do_not_disturb_on_rounded
                : Icons.circle_outlined;

    return GestureDetector(
      onTap: () => _navigateToTask(task.taskId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.category != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.category!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isDp) _buildDpIndicator(task) else _buildProgressIndicator(task),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.grey.withValues(alpha: 0.5), size: 24),
          ],
        ),
      ),
    );
  }

  void _navigateToTask(int taskId) {
    // Find task from provider
    try {
      final taskModel = TaskProvider().taskList.firstWhere((t) => t.id == taskId);

      // Close bottom sheet first
      Get.back();

      // Navigate to task detail page
      if (taskModel.routineID != null) {
        Get.to(
          () => RoutineDetailPage(taskModel: taskModel),
          transition: Transition.rightToLeft,
        );
      } else {
        Get.to(
          () => AddTaskPage(editTask: taskModel),
          transition: Transition.rightToLeft,
        );
      }
    } catch (_) {
      // Task not found
    }
  }

  Widget _buildDpIndicator(_TaskDetailData task) {
    if (task.taskId == -10) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.main.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.main.withValues(alpha: 0.3)),
        ),
        child: Text(
          '+5 DP',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.main,
          ),
        ),
      );
    } else if (task.taskId == -20) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.main.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.main.withValues(alpha: 0.3)),
        ),
        child: Text(
          '+2 DP',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.main,
          ),
        ),
      );
    } else if (task.status == TaskStatusEnum.DONE) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
        ),
        child: Text(
          '+1 DP',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.green,
          ),
        ),
      );
    } else if (task.status == TaskStatusEnum.FAILED) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
        ),
        child: Text(
          '-1 DP',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.red,
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildProgressIndicator(_TaskDetailData task) {
    if (task.type == TaskTypeEnum.TIMER) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.main.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.main.withValues(alpha: 0.3)),
        ),
        child: Text(
          task.duration.textShort2hour(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.main,
          ),
        ),
      );
    } else if (task.type == TaskTypeEnum.COUNTER) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.blue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
        ),
        child: Text(
          '${task.count}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.blue,
          ),
        ),
      );
    } else {
      // Checkbox
      return Icon(
        task.status == TaskStatusEnum.DONE ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        color: task.status == TaskStatusEnum.DONE ? AppColors.green : AppColors.grey.withValues(alpha: 0.5),
        size: 24,
      );
    }
  }

  _DaySummaryData _getDayData() {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final logs = TaskLogProvider().taskLogList.where((log) {
      return log.logDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && log.logDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
    }).toList();

    Duration totalDuration = Duration.zero;
    int doneCount = 0;
    int failedCount = 0;
    int dpGained = 0;
    int dpLost = 0;
    final Map<int, _TaskDetailData> taskMap = {};

    for (var log in logs) {
      if (log.taskId == -10) {
        dpGained += 5;
        taskMap[log.taskId] = _TaskDetailData(
          taskId: -10,
          title: "Daily Routine Bonus",
          type: TaskTypeEnum.CHECKBOX,
          category: null,
          duration: Duration.zero,
          count: 0,
          status: TaskStatusEnum.DONE,
        );
        continue;
      } else if (log.taskId == -20) {
        dpGained += 2;
        taskMap[log.taskId] = _TaskDetailData(
          taskId: -20,
          title: "Daily Task Bonus",
          type: TaskTypeEnum.CHECKBOX,
          category: null,
          duration: Duration.zero,
          count: 0,
          status: TaskStatusEnum.DONE,
        );
        continue;
      }

      TaskModel? task;
      try {
        task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
      } catch (_) {
        continue;
      }

      // Get or create task detail
      if (!taskMap.containsKey(log.taskId)) {
        String? categoryName;
        if (task.categoryId != null) {
          try {
            final category = CategoryProvider().categoryList.firstWhere((c) => c.id == task!.categoryId);
            categoryName = category.name;
          } catch (_) {}
        }

        taskMap[log.taskId] = _TaskDetailData(
          taskId: log.taskId,
          title: task.title,
          type: task.type,
          category: categoryName,
          duration: Duration.zero,
          count: 0,
          status: null,
        );
      }

      final taskDetail = taskMap[log.taskId]!;

      // Update duration
      if (log.duration != null) {
        taskDetail.duration += log.duration!;
        totalDuration += log.duration!;
      }

      // Update count
      if (log.count != null && log.count! > 0) {
        taskDetail.count += log.count!;
        // For counter tasks, also add to total duration based on remainingDuration
        if (task.remainingDuration != null) {
          final countDuration = task.remainingDuration! * log.count!;
          totalDuration += countDuration;
        }
      }

      // Update status (use latest status)
      if (log.status != null) {
        taskDetail.status = log.status;
        if (log.status == TaskStatusEnum.DONE) {
          doneCount++;
          dpGained++; // +1 DP for done task
          // For checkbox tasks, add remainingDuration to total
          if (task.type == TaskTypeEnum.CHECKBOX && task.remainingDuration != null) {
            totalDuration += task.remainingDuration!;
          }
        } else if (log.status == TaskStatusEnum.FAILED) {
          failedCount++;
          dpLost--; // -1 DP for failed task
        }
      }
    }

    return _DaySummaryData(
      totalDuration: totalDuration,
      doneCount: doneCount,
      failedCount: failedCount,
      taskDetails: taskMap.values.toList(),
      dpGained: dpGained,
      dpLost: dpLost,
    );
  }
}

class _DaySummaryData {
  final Duration totalDuration;
  final int doneCount;
  final int failedCount;
  final List<_TaskDetailData> taskDetails;
  final int dpGained;
  final int dpLost;

  _DaySummaryData({
    required this.totalDuration,
    required this.doneCount,
    required this.failedCount,
    required this.taskDetails,
    this.dpGained = 0,
    this.dpLost = 0,
  });

  int get totalDp => dpGained + dpLost; // Note: dpLost is negative, so adding them gives net DP
}

class _TaskDetailData {
  final int taskId;
  final String title;
  final TaskTypeEnum type;
  final String? category;
  Duration duration;
  int count;
  TaskStatusEnum? status;

  _TaskDetailData({
    required this.taskId,
    required this.title,
    required this.type,
    this.category,
    required this.duration,
    required this.count,
    this.status,
  });
}
