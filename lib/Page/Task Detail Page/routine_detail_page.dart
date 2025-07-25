import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/all_time_stats_widget.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/archive_button.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/edit_progress_widget.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/recent_logs_widget.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/trait_progress_widget.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/unarchive_button.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';

class RoutineDetailPage extends StatefulWidget {
  const RoutineDetailPage({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  State<RoutineDetailPage> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage> {
  late TaskDetailViewModel _viewModel;
  late final routine = widget.taskModel.routineID != null
      ? TaskProvider().routineList.firstWhere(
            (r) => r.id == widget.taskModel.routineID,
            orElse: () => throw ArgumentError('Routine not found with ID: ${widget.taskModel.routineID}'),
          )
      : throw ArgumentError('Task model has no routine ID');

  @override
  void initState() {
    super.initState();
    _viewModel = TaskDetailViewModel(widget.taskModel);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    // ViewModel'i dispose et
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TaskProvider'ı dinle (seçili tarih değiştiğinde viewModel'i güncelle)
    context.watch<TaskProvider>();

    // Seçili tarih değiştiğinde viewModel'i güncelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadRecentLogs();
    });

    // TaskDetailViewModel'i dinle
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.taskModel.title + (widget.taskModel.status == TaskStatusEnum.ARCHIVED ? " (Archived)" : ""),
            ),
            leading: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => NavigatorService().back(),
              child: const Icon(Icons.arrow_back_ios),
            ),
            actions: [
              if (widget.taskModel.status != TaskStatusEnum.ARCHIVED)
                TextButton(
                  onPressed: () async {
                    await NavigatorService().goTo(
                      AddTaskPage(editTask: widget.taskModel),
                      transition: Transition.rightToLeft,
                    );
                  },
                  child: Text(
                    LocaleKeys.Edit.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.main,
                    ),
                  ),
                ),
              // Reset routine progress menu
              if (widget.taskModel.routineID != null && widget.taskModel.status != TaskStatusEnum.ARCHIVED)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'reset_routine_progress') {
                      _showResetRoutineProgressDialog();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'reset_routine_progress',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: AppColors.text),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.ResetRoutineProgress.tr()),
                        ],
                      ),
                    ),
                  ],
                ),
              if (widget.taskModel.status == TaskStatusEnum.ARCHIVED)
                TextButton(
                  onPressed: () async {
                    Helper().getDialog(
                        message: "Are you sure delete?",
                        onAccept: () async {
                          if (widget.taskModel.routineID == null) {
                            await TaskProvider().deleteTask(widget.taskModel.id);
                          } else {
                            await TaskProvider().deleteRoutine(widget.taskModel.routineID!);
                          }

                          NavigatorService().goBackNavbar();
                        });
                  },
                  child: Text(
                    LocaleKeys.Delete.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.red,
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  IgnorePointer(
                    // TODO :: FFİX FİX İFX
                    ignoring: widget.taskModel.status == TaskStatusEnum.ARCHIVED,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),

                        // Current Progress
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.panelBackground,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with title and icon
                              Row(
                                children: [
                                  Icon(
                                    Icons.track_changes_rounded,
                                    color: AppColors.main,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Current Progress",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              // Divider
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: AppColors.text.withValues(alpha: 0.1),
                                  height: 1,
                                ),
                              ),

                              EditProgressWidget.forTask(task: widget.taskModel),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // All Time Stats and Success Metrics
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.panelBackground,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with title and icon
                              Row(
                                children: [
                                  Icon(
                                    Icons.bar_chart_rounded,
                                    color: AppColors.main,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Statistics",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              // Divider
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: AppColors.text.withValues(alpha: 0.1),
                                  height: 1,
                                ),
                              ),

                              // All Time Stats
                              AllTimeStatsWidget(
                                viewModel: _viewModel,
                                taskType: widget.taskModel.type,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Trait Progress
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.panelBackground,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with title and icon
                              Row(
                                children: [
                                  Icon(
                                    Icons.psychology_rounded,
                                    color: AppColors.main,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Trait Progress",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              // Divider
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: AppColors.text.withValues(alpha: 0.1),
                                  height: 1,
                                ),
                              ),

                              TraitProgressWidget(viewModel: _viewModel),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Recent Logs
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.panelBackground,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with title and icon
                              Row(
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    color: AppColors.main,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    LocaleKeys.RecentLogs.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              // Divider
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: AppColors.text.withValues(alpha: 0.1),
                                  height: 1,
                                ),
                              ),

                              RecentLogsWidget(viewModel: _viewModel),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      // Archive Button
                      if (widget.taskModel.status != TaskStatusEnum.ARCHIVED)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ArchiveButton(
                            routine: routine,
                            taskModel: widget.taskModel,
                          ),
                        ),

                      // Unarchive Button
                      if (widget.taskModel.status == TaskStatusEnum.ARCHIVED)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: UnarchiveButton(
                            routine: routine,
                            taskModel: widget.taskModel,
                          ),
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showResetRoutineProgressDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocaleKeys.ResetRoutineProgress.tr()),
          content: Text(LocaleKeys.ResetRoutineProgressWarning.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetSingleRoutineProgress();
              },
              child: Text(LocaleKeys.Yes.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetSingleRoutineProgress() async {
    try {
      if (widget.taskModel.routineID == null) {
        Helper().getMessage(message: "Bu görev bir rutine ait değil.");
        return;
      }

      final taskProvider = TaskProvider();
      final taskLogProvider = TaskLogProvider();
      final routineId = widget.taskModel.routineID!;
      final today = DateTime.now();

      debugPrint('=== RESETTING SINGLE ROUTINE PROGRESS ===');
      debugPrint('Routine ID: $routineId');

      // Bu rutine ait tüm taskları bul
      final routineTasks = taskProvider.taskList.where((task) => task.routineID == routineId).toList();

      // Geçmiş taskları sil, şimdiki taskları sıfırla
      final tasksToDelete = <TaskModel>[];
      final tasksToReset = <TaskModel>[];

      for (final task in routineTasks) {
        if (task.taskDate != null) {
          final taskDate = task.taskDate!;
          final isPastTask = taskDate.year < today.year || (taskDate.year == today.year && taskDate.month < today.month) || (taskDate.year == today.year && taskDate.month == today.month && taskDate.day < today.day);

          if (isPastTask) {
            tasksToDelete.add(task);
          } else {
            tasksToReset.add(task);
          }
        } else {
          // Tarihsiz taskları sıfırla
          tasksToReset.add(task);
        }
      }

      debugPrint('Tasks to delete: ${tasksToDelete.length}');
      debugPrint('Tasks to reset: ${tasksToReset.length}');

      // Geçmiş routine taskları tamamen sil
      for (final task in tasksToDelete) {
        debugPrint('Deleting past routine task: ${task.title} (ID=${task.id}, Date=${task.taskDate})');
        await HiveService().deleteTask(task.id);
      }

      // Şimdiki routine taskları sıfırla
      for (final task in tasksToReset) {
        debugPrint('Resetting current routine task: ${task.title} (ID=${task.id})');

        // Reset progress values
        if (task.type == TaskTypeEnum.COUNTER) {
          task.currentCount = 0;
        } else if (task.type == TaskTypeEnum.TIMER) {
          task.currentDuration = Duration.zero;
          if (task.isTimerActive == true) {
            task.isTimerActive = false;
            GlobalTimer().startStopTimer(taskModel: task);
          }
        }

        // Reset task status to null
        task.status = null;

        // Update task in storage
        await HiveService().updateTask(task);
      }

      // Bu rutine ait tüm logları sil
      final taskLogBox = await HiveService().getTaskLogs();
      final routineLogIds = <int>[];

      for (final log in taskLogBox) {
        if (log.routineId == routineId) {
          routineLogIds.add(log.id);
        }
      }

      // Routine loglarını Hive'dan sil
      for (final logId in routineLogIds) {
        await HiveService().deleteTaskLog(logId);
      }

      // Provider'dan silinen taskları kaldır
      taskProvider.taskList.removeWhere((task) => tasksToDelete.contains(task));

      // Provider'dan routine loglarını temizle
      taskLogProvider.taskLogList.removeWhere((log) => log.routineId == routineId);

      // Provider'ları güncelle
      taskProvider.updateItems();

      debugPrint('Single routine reset completed. Deleted ${tasksToDelete.length} past tasks, reset ${tasksToReset.length} current tasks, and deleted ${routineLogIds.length} logs.');

      // Success message
      Helper().getMessage(message: "Rutin ilerlemesi başarıyla sıfırlandı. ${tasksToDelete.length} geçmiş görev silindi, ${tasksToReset.length} mevcut görev sıfırlandı.");

      // Sayfayı yenile
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      Helper().getMessage(message: "Hata: $e");
      debugPrint('Error in _resetSingleRoutineProgress: $e');
    }
  }
}
