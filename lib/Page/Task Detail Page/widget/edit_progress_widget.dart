import 'package:flutter/material.dart';
import 'dart:async';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_progress_view_model.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/checkbox_status_widget.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/counter_control_widget.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/duration_control_widget.dart';
import 'package:next_level/Provider/task_log_provider.dart';

class EditProgressWidget extends StatefulWidget {
  final TaskModel? taskModel;
  final ItemModel? itemModel;
  final VoidCallback? onProgressChanged;

  const EditProgressWidget.forTask({
    super.key,
    required TaskModel task,
    this.onProgressChanged,
  })  : taskModel = task,
        itemModel = null;

  const EditProgressWidget.forStoreItem({
    super.key,
    required ItemModel item,
    this.onProgressChanged,
  })  : itemModel = item,
        taskModel = null;

  @override
  State<EditProgressWidget> createState() => _EditProgressWidgetState();
}

class _EditProgressWidgetState extends State<EditProgressWidget> {
  late final TaskProgressViewModel _viewModel;
  Timer? _timerUpdateTimer;
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    _viewModel = TaskProgressViewModel(
      taskModel: widget.taskModel,
      itemModel: widget.itemModel,
      taskLogProvider: TaskLogProvider(),
    );

    // ViewModel'deki değişiklikleri dinle
    _viewModel.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Timer aktifse periyodik güncelleme başlat
    _startTimerUpdateIfNeeded();
  }

  void _startTimerUpdateIfNeeded() {
    if (widget.taskModel != null && widget.taskModel!.type == TaskTypeEnum.TIMER && widget.taskModel!.isTimerActive == true) {
      // Zaten timer varsa kapat
      _timerUpdateTimer?.cancel();
      // Yeni timer başlat (her 500ms)
      _timerUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) {
          _viewModel.updateProgressFromLogs();
        }
      });
    }
  }

  @override
  void didUpdateWidget(EditProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Task değişti ve timer durumu değiştiyse
    if (oldWidget.taskModel?.isTimerActive != widget.taskModel?.isTimerActive) {
      _timerUpdateTimer?.cancel();
      _startTimerUpdateIfNeeded();
    }
  }

  @override
  void dispose() {
    _timerUpdateTimer?.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sayfa yüklendiğinde logları güncelle (sadece ilk defa)
    if (_isFirstBuild && _viewModel.isTask) {
      _isFirstBuild = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _viewModel.updateProgressFromLogs();
      });
    }

    if (_viewModel.type == TaskTypeEnum.CHECKBOX) {
      if (_viewModel.isTask) {
        return CheckboxStatusWidget(
          taskModel: widget.taskModel!,
          onStatusChanged: () => setState(() {}),
          taskLogProvider: _viewModel.taskLogProvider,
        );
      } else {
        return const SizedBox(); // Store item için checkbox gösterme
      }
    } else if (_viewModel.type == TaskTypeEnum.COUNTER) {
      return CounterControlWidget(
        taskModel: _viewModel.isTask ? widget.taskModel : null,
        currentCount: _viewModel.currentCount,
        targetCount: _viewModel.isTask ? widget.taskModel!.targetCount : null,
        onCountChanged: (value, {bool skipLogging = false}) {
          _viewModel.setCount(value, skipLogging: skipLogging);
          if (widget.onProgressChanged != null) {
            widget.onProgressChanged!();
          }
        },
        onBatchCountChanged: (totalChange) {
          _viewModel.setBatchCount(totalChange);
          if (widget.onProgressChanged != null) {
            widget.onProgressChanged!();
          }
        },
        isTask: _viewModel.isTask,
      );
    } else {
      return DurationControlWidget(
        currentDuration: _viewModel.currentDuration,
        targetDuration: _viewModel.targetDuration,
        onDurationChanged: (value, {bool skipLogging = false}) {
          _viewModel.setDuration(value, skipLogging: skipLogging);
          if (widget.onProgressChanged != null) {
            widget.onProgressChanged!();
          }
        },
        onBatchDurationChanged: (totalChange) {
          _viewModel.setBatchDuration(totalChange);
          if (widget.onProgressChanged != null) {
            widget.onProgressChanged!();
          }
        },
        isTask: _viewModel.isTask,
      );
    }
  }
}
