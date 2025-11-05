import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/quick_add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:provider/provider.dart';

// Field components
import 'QuickAddTask/quick_add_task_name_field.dart';
import 'QuickAddTask/quick_add_date_time_field.dart';
import 'QuickAddTask/quick_add_priority_field.dart';
import 'QuickAddTask/quick_add_task_type_field.dart';

class CompactAddTaskBottomSheet extends StatefulWidget {
  const CompactAddTaskBottomSheet({super.key});

  @override
  State<CompactAddTaskBottomSheet> createState() => _CompactAddTaskBottomSheetState();
}

class _CompactAddTaskBottomSheetState extends State<CompactAddTaskBottomSheet> {
  late QuickAddTaskProvider _quickAddProvider;

  @override
  void initState() {
    super.initState();
    _quickAddProvider = context.read<QuickAddTaskProvider>();

    // Initialize default date from TaskProvider
    _quickAddProvider.updateDate(
      context.read<TaskProvider>().selectedDate,
    );

    // Auto focus on task name field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _quickAddProvider.taskNameFocus.requestFocus();
      LogService.debug('🎯 CompactAddTaskBottomSheet: Focused on task name field');
    });
  }

  Future<void> _addTask() async {
    final validation = _quickAddProvider.validateInputs();
    if (validation != null) {
      LogService.error('❌ Validation failed: $validation');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation)),
      );
      return;
    }

    _quickAddProvider.setLoading(true);

    try {
      final taskModel = _quickAddProvider.toTaskModel();
      final taskProvider = context.read<TaskProvider>();

      // Add task
      await taskProvider.addTask(taskModel);

      if (mounted) {
        LogService.debug(
          '✅ CompactAddTaskBottomSheet: Task added successfully - "${taskModel.title}"',
        );

        // Reset form
        _quickAddProvider.reset();

        // Request focus back to task name for quick consecutive task adding
        _quickAddProvider.taskNameFocus.requestFocus();

        _quickAddProvider.setLoading(false);

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocaleKeys.AddTask.tr()}: ${taskModel.title}'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.main.withValues(alpha: 0.9),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _quickAddProvider.setLoading(false);
        LogService.error('❌ CompactAddTaskBottomSheet: Failed to add task - $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to add task'),
            backgroundColor: AppColors.red.withValues(alpha: 0.9),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuickAddTaskProvider>(
      builder: (context, provider, _) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (_, __) {
            LogService.debug('📋 CompactAddTaskBottomSheet closed, resetting form');
            provider.reset();
          },
          child: Container(
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
              border: const Border(
                top: BorderSide(color: AppColors.dirtyWhite),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  _buildHandleBar(),
                  const SizedBox(height: 16),

                  // Task name input field
                  QuickAddTaskNameField(
                    onFieldSubmitted: provider.descriptionFocus,
                  ),
                  const SizedBox(height: 12),

                  // Options row - Date, Priority, Type, Notification
                  _buildOptionsRow(),
                  const SizedBox(height: 16),

                  // Action buttons
                  _buildActionButtons(provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandleBar() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.text.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildOptionsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Date & Time picker
          const QuickAddDateTimeField(),
          const SizedBox(width: 8),

          // Priority picker
          const QuickAddPriorityField(),
          const SizedBox(width: 8),

          // Task type picker (with Counter/Duration options)
          const QuickAddTaskTypeField(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildActionButtons(QuickAddTaskProvider provider) {
    return Row(
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
            onPressed: provider.isLoading ? null : _addTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.main,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: AppColors.main.withValues(alpha: 0.5),
            ),
            child: provider.isLoading
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
    );
  }
}
