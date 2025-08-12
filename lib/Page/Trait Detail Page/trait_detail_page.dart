import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:get/route_manager.dart';

class TraitDetailPage extends StatefulWidget {
  const TraitDetailPage({
    super.key,
    required this.traitModel,
  });

  final TraitModel traitModel;

  @override
  State<TraitDetailPage> createState() => _TraitDetailPageState();
}

class _TraitDetailPageState extends State<TraitDetailPage> {
  TextEditingController traitTitleController = TextEditingController();
  String traitIcon = "🎯";
  Color selectedColor = AppColors.main;

  late Duration totalDuration;
  List<TaskModel> relatedTasks = [];
  List<TaskModel> relatedRoutines = [];

  void _saveTraitChanges() {
    if (traitTitleController.text.trim().isEmpty) {
      traitTitleController.text = widget.traitModel.title; // Reset to original if empty
      return;
    }

    final TraitModel updatedTrait = TraitModel(
      id: widget.traitModel.id,
      title: traitTitleController.text.trim(),
      icon: traitIcon,
      color: selectedColor,
      type: widget.traitModel.type,
    );

    TraitProvider().editTrait(updatedTrait);
  }

  void calculateTotalDurationFromLogs() {
    // Tüm taskları al
    List<TaskModel> allTasks = TaskProvider().taskList;

    // Trait ile ilgili taskları bul
    List<TaskModel> tasksWithTrait = allTasks.where((task) {
      return (task.attributeIDList?.contains(widget.traitModel.id) ?? false) || (task.skillIDList?.contains(widget.traitModel.id) ?? false);
    }).toList();

    // Toplam süreyi hesapla - ProfileViewModel'deki yöntemle uyumlu
    totalDuration = tasksWithTrait.fold(
      Duration.zero,
      (previousValue, task) {
        if (task.remainingDuration != null) {
          if (task.type == TaskTypeEnum.CHECKBOX && task.status != TaskStatusEnum.DONE) {
            return previousValue; // Tamamlanmamış checkbox'lar sayılmaz
          }
          return previousValue +
              (task.type == TaskTypeEnum.CHECKBOX
                  ? task.remainingDuration!
                  : task.type == TaskTypeEnum.COUNTER
                      ? task.remainingDuration! * (task.currentCount ?? 0)
                      : task.currentDuration ?? Duration.zero);
        }
        return previousValue;
      },
    );
  }

  void findRelatedTasks() {
    // Tüm taskları al
    List<TaskModel> allTasks = TaskProvider().taskList;

    // Trait ile ilgili taskları bul (sadece progress'i olanları)
    for (var task in allTasks) {
      bool hasThisTrait = (task.attributeIDList?.contains(widget.traitModel.id) ?? false) || (task.skillIDList?.contains(widget.traitModel.id) ?? false);

      if (hasThisTrait) {
        // Sadece progress'i olan task'ları ekle
        Duration taskDuration = calculateTaskDuration(task);
        if (taskDuration > Duration.zero) {
          if (task.routineID != null) {
            relatedRoutines.add(task);
          } else {
            relatedTasks.add(task);
          }
        }
      }
    }

    // Süreye göre sırala (büyükten küçüğe) - süre aynı olanlar için en son tarihe göre sırala
    relatedTasks.sort((a, b) {
      Duration aDuration = calculateTaskDuration(a);
      Duration bDuration = calculateTaskDuration(b);

      // Önce süreye göre sırala
      if (aDuration != bDuration) {
        return bDuration.compareTo(aDuration);
      }

      // Süreler eşitse tarihe göre sırala (en yeni önce)
      if (a.taskDate != null && b.taskDate != null) {
        return b.taskDate!.compareTo(a.taskDate!);
      } else if (a.taskDate != null) {
        return -1;
      } else if (b.taskDate != null) {
        return 1;
      }

      return 0;
    });

    relatedRoutines.sort((a, b) {
      Duration aDuration = calculateTaskDuration(a);
      Duration bDuration = calculateTaskDuration(b);

      // Önce süreye göre sırala
      if (aDuration != bDuration) {
        return bDuration.compareTo(aDuration);
      }

      // Süreler eşitse tarihe göre sırala (en yeni önce)
      if (a.taskDate != null && b.taskDate != null) {
        return b.taskDate!.compareTo(a.taskDate!);
      } else if (a.taskDate != null) {
        return -1;
      } else if (b.taskDate != null) {
        return 1;
      }

      return 0;
    });
  }

  Duration calculateTaskDuration(TaskModel task) {
    // Use the same calculation method as ProfileViewModel for consistency
    if (task.remainingDuration == null) return Duration.zero;

    return task.type == TaskTypeEnum.CHECKBOX
        ? (task.status == TaskStatusEnum.DONE ? task.remainingDuration! : Duration.zero)
        : task.type == TaskTypeEnum.COUNTER
            ? task.remainingDuration! * (task.currentCount ?? 0)
            : task.currentDuration ?? Duration.zero;
  }

  // Helper methods for status display
  Color _getStatusColor(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.DONE:
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

  String _getStatusText(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.DONE:
        return LocaleKeys.Done.tr();
      case TaskStatusEnum.FAILED:
        return LocaleKeys.Failed.tr();
      case TaskStatusEnum.CANCEL:
        return LocaleKeys.Cancelled.tr();
      case TaskStatusEnum.ARCHIVED:
        return LocaleKeys.Archived.tr();
      case TaskStatusEnum.OVERDUE:
        return LocaleKeys.Overdue.tr();
    }
  }

  @override
  void initState() {
    super.initState();

    traitTitleController.text = widget.traitModel.title;
    traitIcon = widget.traitModel.icon;
    selectedColor = widget.traitModel.color;

    // Log verilerine göre trait ile ilgili toplam süreyi hesapla
    calculateTotalDurationFromLogs();

    // İlgili görevleri bul
    findRelatedTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.traitModel.title} Detail',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () => NavigatorService().back(),
          child: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trait Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground2,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: traitTitleController,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (value) {
                              _saveTraitChanges();
                            },
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: LocaleKeys.Name.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.panelBackground2.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            traitIcon = await Helper().showEmojiPicker(context);
                            setState(() {});
                            _saveTraitChanges();
                          },
                          child: Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: selectedColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                traitIcon,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            selectedColor = await Helper().selectColor();
                            setState(() {});
                            _saveTraitChanges();
                          },
                          child: Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Total Duration Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      totalDuration.toLevel(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: selectedColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalDuration.textShort2hour(),
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Related Tasks Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleKeys.RelatedTasks.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        relatedTasks.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.panelBackground2.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  LocaleKeys.NoTasksWithProgressFound.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: relatedTasks.length,
                                itemBuilder: (context, index) {
                                  final TaskModel task = relatedTasks[index];
                                  // Log verilerine göre task süresini hesapla
                                  Duration taskDuration = calculateTaskDuration(task);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: task.status == TaskStatusEnum.ARCHIVED ? AppColors.panelBackground2.withValues(alpha: 0.5) : AppColors.panelBackground2,
                                      borderRadius: BorderRadius.circular(12),
                                      border: task.status == TaskStatusEnum.ARCHIVED ? Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1) : null,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                task.title,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                  color: task.status == TaskStatusEnum.ARCHIVED ? Colors.grey : AppColors.text,
                                                  decoration: task.status == TaskStatusEnum.ARCHIVED ? TextDecoration.lineThrough : TextDecoration.none,
                                                ),
                                              ),
                                            ),
                                            if (task.status != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(task.status!),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  _getStatusText(task.status!),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              task.taskDate != null ? task.taskDate!.toLocal().toString().split(' ')[0] : "No date",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              taskDuration.textShort2hour(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.text,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Related Routines",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        relatedRoutines.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.panelBackground2.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "No routines with progress found",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: relatedRoutines.length,
                                itemBuilder: (context, index) {
                                  final TaskModel task = relatedRoutines[index];
                                  // Log verilerine göre task süresini hesapla
                                  Duration taskDuration = calculateTaskDuration(task);

                                  // Artık task duration hesaplaması calculateTaskDuration metodunda yapılıyor

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.panelBackground2,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              task.taskDate != null ? task.taskDate!.toLocal().toString().split(' ')[0] : "No date",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              taskDuration.textShort2hour(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.text,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Delete Button
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    TraitProvider().removeTrait(widget.traitModel.id);
                    Get.back();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.red.withValues(alpha: 0.9),
                    ),
                    child: Text(
                      LocaleKeys.Delete.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
