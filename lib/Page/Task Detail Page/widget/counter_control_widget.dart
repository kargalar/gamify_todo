import 'package:flutter/material.dart';
import 'package:gamify_todo/Model/task_model.dart';

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
    // Sadece değeri değiştir, log oluşturma işlemini ViewModel'e bırak
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
