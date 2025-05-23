import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class DurationControlWidget extends StatefulWidget {
  final Duration? currentDuration;
  final Duration? targetDuration;
  final Function(Duration) onDurationChanged;
  final bool isTask;

  const DurationControlWidget({
    super.key,
    required this.currentDuration,
    this.targetDuration,
    required this.onDurationChanged,
    required this.isTask,
  });

  @override
  State<DurationControlWidget> createState() => _DurationControlWidgetState();
}

class _DurationControlWidgetState extends State<DurationControlWidget> {
  bool _isIncrementing = false;
  bool _isDecrementing = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDurationControl(
          label: LocaleKeys.Hour.tr(),
          value: (widget.currentDuration?.isNegative ?? false) ? -((-widget.currentDuration!.inHours) % 24) : widget.currentDuration?.inHours ?? 0,
          onIncrease: () {
            widget.onDurationChanged((widget.currentDuration ?? Duration.zero) + const Duration(hours: 1));
          },
          onDecrease: () {
            if ((widget.currentDuration?.inHours ?? 0) > 0 || !widget.isTask) {
              widget.onDurationChanged((widget.currentDuration ?? Duration.zero) - const Duration(hours: 1));
            }
          },
        ),
        const SizedBox(width: 16),
        _buildDurationControl(
          label: LocaleKeys.Minute.tr(),
          value: (widget.currentDuration?.isNegative ?? false) ? -((-widget.currentDuration!.inMinutes) % 60) : (widget.currentDuration?.inMinutes ?? 0) % 60,
          onIncrease: () {
            widget.onDurationChanged((widget.currentDuration ?? Duration.zero) + const Duration(minutes: 1));
          },
          onDecrease: () {
            if ((widget.currentDuration?.inMinutes ?? 0) > 0 || !widget.isTask) {
              widget.onDurationChanged((widget.currentDuration ?? Duration.zero) - const Duration(minutes: 1));
            }
          },
        ),
        const SizedBox(width: 16),
        _buildDurationControl(
          label: LocaleKeys.Second.tr(),
          value: (widget.currentDuration?.isNegative ?? false) ? -((-widget.currentDuration!.inSeconds) % 60) : (widget.currentDuration?.inSeconds ?? 0) % 60,
          onIncrease: () {
            widget.onDurationChanged((widget.currentDuration ?? Duration.zero) + const Duration(seconds: 1));
          },
          onDecrease: () {
            if ((widget.currentDuration?.inSeconds ?? 0) > 0 || !widget.isTask) {
              widget.onDurationChanged((widget.currentDuration ?? Duration.zero) - const Duration(seconds: 1));
            }
          },
        ),
        if (widget.isTask && widget.targetDuration != null) ...[
          const SizedBox(width: 16),
          Text(
            "/ ${widget.targetDuration?.toString().split('.').first ?? "0"}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDurationControl({
    required String label,
    required int value,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onIncrease,
          onLongPressStart: (_) async {
            _isIncrementing = true;
            while (_isIncrementing && mounted) {
              onIncrease();
              await Future.delayed(const Duration(milliseconds: 60));
            }
          },
          onLongPressEnd: (_) {
            _isIncrementing = false;
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.keyboard_arrow_up, size: 24),
          ),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: onDecrease,
          onLongPressStart: (_) async {
            _isDecrementing = true;
            while (_isDecrementing && mounted) {
              onDecrease();
              await Future.delayed(const Duration(milliseconds: 60));
            }
          },
          onLongPressEnd: (_) {
            _isDecrementing = false;
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.keyboard_arrow_down, size: 24),
          ),
        ),
      ],
    );
  }
}
