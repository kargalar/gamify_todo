import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gamify_todo/Core/Enums/status_enum.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/duraiton_picker.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/notification_status.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/select_date.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/select_days.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/select_priority.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/select_target_count.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/select_task_type.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/select_time.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/select_trait.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/task_description.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/task_name.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Service/navigator_service.dart';
import 'package:gamify_todo/Provider/add_task_provider.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Provider/trait_provider.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Enum/trait_type_enum.dart';
import 'package:gamify_todo/Model/routine_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:provider/provider.dart';
import 'package:gamify_todo/Page/Task%20Detail%20Page/widget/edit_progress_widget.dart';

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
  late final addTaskProvider = context.read<AddTaskProvider>();
  late final taskProvider = context.read<TaskProvider>();

  bool isLoadign = false;

  @override
  void initState() {
    super.initState();

    if (widget.editTask != null) {
      RoutineModel? routine;
      addTaskProvider.editTask = widget.editTask;
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
      addTaskProvider.selectedTime = addTaskProvider.editTask!.time;
      addTaskProvider.selectedDate = addTaskProvider.editTask!.taskDate;
      addTaskProvider.isNotificationOn = addTaskProvider.editTask!.isNotificationOn;
      addTaskProvider.isAlarmOn = addTaskProvider.editTask!.isAlarmOn;
      addTaskProvider.selectedTaskType = addTaskProvider.editTask!.type;
      addTaskProvider.selectedTraits =
          TraitProvider().traitList.where((element) => (addTaskProvider.editTask!.attributeIDList != null && addTaskProvider.editTask!.attributeIDList!.contains(element.id)) || (addTaskProvider.editTask!.skillIDList != null && addTaskProvider.editTask!.skillIDList!.contains(element.id))).toList();
      addTaskProvider.priority = addTaskProvider.editTask!.priority;
    } else {
      addTaskProvider.editTask = null;

      addTaskProvider.taskNameController.clear();
      addTaskProvider.descriptionController.clear();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // didpop kontrolü şunun için var: eğer geri gelme butonuna basarak pop yaparsak false oluyor fonsiyon ile tetiklersek true oluyor. hata bu sayede düzeltildi. debuglock falan yazıyordu.
        if (!didPop) goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(addTaskProvider.editTask != null
              ? LocaleKeys.EditTask.tr()
              : addTaskProvider.editTask != null && addTaskProvider.editTask!.routineID != null
                  ? LocaleKeys.EditRoutine.tr()
                  : LocaleKeys.AddTask.tr()),
          leading: InkWell(
            borderRadius: AppColors.borderRadiusAll,
            onTap: () {
              goBack();
            },
            child: const Icon(Icons.arrow_back_ios),
          ),
          actions: [
            if (addTaskProvider.editTask == null)
              TextButton(
                onPressed: addTask,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                if (addTaskProvider.editTask != null && addTaskProvider.editTask!.routineID == null) ...[
                  const SizedBox(height: 10),
                  EditProgressWidget.forTask(task: addTaskProvider.editTask!),
                ],
                const SizedBox(height: 10),
                TaskName(autoFocus: addTaskProvider.editTask == null),
                const SizedBox(height: 5),
                const TaskDescription(),
                const SizedBox(height: 10),
                const SelectPriority(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (addTaskProvider.editTask == null)
                      const Expanded(
                        child: SelectDate(),
                      ),
                    SizedBox(
                      width: 0.35.sw,
                      child: const Column(
                        children: [
                          SelectTime(),
                          SizedBox(height: 5),
                          NotificationStatus(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const DurationPickerWidget(),
                    if (addTaskProvider.editTask == null) const SelectTaskType(),
                    if (addTaskProvider.editTask != null && addTaskProvider.selectedTaskType == TaskTypeEnum.COUNTER)
                      const Column(
                        children: [
                          // TODO: localization
                          Text("Target Count"),
                          SelectTargetCount(),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (addTaskProvider.editTask != null ? addTaskProvider.editTask!.routineID != null : true) const SelectDays(),
                const SizedBox(height: 10),
                const SelectTraitList(isSkill: false),
                const SizedBox(height: 10),
                const SelectTraitList(isSkill: true),
                const SizedBox(height: 50),
                if (addTaskProvider.editTask != null)
                  InkWell(
                    borderRadius: AppColors.borderRadiusAll,
                    onTap: () {
                      Helper().getDialog(
                          message: "Are you sure delete?",
                          onAccept: () {
                            if (addTaskProvider.editTask != null && addTaskProvider.editTask!.routineID == null) {
                              taskProvider.deleteTask(addTaskProvider.editTask!);
                            } else {
                              taskProvider.deleteRoutine(addTaskProvider.editTask!.routineID!);
                            }

                            NavigatorService().goBackNavbar();
                          });
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void addTask() async {
    if (addTaskProvider.taskNameController.text.trim().isEmpty) {
      addTaskProvider.taskNameController.clear();

      Helper().getMessage(
        message: LocaleKeys.TraitNameEmpty.tr(),
        status: StatusEnum.WARNING,
      );
      return;
    }

    if (addTaskProvider.selectedDays.isNotEmpty && addTaskProvider.selectedDate.isBeforeDay(DateTime.now())) {
      Helper().getMessage(
        message: LocaleKeys.RoutineStartDateError.tr(),
        status: StatusEnum.WARNING,
      );
      return;
    }

    if (isLoadign) return;

    isLoadign = true;

    if (addTaskProvider.selectedDays.isEmpty) {
      taskProvider.addTask(
        TaskModel(
          title: addTaskProvider.taskNameController.text,
          description: addTaskProvider.descriptionController.text.trim().isEmpty ? null : addTaskProvider.descriptionController.text,
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
        ),
      );
    } else {
      await taskProvider.addRoutine(
        RoutineModel(
          title: addTaskProvider.taskNameController.text,
          description: addTaskProvider.descriptionController.text.trim().isEmpty ? null : addTaskProvider.descriptionController.text,
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
        ),
      );

      if (addTaskProvider.selectedDays.contains(DateTime.now().weekday - 1) && addTaskProvider.selectedDate.isBeforeOrSameDay(DateTime.now())) {
        taskProvider.addTask(
          TaskModel(
            title: addTaskProvider.taskNameController.text,
            description: addTaskProvider.descriptionController.text.trim().isEmpty ? null : addTaskProvider.descriptionController.text,
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
          ),
        );
      } else {
        taskProvider.updateItems();
      }
    }

    NavigatorService().goBackNavbar();
  }

  void goBack() {
    if (addTaskProvider.editTask != null) {
      if (addTaskProvider.taskNameController.text.trim().isEmpty) {
        addTaskProvider.taskNameController.clear();

        Helper().getMessage(
          message: LocaleKeys.TraitNameEmpty.tr(),
          status: StatusEnum.WARNING,
        );
        return;
      }

      if (addTaskProvider.editTask == null && addTaskProvider.selectedDays.isNotEmpty && addTaskProvider.selectedDate.isBeforeDay(DateTime.now())) {
        Helper().getMessage(
          message: LocaleKeys.RoutineStartDateError.tr(),
          status: StatusEnum.WARNING,
        );
        return;
      }

      if (isLoadign) return;

      isLoadign = true;

      TaskProvider().editTask(
        selectedDays: addTaskProvider.selectedDays,
        taskModel: TaskModel(
          id: addTaskProvider.editTask!.id,
          routineID: addTaskProvider.editTask!.routineID,
          title: addTaskProvider.taskNameController.text,
          description: addTaskProvider.descriptionController.text.trim().isEmpty ? null : addTaskProvider.descriptionController.text,
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
        ),
      );

      NavigatorService().back();
    } else {
      NavigatorService().back();
    }
  }
}
