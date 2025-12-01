// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/task_template_model.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Page/Home/Widget/task_template_item.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_template_provider.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/task_template_service.dart';
import 'package:provider/provider.dart';

class TaskTemplatesBottomSheet extends StatefulWidget {
  const TaskTemplatesBottomSheet({super.key});

  @override
  State<TaskTemplatesBottomSheet> createState() => _TaskTemplatesBottomSheetState();
}

class _TaskTemplatesBottomSheetState extends State<TaskTemplatesBottomSheet> {
  @override
  void initState() {
    super.initState();
    LogService.debug('📋 TaskTemplatesBottomSheet opened');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskTemplateProvider>(
      builder: (context, templateProvider, _) {
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
            border: const Border(
              top: BorderSide(color: AppColors.dirtyWhite),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                if (templateProvider.templates.isEmpty) _buildEmptyState(context) else _buildTemplatesList(context, templateProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Templates',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select a template to create a new task',
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
        FloatingActionButton(
          mini: true,
          backgroundColor: AppColors.main,
          onPressed: () => _createNewTemplate(context),
          tooltip: 'Create new template',
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: AppColors.text.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No templates yet',
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new template to get started',
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _createNewTemplate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.main,
              ),
              child: const Text('Create Template'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesList(BuildContext context, TaskTemplateProvider provider) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: ReorderableListView(
        onReorder: (oldIndex, newIndex) async {
          LogService.debug('📑 Template reordered from $oldIndex to $newIndex');
          setState(() {
            // Flutter's onReorder has a quirk: when dragging down, newIndex is already adjusted
            // So we need to check if we're dragging down (newIndex > oldIndex)
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final template = provider.templates.removeAt(oldIndex);
            provider.templates.insert(newIndex, template);
          });

          // Order'ı database'e kaydet
          try {
            await TaskTemplateService.updateTemplatesOrder(provider.templates);
            LogService.debug('✅ Order saved to database');
          } catch (e) {
            LogService.error('❌ Failed to save order: $e');
          }
        },
        proxyDecorator: (child, index, animation) {
          // Remove gray overlay - just return the child with opacity
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final double animValue = Curves.easeInOut.transform(animation.value);
              final double elevation = lerpDouble(0, 6, animValue)!;
              return Material(
                elevation: elevation,
                color: Colors.transparent,
                shadowColor: Colors.transparent,
                child: child,
              );
            },
            child: child,
          );
        },
        children: List.generate(
          provider.templates.length,
          (index) {
            final template = provider.templates[index];
            return Container(
              key: ValueKey(template.id),
              child: TaskTemplateItem(
                template: template,
                onTap: () => _createTaskFromTemplate(context, template),
                onEditPressed: () => _editTemplate(context, template),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _createTaskFromTemplate(BuildContext context, TaskTemplateModel template) async {
    try {
      LogService.debug('📋 Creating task from template: ${template.title}');

      // Close bottom sheet
      Navigator.of(context).pop();

      // Get selected date from TaskProvider
      final taskProvider = context.read<TaskProvider>();
      final selectedDate = taskProvider.selectedDate;
      final dateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

      // Create task from template
      final task = TaskModel(
        title: template.title,
        description: template.description,
        type: template.type,
        taskDate: dateOnly,
        time: null,
        isNotificationOn: template.isNotificationOn,
        isAlarmOn: template.isAlarmOn,
        priority: template.priority,
        attributeIDList: template.attributeIDList,
        skillIDList: template.skillIDList,
        subtasks: template.subtasks,
        location: template.location,
        categoryId: template.categoryId,
        earlyReminderMinutes: template.earlyReminderMinutes,
        remainingDuration: template.remainingDuration,
        targetCount: template.targetCount,
      );

      // Add task
      await taskProvider.addTask(task);

      LogService.debug('✅ Task created from template: ${template.title}');

      Helper().getMessage(
        message: '✅ Task created: ${template.title}',
        status: StatusEnum.SUCCESS,
      );
    } catch (e) {
      LogService.error('❌ Failed to create task from template: $e');
      Helper().getMessage(
        message: '❌ Failed to create task',
        status: StatusEnum.WARNING,
      );
    }
  }

  Future<void> _editTemplate(BuildContext context, TaskTemplateModel template) async {
    try {
      LogService.debug('✏️ Editing template: ${template.title}');

      Navigator.of(context).pop(); // Close templates sheet

      // Navigate to add task page with edit mode for template
      await NavigatorService().goTo(
        AddTaskPage(isTemplateMode: true, editTask: _templateToTaskModel(template)),
      );
    } catch (e) {
      LogService.error('❌ Failed to edit template: $e');
    }
  }

  /// Converts TaskTemplateModel to TaskModel for editing
  TaskModel _templateToTaskModel(TaskTemplateModel template) {
    return TaskModel(
      id: template.id, // Keep template ID to update it later
      title: template.title,
      description: template.description,
      type: template.type,
      priority: template.priority,
      attributeIDList: template.attributeIDList,
      skillIDList: template.skillIDList,
      subtasks: template.subtasks,
      location: template.location,
      categoryId: template.categoryId,
      earlyReminderMinutes: template.earlyReminderMinutes,
      isNotificationOn: template.isNotificationOn,
      isAlarmOn: template.isAlarmOn,
      remainingDuration: template.remainingDuration,
      targetCount: template.targetCount,
    );
  }

  void _createNewTemplate(BuildContext context) {
    Navigator.of(context).pop(); // Close templates sheet

    // Navigate to add task page with template mode
    NavigatorService().goTo(
      const AddTaskPage(isTemplateMode: true),
    );
  }
}
