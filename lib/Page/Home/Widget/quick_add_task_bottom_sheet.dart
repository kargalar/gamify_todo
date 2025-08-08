import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Core/helper.dart';
import 'package:provider/provider.dart';

class QuickAddTaskBottomSheet extends StatefulWidget {
  const QuickAddTaskBottomSheet({super.key});

  @override
  State<QuickAddTaskBottomSheet> createState() => _QuickAddTaskBottomSheetState();
}

class _QuickAddTaskBottomSheetState extends State<QuickAddTaskBottomSheet> {
  final TextEditingController _taskNameController = TextEditingController();
  final FocusNode _taskNameFocus = FocusNode();
  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Default to today
    _selectedDate = DateTime.now();
    // Auto focus on the text field when the bottom sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskNameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskNameFocus.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selectedDate = await Helper().selectDateWithQuickActions(
      context: context,
      initialDate: _selectedDate,
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  void _addTask() async {
    final taskName = _taskNameController.text.trim();

    if (taskName.isEmpty) {
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final taskProvider = context.read<TaskProvider>();

    // Create a simple task with selected date
    final newTask = TaskModel(
      title: taskName,
      type: TaskTypeEnum.CHECKBOX,
      taskDate: _selectedDate,
      isNotificationOn: false,
      isAlarmOn: false,
      targetCount: 1,
      priority: 3, // Default priority (low)
    );

    // Add the task
    await taskProvider.addTask(newTask);

    setState(() {
      _isLoading = false;
    });

    // Close the bottom sheet
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.dirtyMain,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.text.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Icon(
                Icons.add_task_rounded,
                color: AppColors.main,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                LocaleKeys.AddTask.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Task name input field
          Container(
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.main.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _taskNameController,
              focusNode: _taskNameFocus,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: LocaleKeys.TaskName.tr(),
                hintStyle: TextStyle(
                  color: AppColors.text.withValues(alpha: 0.4),
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: Icon(
                  Icons.task_alt_rounded,
                  color: AppColors.text.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addTask(),
            ),
          ),
          const SizedBox(height: 12),

          // Date selection button (compact)
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.panelBackground.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.main.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.main,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDate != null ? DateFormat('d MMM yyyy').format(_selectedDate!) : 'Select Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.text.withValues(alpha: 0.5),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              // Cancel button
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    LocaleKeys.Cancel.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Add button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.main,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          LocaleKeys.AddTask.tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
