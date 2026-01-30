import 'package:duration_picker/duration_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class LogBottomSheet extends StatefulWidget {
  final TaskTypeEnum type;
  final dynamic initialValue;
  final bool isEdit;

  const LogBottomSheet({
    super.key,
    required this.type,
    this.initialValue,
    this.isEdit = false,
  });

  @override
  State<LogBottomSheet> createState() => _LogBottomSheetState();
}

class _LogBottomSheetState extends State<LogBottomSheet> {
  late dynamic _value;
  late TextEditingController _counterController;

  @override
  void initState() {
    super.initState();
    if (widget.type == TaskTypeEnum.COUNTER) {
      _value = widget.initialValue ?? 0;
      _counterController = TextEditingController(text: _value == 0 && !widget.isEdit ? '' : _value.toString());
      if (_value > 0 && !widget.isEdit) {
        _counterController.text = "+$_value";
      }
    } else {
      _value = widget.initialValue ?? const Duration(minutes: 30);
    }
  }

  @override
  void dispose() {
    if (widget.type == TaskTypeEnum.COUNTER) {
      _counterController.dispose();
    }
    super.dispose();
  }

  void _onSave() {
    if (widget.type == TaskTypeEnum.COUNTER) {
      if (_counterController.text.trim().isEmpty) return;
      try {
        int val = int.parse(_counterController.text.replaceAll('+', ''));
        Navigator.pop(context, val);
      } catch (e) {
        Helper().getMessage(message: LocaleKeys.InvalidFormat.tr(), status: StatusEnum.WARNING);
      }
    } else {
      Navigator.pop(context, _value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isEdit ? LocaleKeys.EditLog.tr() : LocaleKeys.Add.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.type == TaskTypeEnum.COUNTER) _buildCounterInput() else _buildTimerInput(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.main,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              LocaleKeys.Save.tr(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          if (widget.isEdit) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context, 'DELETE'),
              child: Text(
                LocaleKeys.Delete.tr(),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCounterInput() {
    return Column(
      children: [
        TextField(
          controller: _counterController,
          keyboardType: TextInputType.number,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '+1',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.main),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.main, width: 2),
            ),
            filled: true,
            fillColor: AppColors.panelBackground,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _quickAddButton(-1),
            const SizedBox(width: 8),
            _quickAddButton(1),
            const SizedBox(width: 8),
            _quickAddButton(5),
          ],
        ),
      ],
    );
  }

  Widget _quickAddButton(int change) {
    String label = change > 0 ? '+$change' : '$change';
    return ActionChip(
      label: Text(label),
      onPressed: () {
        int current = int.tryParse(_counterController.text.replaceAll('+', '')) ?? 0;
        int newVal = current + change;
        String text = newVal > 0 ? '+$newVal' : '$newVal';
        _counterController.text = text;
        // Move cursor to end
        _counterController.selection = TextSelection.fromPosition(TextPosition(offset: _counterController.text.length));
      },
      backgroundColor: AppColors.panelBackground,
      side: BorderSide.none,
    );
  }

  Widget _buildTimerInput() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: DurationPicker(
            duration: _value,
            baseUnit: BaseUnit.minute,
            onChange: (val) {
              setState(() => _value = val);
            },
            // ignore: deprecated_member_use
            snapToMins: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatDuration(_value),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.main,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    bool negative = d.isNegative;
    Duration absD = d.abs();
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(absD.inMinutes.remainder(60));
    // String twoDigitSeconds = twoDigits(absD.inSeconds.remainder(60));
    return "${negative ? "-" : ""}${twoDigits(absD.inHours)}h ${twoDigitMinutes}m";
  }
}
