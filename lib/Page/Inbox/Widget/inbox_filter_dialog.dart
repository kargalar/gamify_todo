import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Inbox/Widget/date_filter_state.dart';
import 'package:next_level/Page/Inbox/Widget/filter_chip_widget.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class InboxFilterDialog extends StatefulWidget {
  final bool showRoutines;
  final bool showTasks;
  final DateFilterState dateFilterState;
  final Set<TaskTypeEnum> selectedTaskTypes;
  final Set<TaskStatusEnum> selectedStatuses;
  final bool showEmptyStatus;
  final Function(bool, bool, DateFilterState, Set<TaskTypeEnum>, Set<TaskStatusEnum>, bool) onFiltersChanged;

  const InboxFilterDialog({
    super.key,
    required this.showRoutines,
    required this.showTasks,
    required this.dateFilterState,
    required this.selectedTaskTypes,
    required this.selectedStatuses,
    required this.showEmptyStatus,
    required this.onFiltersChanged,
  });

  @override
  State<InboxFilterDialog> createState() => _InboxFilterDialogState();
}

class _InboxFilterDialogState extends State<InboxFilterDialog> {
  late bool _showRoutines;
  late bool _showTasks;
  late DateFilterState _dateFilterState;
  late Set<TaskTypeEnum> _selectedTaskTypes;
  late Set<TaskStatusEnum> _selectedStatuses;
  late bool _showEmptyStatus;

  @override
  void initState() {
    super.initState();
    _showRoutines = widget.showRoutines;
    _showTasks = widget.showTasks;
    _dateFilterState = widget.dateFilterState;
    _selectedTaskTypes = Set.from(widget.selectedTaskTypes);
    _selectedStatuses = Set.from(widget.selectedStatuses);
    _showEmptyStatus = widget.showEmptyStatus;
  }

  // Get status color based on TaskStatusEnum
  Color _getStatusColor(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.COMPLETED:
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

  // Get status icon based on TaskStatusEnum
  IconData _getStatusIcon(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.COMPLETED:
        return Icons.check_circle;
      case TaskStatusEnum.FAILED:
        return Icons.cancel;
      case TaskStatusEnum.CANCEL:
        return Icons.block;
      case TaskStatusEnum.ARCHIVED:
        return Icons.archive_outlined;
      case TaskStatusEnum.OVERDUE:
        return Icons.schedule;
    }
  }

  // Get status label based on TaskStatusEnum
  String _getStatusLabel(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.COMPLETED:
        return LocaleKeys.Completed.tr();
      case TaskStatusEnum.FAILED:
        return LocaleKeys.Failed.tr();
      case TaskStatusEnum.CANCEL:
        return LocaleKeys.Cancel.tr();
      case TaskStatusEnum.ARCHIVED:
        return "Archived";
      case TaskStatusEnum.OVERDUE:
        return "Overdue"; // TODO: Add to localization
    }
  }

  void _updateFilters() {
    widget.onFiltersChanged(
      _showRoutines,
      _showTasks,
      _dateFilterState,
      _selectedTaskTypes,
      _selectedStatuses,
      _showEmptyStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: const Border(
          top: BorderSide(color: AppColors.white, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleKeys.Filters.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                color: AppColors.text,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date filter section
          _buildSectionTitle("Date Filter"),
          Row(
            children: [
              FilterChipWidget(
                label: "All Tasks",
                icon: Icons.calendar_view_month_rounded,
                isSelected: _dateFilterState == DateFilterState.all,
                selectedColor: AppColors.main,
                onTap: () {
                  setState(() => _dateFilterState = DateFilterState.all);
                  _updateFilters();
                },
              ),
              const SizedBox(width: 8),
              FilterChipWidget(
                label: "With Date",
                icon: Icons.event_rounded,
                isSelected: _dateFilterState == DateFilterState.withDate,
                selectedColor: AppColors.green,
                onTap: () {
                  setState(() => _dateFilterState = DateFilterState.withDate);
                  _updateFilters();
                },
              ),
              const SizedBox(width: 8),
              FilterChipWidget(
                label: "No Date",
                icon: Icons.event_busy_rounded,
                isSelected: _dateFilterState == DateFilterState.withoutDate,
                selectedColor: AppColors.red,
                onTap: () {
                  setState(() => _dateFilterState = DateFilterState.withoutDate);
                  _updateFilters();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Task/Routine filter section
          _buildSectionTitle("Task Type"),
          Row(
            children: [
              FilterChipWidget(
                label: "Tasks",
                icon: Icons.task_alt_rounded,
                isSelected: _showTasks,
                selectedColor: AppColors.main,
                onTap: () {
                  setState(() {
                    _showTasks = !_showTasks;
                    if (!_showTasks && !_showRoutines) _showRoutines = true;
                  });
                  _updateFilters();
                },
              ),
              const SizedBox(width: 8),
              FilterChipWidget(
                label: "Routines",
                icon: Icons.repeat_rounded,
                isSelected: _showRoutines,
                selectedColor: AppColors.purple,
                onTap: () {
                  setState(() {
                    _showRoutines = !_showRoutines;
                    if (!_showRoutines && !_showTasks) _showTasks = true;
                  });
                  _updateFilters();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Task format filter section
          _buildSectionTitle("Task Format"),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChipWidget(
                label: "Checkbox",
                icon: Icons.check_box_rounded,
                isSelected: _selectedTaskTypes.contains(TaskTypeEnum.CHECKBOX),
                selectedColor: AppColors.green,
                onTap: () => _toggleTaskType(TaskTypeEnum.CHECKBOX),
              ),
              FilterChipWidget(
                label: "Counter",
                icon: Icons.add_circle_outline_rounded,
                isSelected: _selectedTaskTypes.contains(TaskTypeEnum.COUNTER),
                selectedColor: AppColors.main,
                onTap: () => _toggleTaskType(TaskTypeEnum.COUNTER),
              ),
              FilterChipWidget(
                label: "Timer",
                icon: Icons.timer_rounded,
                isSelected: _selectedTaskTypes.contains(TaskTypeEnum.TIMER),
                selectedColor: AppColors.purple,
                onTap: () => _toggleTaskType(TaskTypeEnum.TIMER),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status filter section
          _buildSectionTitle("Status"),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Empty chip for tasks with null status
              FilterChipWidget(
                label: "Empty",
                icon: Icons.radio_button_unchecked,
                isSelected: _showEmptyStatus,
                selectedColor: AppColors.yellow,
                onTap: () {
                  setState(() => _showEmptyStatus = !_showEmptyStatus);
                  _updateFilters();
                },
              ),
              // Status chips with colors and icons
              ...TaskStatusEnum.values.map((status) {
                return FilterChipWidget(
                  label: _getStatusLabel(status),
                  icon: _getStatusIcon(status),
                  isSelected: _selectedStatuses.contains(status),
                  selectedColor: _getStatusColor(status),
                  onTap: () => _toggleStatus(status),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Add extra space at the bottom for devices with notches
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.text.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  void _toggleTaskType(TaskTypeEnum type) {
    setState(() {
      if (_selectedTaskTypes.contains(type)) {
        _selectedTaskTypes.remove(type);
        if (_selectedTaskTypes.isEmpty) _selectedTaskTypes.add(type);
      } else {
        _selectedTaskTypes.add(type);
      }
    });
    _updateFilters();
  }

  void _toggleStatus(TaskStatusEnum status) {
    setState(() {
      if (_selectedStatuses.contains(status)) {
        _selectedStatuses.remove(status);
      } else {
        _selectedStatuses.add(status);
      }
    });
    _updateFilters();
  }
}
