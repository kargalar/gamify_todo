import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/compact_task_options_vertical.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/compact_trait_options.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/enhanced_subtask_section.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/duraiton_picker.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/date_time_notification_widget.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/select_days.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/select_target_count.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/select_task_type.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/task_name.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/recent_logs_widget.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Enum/trait_type_enum.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/edit_progress_widget.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/file_attachment_widget.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({
    super.key,
    this.editTask,
  });

  final TaskModel? editTask;

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  // Use read for init but watch inside build for reactive UI
  late final addTaskProvider = context.read<AddTaskProvider>();
  late final taskProvider = context.read<TaskProvider>();
  TaskDetailViewModel? _taskDetailViewModel;

  bool isLoadign = false;

  @override
  void initState() {
    super.initState();

    if (widget.editTask != null) {
      RoutineModel? routine;
      addTaskProvider.editTask = widget.editTask;

      // Initialize the TaskDetailViewModel for the edit task
      _taskDetailViewModel = TaskDetailViewModel(widget.editTask!);
      _taskDetailViewModel!.initialize();
      if (addTaskProvider.editTask!.routineID != null) {
        routine = taskProvider.routineList.firstWhere((element) => element.id == widget.editTask!.routineID);

        addTaskProvider.targetCount = routine.targetCount ?? 1;
        addTaskProvider.taskDuration = routine.remainingDuration ?? const Duration(hours: 0, minutes: 0);
        addTaskProvider.selectedDays = routine.repeatDays;
      } else {
        addTaskProvider.targetCount = addTaskProvider.editTask!.targetCount ?? 1;
        addTaskProvider.taskDuration = addTaskProvider.editTask!.remainingDuration ?? const Duration(hours: 0, minutes: 0);
        addTaskProvider.selectedDays = [];
      }

      addTaskProvider.taskNameController.text = addTaskProvider.editTask!.title;
      addTaskProvider.descriptionController.text = addTaskProvider.editTask!.description ?? '';
      addTaskProvider.locationController.text = addTaskProvider.editTask!.location ?? '';
      addTaskProvider.selectedTime = addTaskProvider.editTask!.time;
      addTaskProvider.selectedDate = addTaskProvider.editTask!.taskDate;
      addTaskProvider.isNotificationOn = addTaskProvider.editTask!.isNotificationOn;
      addTaskProvider.isAlarmOn = addTaskProvider.editTask!.isAlarmOn;
      addTaskProvider.selectedTaskType = addTaskProvider.editTask!.type;
      addTaskProvider.selectedTraits =
          TraitProvider().traitList.where((element) => (addTaskProvider.editTask!.attributeIDList != null && addTaskProvider.editTask!.attributeIDList!.contains(element.id)) || (addTaskProvider.editTask!.skillIDList != null && addTaskProvider.editTask!.skillIDList!.contains(element.id))).toList();
      addTaskProvider.priority = addTaskProvider.editTask!.priority;
      addTaskProvider.categoryId = addTaskProvider.editTask!.categoryId;
      addTaskProvider.earlyReminderMinutes = addTaskProvider.editTask!.earlyReminderMinutes;
      addTaskProvider.loadSubtasksFromTask(addTaskProvider.editTask!);
      addTaskProvider.loadAttachmentsFromTask(addTaskProvider.editTask!);
    } else {
      addTaskProvider.editTask = null;

      addTaskProvider.taskNameController.clear();
      addTaskProvider.descriptionController.clear();
      addTaskProvider.locationController.clear();
      addTaskProvider.selectedTime = null;
      addTaskProvider.selectedDate = context.read<TaskProvider>().selectedDate;
      addTaskProvider.isNotificationOn = false;
      addTaskProvider.isAlarmOn = false;
      addTaskProvider.targetCount = 1;
      addTaskProvider.taskDuration = const Duration(hours: 0, minutes: 0);
      addTaskProvider.selectedTaskType = TaskTypeEnum.CHECKBOX;
      addTaskProvider.selectedDays.clear();
      addTaskProvider.selectedTraits.clear();
      addTaskProvider.priority = 3;
      addTaskProvider.categoryId = null;
      addTaskProvider.clearSubtasks();
      addTaskProvider.clearAttachments();
    }
  }

  // We don't need to explicitly dispose focus nodes here
  // The provider will handle it in its own dispose method

  @override
  void dispose() {
    // Clean up the TaskDetailViewModel
    if (_taskDetailViewModel != null) {
      _taskDetailViewModel!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider for task type / target count reactive sections
    final watchedAddTaskProvider = context.watch<AddTaskProvider>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // didpop kontrolü şunun için var: eğer geri gelme butonuna basarak pop yaparsak false oluyor fonsiyon ile tetiklersek true oluyor. hata bu sayede düzeltildi. debuglock falan yazıyordu.
        if (!didPop) goBack();
      },
      child: GestureDetector(
        // Unfocus when tapping outside of text fields
        onTap: () {
          // Unfocus all text fields including subtask field
          addTaskProvider.unfocusAll();

          // Find and unfocus all fields in the current focus scope
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text(
              addTaskProvider.editTask != null
                  ? LocaleKeys.EditTask.tr()
                  : addTaskProvider.editTask != null && addTaskProvider.editTask!.routineID != null
                      ? LocaleKeys.EditRoutine.tr()
                      : LocaleKeys.AddTask.tr(),
            ),
            leading: InkWell(
              borderRadius: AppColors.borderRadiusAll,
              onTap: () {
                // Unfocus before going back
                addTaskProvider.unfocusAll();
                FocusScope.of(context).unfocus();
                goBack();
              },
              child: const Icon(Icons.arrow_back_ios),
            ),
            actions: [
              if (addTaskProvider.editTask == null)
                TextButton(
                  onPressed: () {
                    // Unfocus before saving
                    addTaskProvider.unfocusAll();
                    FocusScope.of(context).unfocus();
                    addTask();
                  },
                  child: Text(
                    LocaleKeys.Save.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            // Add keyboard dismiss behavior
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    if (addTaskProvider.editTask != null && addTaskProvider.editTask!.routineID == null) ...[
                      const SizedBox(height: 10),
                      EditProgressWidget.forTask(task: addTaskProvider.editTask!),
                    ],
                    const SizedBox(height: 10), // Combined Task Name and Description in a simpler way
                    TaskName(
                      autoFocus: addTaskProvider.editTask == null,
                      onTaskSubmit: addTaskProvider.editTask == null ? addTask : null,
                    ),
                    const SizedBox(height: 10),
                    // Enhanced Subtask Section
                    const EnhancedSubtaskSection(),
                    const SizedBox(height: 10),
                    // Combined Date, Time & Notification widget
                    const DateTimeNotificationWidget(),
                    const SizedBox(height: 10),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Duration picker on the left (takes less space)
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              DurationPickerWidget(),
                            ],
                          ),
                        ),

                        SizedBox(width: 10),

                        // Compact task options on the right (Location, Priority, Category)
                        Expanded(
                          flex: 3,
                          child: CompactTaskOptionsVertical(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (addTaskProvider.editTask == null) const SelectTaskType(),
                    // Show target count widget whenever selected type is COUNTER (both new and edit)
                    if (watchedAddTaskProvider.selectedTaskType == TaskTypeEnum.COUNTER) const SizedBox(height: 10),
                    const SelectTargetCount(),
                    const SizedBox(height: 10),
                    const CompactTraitOptions(),
                    const SizedBox(height: 10),
                    // File attachment widget
                    const FileAttachmentWidget(),
                    const SizedBox(height: 10),
                    // Always show repeat days selector; for standalone tasks in edit, selecting days will convert to a routine
                    const SelectDays(),
                    const SizedBox(height: 10),

                    // Add Recent Logs section for edit task
                    if (addTaskProvider.editTask != null && _taskDetailViewModel != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RecentLogsWidget(viewModel: _taskDetailViewModel!),
                          const SizedBox(height: 30),
                        ],
                      ),

                    const SizedBox(height: 20),
                    if (addTaskProvider.editTask != null)
                      InkWell(
                        borderRadius: AppColors.borderRadiusAll,
                        onTap: () async {
                          // Unfocus all fields before showing dialog
                          addTaskProvider.unfocusAll();
                          FocusScope.of(context).unfocus();

                          await Helper().getDialog(
                            message: LocaleKeys.AreYouSureDelete.tr(),
                            onAccept: () async {
                              NavigatorService().goBackNavbar();

                              if (addTaskProvider.editTask != null && addTaskProvider.editTask!.routineID == null) {
                                await taskProvider.deleteTask(addTaskProvider.editTask!.id);
                              } else {
                                await taskProvider.deleteRoutine(addTaskProvider.editTask!.routineID!);
                              }
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: AppColors.borderRadiusAll,
                            color: AppColors.red,
                          ),
                          child: Text(
                            LocaleKeys.Delete.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                  ],
                )),
          ),
        ),
      ),
    );
  }

  void addTask() async {
    addTaskProvider.taskNameController.text = addTaskProvider.taskNameController.text.trim();
    addTaskProvider.descriptionController.text = addTaskProvider.descriptionController.text.trim();
    addTaskProvider.locationController.text = addTaskProvider.locationController.text.trim();
    if (addTaskProvider.taskNameController.text.isEmpty) {
      addTaskProvider.taskNameController.clear();

      Helper().getMessage(
        message: LocaleKeys.TraitNameEmpty.tr(),
        status: StatusEnum.WARNING,
      );
      return;
    }

    // Rutin oluşturulurken tarih seçimi zorunlu
    if (addTaskProvider.selectedDays.isNotEmpty && addTaskProvider.selectedDate == null) {
      Helper().getMessage(
        message: LocaleKeys.RoutineStartDateError.tr(),
        status: StatusEnum.WARNING,
      );
      return;
    }

    // Rutin başlangıç tarihi geçmiş bir tarih olamaz
    if (addTaskProvider.selectedDays.isNotEmpty && addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.isBeforeDay(DateTime.now())) {
      Helper().getMessage(
        message: LocaleKeys.RoutineStartDateError.tr(),
        status: StatusEnum.WARNING,
      );
      return;
    }

    if (isLoadign) return;

    isLoadign = true;

    if (addTaskProvider.selectedDays.isEmpty) {
      await taskProvider.addTask(
        TaskModel(
          title: addTaskProvider.taskNameController.text,
          description: addTaskProvider.descriptionController.text.isEmpty ? null : addTaskProvider.descriptionController.text,
          type: addTaskProvider.selectedTaskType,
          taskDate: addTaskProvider.selectedDate,
          time: addTaskProvider.selectedTime,
          isNotificationOn: addTaskProvider.isNotificationOn,
          isAlarmOn: addTaskProvider.isAlarmOn,
          currentDuration: addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER ? Duration.zero : null,
          remainingDuration: addTaskProvider.taskDuration,
          currentCount: addTaskProvider.selectedTaskType == TaskTypeEnum.COUNTER ? 0 : null,
          targetCount: addTaskProvider.targetCount,
          isTimerActive: addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER ? false : null,
          attributeIDList: addTaskProvider.selectedTraits.where((element) => element.type == TraitTypeEnum.ATTRIBUTE).map((e) => e.id).toList(),
          skillIDList: addTaskProvider.selectedTraits.where((element) => element.type == TraitTypeEnum.SKILL).map((e) => e.id).toList(),
          priority: addTaskProvider.priority,
          subtasks: addTaskProvider.subtasks.isNotEmpty ? List.from(addTaskProvider.subtasks) : null,
          location: addTaskProvider.locationController.text.isEmpty ? null : addTaskProvider.locationController.text,
          categoryId: addTaskProvider.categoryId,
          earlyReminderMinutes: addTaskProvider.earlyReminderMinutes,
          attachmentPaths: addTaskProvider.attachmentPaths.isNotEmpty ? List.from(addTaskProvider.attachmentPaths) : null,
        ),
      );
    } else {
      await taskProvider.addRoutine(
        RoutineModel(
          title: addTaskProvider.taskNameController.text,
          description: addTaskProvider.descriptionController.text.isEmpty ? null : addTaskProvider.descriptionController.text,
          type: addTaskProvider.selectedTaskType,
          createdDate: DateTime.now(),
          startDate: addTaskProvider.selectedDate,
          time: addTaskProvider.selectedTime,
          isNotificationOn: addTaskProvider.isNotificationOn,
          isAlarmOn: addTaskProvider.isAlarmOn,
          remainingDuration: addTaskProvider.taskDuration,
          targetCount: addTaskProvider.targetCount,
          repeatDays: addTaskProvider.selectedDays,
          attirbuteIDList: addTaskProvider.selectedTraits.where((element) => element.type == TraitTypeEnum.ATTRIBUTE).map((e) => e.id).toList(),
          skillIDList: addTaskProvider.selectedTraits.where((element) => element.type == TraitTypeEnum.SKILL).map((e) => e.id).toList(),
          isArchived: false,
          priority: addTaskProvider.priority,
          categoryId: addTaskProvider.categoryId,
          earlyReminderMinutes: addTaskProvider.earlyReminderMinutes,
          subtasks: addTaskProvider.subtasks.isNotEmpty ? List.from(addTaskProvider.subtasks) : null,
        ),
      );

      if (addTaskProvider.selectedDays.contains(DateTime.now().weekday - 1) && addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.isBeforeOrSameDay(DateTime.now())) {
        await taskProvider.addTask(
          TaskModel(
            title: addTaskProvider.taskNameController.text,
            description: addTaskProvider.descriptionController.text.isEmpty ? null : addTaskProvider.descriptionController.text,
            routineID: taskProvider.routineList.last.id,
            type: addTaskProvider.selectedTaskType,
            taskDate: addTaskProvider.selectedDate,
            time: addTaskProvider.selectedTime,
            isNotificationOn: addTaskProvider.isNotificationOn,
            isAlarmOn: addTaskProvider.isAlarmOn,
            currentDuration: addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER ? Duration.zero : null,
            remainingDuration: addTaskProvider.taskDuration,
            currentCount: addTaskProvider.selectedTaskType == TaskTypeEnum.COUNTER ? 0 : null,
            targetCount: addTaskProvider.targetCount,
            isTimerActive: addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER ? false : null,
            attributeIDList: addTaskProvider.selectedTraits.where((element) => element.type == TraitTypeEnum.ATTRIBUTE).map((e) => e.id).toList(),
            skillIDList: addTaskProvider.selectedTraits.where((element) => element.type == TraitTypeEnum.SKILL).map((e) => e.id).toList(),
            priority: addTaskProvider.priority,
            subtasks: addTaskProvider.subtasks.isNotEmpty ? List.from(addTaskProvider.subtasks) : null,
            location: addTaskProvider.locationController.text.isEmpty ? null : addTaskProvider.locationController.text,
            categoryId: addTaskProvider.categoryId,
            earlyReminderMinutes: addTaskProvider.earlyReminderMinutes,
            attachmentPaths: addTaskProvider.attachmentPaths.isNotEmpty ? List.from(addTaskProvider.attachmentPaths) : null,
          ),
        );
      } else {
        taskProvider.updateItems();
      }
    }

    NavigatorService().goBackNavbar();
  }

  Future<void> goBack() async {
    if (addTaskProvider.editTask != null) {
      addTaskProvider.taskNameController.text = addTaskProvider.taskNameController.text.trim();
      addTaskProvider.descriptionController.text = addTaskProvider.descriptionController.text.trim();
      addTaskProvider.locationController.text = addTaskProvider.locationController.text.trim();
      if (addTaskProvider.taskNameController.text.isEmpty) {
        addTaskProvider.taskNameController.clear();

        Helper().getMessage(
          message: LocaleKeys.TraitNameEmpty.tr(),
          status: StatusEnum.WARNING,
        );
        return;
      }

      // Rutin oluşturulurken tarih seçimi zorunlu
      // If converting a standalone task to a routine in edit, a start date is required
      if (addTaskProvider.editTask != null && addTaskProvider.editTask!.routineID == null && addTaskProvider.selectedDays.isNotEmpty && addTaskProvider.selectedDate == null) {
        Helper().getMessage(
          message: "Rutin oluşturmak için başlangıç tarihi seçmelisiniz.",
          status: StatusEnum.WARNING,
        );
        return;
      }

      // Rutin başlangıç tarihi geçmiş bir tarih olamaz
      if (addTaskProvider.editTask != null && addTaskProvider.editTask!.routineID == null && addTaskProvider.selectedDays.isNotEmpty && addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.isBeforeDay(DateTime.now())) {
        Helper().getMessage(
          message: LocaleKeys.RoutineStartDateError.tr(),
          status: StatusEnum.WARNING,
        );
        return;
      }

      if (isLoadign) return;

      isLoadign = true;

      // Find the existing task in the taskList to preserve Hive object identity
      if (addTaskProvider.editTask!.routineID == null) {
        // For standalone tasks, find the task in the list
        final index = taskProvider.taskList.indexWhere((element) => element.id == addTaskProvider.editTask!.id);
        if (index != -1) {
          // Update the existing task model directly to preserve Hive object identity
          TaskModel existingTask = taskProvider.taskList[index];

          // Update all properties
          existingTask.title = addTaskProvider.taskNameController.text;
          existingTask.description = addTaskProvider.descriptionController.text.isEmpty ? null : addTaskProvider.descriptionController.text;
          existingTask.taskDate = addTaskProvider.selectedDate;
          existingTask.time = addTaskProvider.selectedTime;
          existingTask.isNotificationOn = addTaskProvider.isNotificationOn;
          existingTask.isAlarmOn = addTaskProvider.isAlarmOn;
          existingTask.remainingDuration = addTaskProvider.taskDuration;
          existingTask.targetCount = addTaskProvider.targetCount;
          existingTask.attributeIDList = addTaskProvider.selectedTraits.where((element) => element.type == TraitTypeEnum.ATTRIBUTE).map((e) => e.id).toList();
          existingTask.skillIDList = addTaskProvider.selectedTraits.where((element) => element.type == TraitTypeEnum.SKILL).map((e) => e.id).toList();
          existingTask.priority = addTaskProvider.priority;
          existingTask.subtasks = addTaskProvider.subtasks.isNotEmpty ? List.from(addTaskProvider.subtasks) : null;
          existingTask.location = addTaskProvider.locationController.text.isEmpty ? null : addTaskProvider.locationController.text;
          existingTask.categoryId = addTaskProvider.categoryId;
          existingTask.earlyReminderMinutes = addTaskProvider.earlyReminderMinutes;
          existingTask.attachmentPaths = addTaskProvider.attachmentPaths.isNotEmpty ? List.from(addTaskProvider.attachmentPaths) : null;

          // For type-specific properties
          if (addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER) {
            existingTask.currentDuration = addTaskProvider.editTask!.currentDuration ?? const Duration(seconds: 0);
            existingTask.isTimerActive = addTaskProvider.editTask!.isTimerActive;
          } else if (addTaskProvider.selectedTaskType == TaskTypeEnum.COUNTER) {
            existingTask.currentCount = addTaskProvider.editTask!.currentCount ?? 0;
          } // Now call editTask with the updated existing task
          debugPrint('Updating existing task with preserved Hive identity: ID=${existingTask.id}');
          await TaskProvider().editTask(
            selectedDays: addTaskProvider.selectedDays,
            taskModel: existingTask,
          );
        } else {
          debugPrint('ERROR: Task not found in taskList: ID=${addTaskProvider.editTask!.id}');
        }
      } else {
        // For routine tasks, use the original method as it already preserves Hive object identity
        await TaskProvider().editTask(
          selectedDays: addTaskProvider.selectedDays,
          taskModel: TaskModel(
            id: addTaskProvider.editTask!.id,
            routineID: addTaskProvider.editTask!.routineID,
            title: addTaskProvider.taskNameController.text,
            description: addTaskProvider.descriptionController.text.isEmpty ? null : addTaskProvider.descriptionController.text,
            type: addTaskProvider.selectedTaskType,
            taskDate: addTaskProvider.selectedDate,
            time: addTaskProvider.selectedTime,
            isNotificationOn: addTaskProvider.isNotificationOn,
            isAlarmOn: addTaskProvider.isAlarmOn,
            currentDuration: addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER ? addTaskProvider.editTask!.currentDuration ?? const Duration(seconds: 0) : null,
            remainingDuration: addTaskProvider.taskDuration,
            currentCount: addTaskProvider.selectedTaskType == TaskTypeEnum.COUNTER ? addTaskProvider.editTask!.currentCount ?? 0 : null,
            targetCount: addTaskProvider.targetCount,
            isTimerActive: addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER ? addTaskProvider.editTask!.isTimerActive : null,
            attributeIDList: addTaskProvider.selectedTraits.where((element) => element.type == TraitTypeEnum.ATTRIBUTE).map((e) => e.id).toList(),
            skillIDList: addTaskProvider.selectedTraits.where((element) => element.type == TraitTypeEnum.SKILL).map((e) => e.id).toList(),
            status: addTaskProvider.editTask!.status,
            priority: addTaskProvider.priority,
            subtasks: addTaskProvider.subtasks.isNotEmpty ? List.from(addTaskProvider.subtasks) : null,
            location: addTaskProvider.locationController.text.isEmpty ? null : addTaskProvider.locationController.text,
            categoryId: addTaskProvider.categoryId,
            earlyReminderMinutes: addTaskProvider.earlyReminderMinutes,
            attachmentPaths: addTaskProvider.attachmentPaths.isNotEmpty ? List.from(addTaskProvider.attachmentPaths) : null,
          ),
        );
      }

      NavigatorService().back();
    } else {
      // Check for unsaved changes on new task
      final hasUnsaved = addTaskProvider.taskNameController.text.isNotEmpty || addTaskProvider.descriptionController.text.isNotEmpty || addTaskProvider.locationController.text.isNotEmpty || addTaskProvider.selectedDays.isNotEmpty || addTaskProvider.subtasks.isNotEmpty;
      if (hasUnsaved) {
        await Helper().getDialog(
          message: LocaleKeys.UnsavedChangesWarning.tr(),
          onAccept: () {
            NavigatorService().back();
          },
        );
        return;
      }
      NavigatorService().back();
    }
  }
}
