import 'package:flutter/material.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Provider/task_log_provider.dart';
import 'package:gamify_todo/Provider/task_provider.dart';

class CounterControlWidget extends StatefulWidget {
  final TaskModel? taskModel;
  final int currentCount;
  final int? targetCount;
  final Function(int) onCountChanged;
  final bool isTask;

  const CounterControlWidget({
    super.key,
    this.taskModel,
    required this.currentCount,
    this.targetCount,
    required this.onCountChanged,
    required this.isTask,
  });

  @override
  State<CounterControlWidget> createState() => _CounterControlWidgetState();
}

class _CounterControlWidgetState extends State<CounterControlWidget> {
  bool _isIncrementing = false;
  bool _isDecrementing = false;

  void setCount(int value) async {
    // Önceki değeri kaydet
    int previousCount = widget.currentCount;

    if (widget.isTask && widget.taskModel != null) {
      // Değer değiştiyse log oluştur
      bool shouldCreateLog = value != previousCount;

      if (value >= widget.targetCount! && widget.taskModel!.status != TaskStatusEnum.COMPLETED) {
        widget.taskModel!.status = TaskStatusEnum.COMPLETED;
      } else if (value < widget.targetCount! && widget.taskModel!.status == TaskStatusEnum.COMPLETED) {
        widget.taskModel!.status = null;
      }

      // Değer değiştiyse log oluştur
      if (shouldCreateLog) {
        // Değişim miktarını hesapla
        int difference = value - previousCount;

        // Değişim miktarını log olarak kaydet (hem pozitif hem negatif değişimler için)
        if (difference != 0) {
          // TaskProvider'dan seçili tarihi al
          final selectedDate = TaskProvider().selectedDate;

          TaskLogProvider().addTaskLog(
            widget.taskModel!,
            customLogDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, DateTime.now().hour, DateTime.now().minute, DateTime.now().second, DateTime.now().millisecond),
            customCount: difference, // Değişim miktarını logla (pozitif veya negatif)
            customStatus: value >= widget.targetCount! ? TaskStatusEnum.COMPLETED : null,
          );
        }
      }
    }

    widget.onCountChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            if (widget.currentCount > 0 || !widget.isTask) {
              setCount(widget.currentCount - 1);
            }
          },
          onLongPressStart: (_) async {
            _isDecrementing = true;
            while (_isDecrementing && mounted) {
              if (widget.currentCount > 0 || !widget.isTask) {
                setCount(widget.currentCount - 1);
              }
              await Future.delayed(const Duration(milliseconds: 60));
            }
          },
          onLongPressEnd: (_) {
            _isDecrementing = false;
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.remove, size: 30),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          widget.isTask ? "${widget.currentCount} / ${widget.targetCount!}" : "${widget.currentCount}",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            setCount(widget.currentCount + 1);
          },
          onLongPressStart: (_) async {
            _isIncrementing = true;
            while (_isIncrementing && mounted) {
              setCount(widget.currentCount + 1);
              await Future.delayed(const Duration(milliseconds: 60));
            }
          },
          onLongPressEnd: (_) {
            _isIncrementing = false;
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.add, size: 30),
          ),
        ),
      ],
    );
  }
}
