import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:get/route_manager.dart';
import 'package:next_level/Page/Task Detail Page/routine_detail_page.dart';
import 'package:next_level/Page/Home/Add Task/add_task_page.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Page/Trait%20Detail%20Page/widget/monthly_comparison_chart.dart';
import 'package:next_level/Page/Trait%20Detail%20Page/widget/trait_progress_summary.dart';
import 'package:next_level/Service/logging_service.dart';

class TraitDetailPage extends StatefulWidget {
  const TraitDetailPage({
    super.key,
    required this.traitModel,
  });

  final TraitModel traitModel;

  @override
  State<TraitDetailPage> createState() => _TraitDetailPageState();
}

class _TraitDetailPageState extends State<TraitDetailPage> {
  TextEditingController traitTitleController = TextEditingController();
  String traitIcon = "🎯";
  Color selectedColor = AppColors.main;

  late Duration totalDuration;
  List<TaskModel> relatedTasks = [];
  List<TaskModel> relatedRoutines = [];

  void _saveTraitChanges() {
    if (traitTitleController.text.trim().isEmpty) {
      traitTitleController.text = widget.traitModel.title; // Reset to original if empty
      return;
    }

    final TraitModel updatedTrait = TraitModel(
      id: widget.traitModel.id,
      title: traitTitleController.text.trim(),
      icon: traitIcon,
      color: selectedColor,
      type: widget.traitModel.type,
    );

    TraitProvider().editTrait(updatedTrait);
  }

  void calculateTotalDurationFromLogs() {
    // İlgili tüm taskları al
    final tasksWithTrait = TaskProvider().taskList.where((task) => (task.attributeIDList?.contains(widget.traitModel.id) ?? false) || (task.skillIDList?.contains(widget.traitModel.id) ?? false)).toList();

    LogService.debug('Tasks with trait ${widget.traitModel.id}: ${tasksWithTrait.length}');

    // Log tabanlı toplam ilerleme, log yoksa state fallback
    totalDuration = Duration.zero;
    for (final task in tasksWithTrait) {
      final taskDuration = calculateTaskDuration(task);
      totalDuration += taskDuration;
      LogService.debug('Task ${task.id} (${task.title}): duration $taskDuration');
    }
    LogService.debug('Total duration for trait ${widget.traitModel.id}: $totalDuration');
  }

  void findRelatedTasks() {
    // Tüm taskları al
    List<TaskModel> allTasks = TaskProvider().taskList;

    // Trait ile ilgili taskları bul (sadece progress'i olanları)
    for (var task in allTasks) {
      bool hasThisTrait = (task.attributeIDList?.contains(widget.traitModel.id) ?? false) || (task.skillIDList?.contains(widget.traitModel.id) ?? false);

      if (hasThisTrait) {
        // Sadece progress'i olan task'ları ekle
        Duration taskDuration = calculateTaskDuration(task);
        if (taskDuration > Duration.zero) {
          if (task.routineID != null) {
            relatedRoutines.add(task);
          } else {
            relatedTasks.add(task);
          }
        }
      }
    }

    // Süreye göre sırala (büyükten küçüğe) - süre aynı olanlar için en son tarihe göre sırala
    relatedTasks.sort((a, b) {
      Duration aDuration = calculateTaskDuration(a);
      Duration bDuration = calculateTaskDuration(b);

      // Önce süreye göre sırala
      if (aDuration != bDuration) {
        return bDuration.compareTo(aDuration);
      }

      // Süreler eşitse tarihe göre sırala (en yeni önce)
      if (a.taskDate != null && b.taskDate != null) {
        return b.taskDate!.compareTo(a.taskDate!);
      } else if (a.taskDate != null) {
        return -1;
      } else if (b.taskDate != null) {
        return 1;
      }

      return 0;
    });

    relatedRoutines.sort((a, b) {
      Duration aDuration = calculateTaskDuration(a);
      Duration bDuration = calculateTaskDuration(b);

      // Önce süreye göre sırala
      if (aDuration != bDuration) {
        return bDuration.compareTo(aDuration);
      }

      // Süreler eşitse tarihe göre sırala (en yeni önce)
      if (a.taskDate != null && b.taskDate != null) {
        return b.taskDate!.compareTo(a.taskDate!);
      } else if (a.taskDate != null) {
        return -1;
      } else if (b.taskDate != null) {
        return 1;
      }

      return 0;
    });
  }

  Duration calculateTaskDuration(TaskModel task) {
    // Önce loglara göre hesapla; yoksa state'e göre
    final fromLogs = _calculateTaskDurationFromLogs(task);
    if (fromLogs > Duration.zero) return fromLogs;

    if (task.remainingDuration == null) return Duration.zero;
    if (task.type == TaskTypeEnum.TIMER) {
      return task.currentDuration ?? Duration.zero;
    } else if (task.type == TaskTypeEnum.COUNTER) {
      return (task.remainingDuration ?? Duration.zero) * (task.currentCount ?? 0);
    } else {
      // CHECKBOX
      return task.status == TaskStatusEnum.DONE ? (task.remainingDuration ?? Duration.zero) : Duration.zero;
    }
  }

  // Log tabanlı tek task ilerleme hesabı (tüm zamanlar)
  Duration _calculateTaskDurationFromLogs(TaskModel task) {
    final logs = TaskLogProvider().getLogsByTaskId(task.id);
    if (logs.isEmpty) {
      LogService.debug('No logs for task ${task.id}');
      return Duration.zero;
    }

    LogService.debug('Task ${task.id} has ${logs.length} logs');

    Duration total = Duration.zero;
    if (task.type == TaskTypeEnum.TIMER) {
      for (final l in logs) {
        if (l.duration != null) total += l.duration!;
      }
      LogService.debug('Timer task ${task.id}: total duration $total');
    } else if (task.type == TaskTypeEnum.COUNTER) {
      final per = task.remainingDuration ?? Duration.zero;
      int count = 0;
      for (final l in logs) {
        count += l.count ?? 0;
      }
      total = per * count;
      LogService.debug('Counter task ${task.id}: per $per, total count $count, total duration $total');
    } else if (task.type == TaskTypeEnum.CHECKBOX) {
      // Gün başına tek sayım (aynı gün birden fazla DONE varsa 1 kabul)
      final Set<String> doneDays = {};
      for (final l in logs) {
        if (l.status == TaskStatusEnum.DONE) {
          doneDays.add('${l.logDate.year}-${l.logDate.month}-${l.logDate.day}');
        }
      }
      final per = task.remainingDuration ?? Duration.zero;
      total = per * doneDays.length;
      LogService.debug('Checkbox task ${task.id}: per $per, done days ${doneDays.length}, total duration $total');
    }
    return total;
  }

  // Helper methods for status display
  Color _getStatusColor(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.DONE:
        return AppColors.green;
      case TaskStatusEnum.FAILED:
        return AppColors.red;
      case TaskStatusEnum.CANCEL:
        return AppColors.purple;
      case TaskStatusEnum.ARCHIVED:
        return AppColors.blue;
      case TaskStatusEnum.OVERDUE:
        return AppColors.orange;
    }
  }

  String _getStatusText(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.DONE:
        return LocaleKeys.Done.tr();
      case TaskStatusEnum.FAILED:
        return LocaleKeys.Failed.tr();
      case TaskStatusEnum.CANCEL:
        return LocaleKeys.Cancelled.tr();
      case TaskStatusEnum.ARCHIVED:
        return LocaleKeys.Archived.tr();
      case TaskStatusEnum.OVERDUE:
        return LocaleKeys.Overdue.tr();
    }
  }

  @override
  void initState() {
    super.initState();

    traitTitleController.text = widget.traitModel.title;
    traitIcon = widget.traitModel.icon;
    selectedColor = widget.traitModel.color;

    // Log verilerine göre trait ile ilgili toplam süreyi hesapla
    calculateTotalDurationFromLogs();

    // İlgili görevleri bul
    findRelatedTasks();
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: selectedColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: selectedColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: selectedColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    // Get weekly, monthly, and yearly data
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final yearStart = DateTime(now.year, 1, 1);

    Duration weeklyDuration = Duration.zero;
    Duration monthlyDuration = Duration.zero;
    Duration yearlyDuration = Duration.zero;

    // Calculate from logs
    final taskLogs = TaskLogProvider().taskLogList;
    LogService.debug('Total task logs: ${taskLogs.length}');
    for (final log in taskLogs) {
      final task = TaskProvider().taskList.firstWhere(
            (t) => t.id == log.taskId,
            orElse: () => TaskModel(id: -1, title: '', description: '', taskDate: null, status: null, type: TaskTypeEnum.TIMER, attributeIDList: [], skillIDList: [], isNotificationOn: false, isAlarmOn: false),
          );

      bool hasTrait = (task.attributeIDList?.contains(widget.traitModel.id) ?? false) || (task.skillIDList?.contains(widget.traitModel.id) ?? false);

      if (!hasTrait) continue;

      final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);

      // Calculate duration based on task type
      Duration logDuration = Duration.zero;
      if (log.duration != null) {
        // Timer task
        logDuration = log.duration!;
        LogService.debug('Timer task ${task.id}: log duration ${log.duration}');
      } else if (log.count != null && log.count! > 0) {
        // Counter task
        final perCount = task.remainingDuration ?? Duration.zero;
        final count = log.count! <= 100 ? log.count! : 5; // Cap extreme counts
        logDuration = perCount * count;
        LogService.debug('Counter task ${task.id}: perCount $perCount, count $count, logDuration $logDuration');
      } else if (log.status == TaskStatusEnum.DONE) {
        // Checkbox task
        logDuration = task.remainingDuration ?? Duration.zero;
        LogService.debug('Checkbox task ${task.id}: remainingDuration ${task.remainingDuration}, logDuration $logDuration');
      }

      if (logDate.isAfter(weekStart) || logDate.isAtSameMomentAs(weekStart)) {
        weeklyDuration += logDuration;
      }
      if (logDate.isAfter(monthStart) || logDate.isAtSameMomentAs(monthStart)) {
        monthlyDuration += logDuration;
      }
      if (logDate.isAfter(yearStart) || logDate.isAtSameMomentAs(yearStart)) {
        yearlyDuration += logDuration;
      }
    }

    LogService.debug('Trait ${widget.traitModel.id} - Weekly: $weeklyDuration, Monthly: $monthlyDuration, Yearly: $yearlyDuration, Total: $totalDuration');

    // Calculate weekly trend data (last 7 days)
    final weeklyData = <double>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);

      Duration dayDuration = Duration.zero;
      for (final log in taskLogs) {
        final task = TaskProvider().taskList.firstWhere(
              (t) => t.id == log.taskId,
              orElse: () => TaskModel(id: -1, title: '', description: '', taskDate: null, status: null, type: TaskTypeEnum.TIMER, attributeIDList: [], skillIDList: [], isNotificationOn: false, isAlarmOn: false),
            );

        bool hasTrait = (task.attributeIDList?.contains(widget.traitModel.id) ?? false) || (task.skillIDList?.contains(widget.traitModel.id) ?? false);

        if (!hasTrait) continue;

        final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);

        if (logDate.isAtSameMomentAs(dayStart)) {
          // Calculate duration based on task type
          Duration logDuration = Duration.zero;
          if (log.duration != null) {
            // Timer task
            logDuration = log.duration!;
          } else if (log.count != null && log.count! > 0) {
            // Counter task
            final perCount = task.remainingDuration ?? Duration.zero;
            final count = log.count! <= 100 ? log.count! : 5;
            logDuration = perCount * count;
          } else if (log.status == TaskStatusEnum.DONE) {
            // Checkbox task
            logDuration = task.remainingDuration ?? Duration.zero;
          }
          dayDuration += logDuration;
        }
      }
      weeklyData.add(dayDuration.inMinutes.toDouble());
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panelBackground2,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.Statistics.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  LocaleKeys.ThisWeek.tr(),
                  weeklyDuration.textShort2hour(),
                  Icons.calendar_view_week,
                  selectedColor.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  LocaleKeys.ThisMonth.tr(),
                  monthlyDuration.textShort2hour(),
                  Icons.calendar_month,
                  selectedColor.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "This Year",
                  yearlyDuration.textShort2hour(),
                  Icons.calendar_today,
                  selectedColor.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "All Time",
                  totalDuration.textShort2hour(),
                  Icons.timeline,
                  selectedColor.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Weekly trend chart
          Text(
            LocaleKeys.WeeklyTrendMinutes.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final dayIndex = value.toInt();
                        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Text(
                          dayNames[dayIndex % 7],
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      weeklyData.length,
                      (index) => FlSpot(index.toDouble(), weeklyData[index]),
                    ),
                    isCurved: true,
                    color: selectedColor,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: selectedColor.withValues(alpha: 0.1),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.traitModel.title} Detail',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () => NavigatorService().back(),
          child: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trait Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground2,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: traitTitleController,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (value) {
                              _saveTraitChanges();
                            },
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: LocaleKeys.Name.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.panelBackground2.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            traitIcon = await Helper().showEmojiPicker(context);
                            setState(() {});
                            _saveTraitChanges();
                          },
                          child: Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: selectedColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                traitIcon,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            selectedColor = await Helper().selectColor();
                            setState(() {});
                            _saveTraitChanges();
                          },
                          child: Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Total Duration Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      totalDuration.toLevel(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: selectedColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalDuration.textShort2hour(),
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Progress Summary
              TraitProgressSummary(
                traitModel: widget.traitModel,
                selectedColor: selectedColor,
                totalDuration: totalDuration,
              ),

              const SizedBox(height: 24),

              // Statistics Section
              _buildStatisticsSection(),

              const SizedBox(height: 24),

              // Monthly Comparison Chart
              MonthlyComparisonChart(
                traitModel: widget.traitModel,
                selectedColor: selectedColor,
              ),

              const SizedBox(height: 24),

              // Related Tasks Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleKeys.RelatedTasks.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        relatedTasks.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.panelBackground2.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  LocaleKeys.NoTasksWithProgressFound.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: relatedTasks.length,
                                itemBuilder: (context, index) {
                                  final TaskModel task = relatedTasks[index];
                                  // Log verilerine göre task süresini hesapla
                                  Duration taskDuration = calculateTaskDuration(task);

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      // Navigate to task detail/edit page
                                      await NavigatorService().goTo(
                                        AddTaskPage(editTask: task),
                                        transition: Transition.rightToLeft,
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: task.status == TaskStatusEnum.ARCHIVED ? AppColors.panelBackground2.withValues(alpha: 0.5) : AppColors.panelBackground2,
                                        borderRadius: BorderRadius.circular(12),
                                        border: task.status == TaskStatusEnum.ARCHIVED ? Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1) : null,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  task.title,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: task.status == TaskStatusEnum.ARCHIVED ? Colors.grey : AppColors.text,
                                                    decoration: task.status == TaskStatusEnum.ARCHIVED ? TextDecoration.lineThrough : TextDecoration.none,
                                                  ),
                                                ),
                                              ),
                                              if (task.status != null) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(task.status!),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    _getStatusText(task.status!),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                task.taskDate != null ? task.taskDate!.toLocal().toString().split(' ')[0] : "No date",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                taskDuration.textShort2hour(),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.text,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Related Routines",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        relatedRoutines.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.panelBackground2.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "No routines with progress found",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: relatedRoutines.length,
                                itemBuilder: (context, index) {
                                  final TaskModel task = relatedRoutines[index];
                                  // Log verilerine göre task süresini hesapla
                                  Duration taskDuration = calculateTaskDuration(task);

                                  // Artık task duration hesaplaması calculateTaskDuration metodunda yapılıyor

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      // Navigate to routine task detail page
                                      await NavigatorService().goTo(
                                        RoutineDetailPage(taskModel: task),
                                        transition: Transition.rightToLeft,
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.panelBackground2,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                task.taskDate != null ? task.taskDate!.toLocal().toString().split(' ')[0] : "No date",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                taskDuration.textShort2hour(),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.text,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Delete Button
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    TraitProvider().removeTrait(widget.traitModel.id);
                    Get.back();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.red.withValues(alpha: 0.9),
                    ),
                    child: Text(
                      LocaleKeys.Delete.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
