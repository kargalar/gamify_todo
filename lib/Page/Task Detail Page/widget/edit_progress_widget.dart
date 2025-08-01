import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel.isTask) {
      // Timer aktifse periyodik olarak güncelle
      if (widget.taskModel!.type == TaskTypeEnum.TIMER && widget.taskModel!.isTimerActive == true) {
        // Her saniye güncelle
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _viewModel.updateProgressFromLogs();
          }
        });
      }

      // Sayfa yüklendiğinde logları güncelle
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
