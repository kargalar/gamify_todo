import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/Enums/status_enum.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Service/navigator_service.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Provider/task_log_provider.dart';
import 'package:gamify_todo/Provider/trait_provider.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Enum/trait_type_enum.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Model/trait_model.dart';
import 'package:gamify_todo/Model/task_log_model.dart';
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

  void calculateTotalDurationFromLogs() {
    // Tüm logları al
    List<TaskLogModel> allLogs = TaskLogProvider().taskLogList;

    // Tüm taskları al
    List<TaskModel> allTasks = TaskProvider().taskList;

    // Trait ile ilgili taskları bul
    List<TaskModel> tasksWithTrait = allTasks.where((task) {
      return (task.attributeIDList?.contains(widget.traitModel.id) ?? false) || (task.skillIDList?.contains(widget.traitModel.id) ?? false);
    }).toList();

    // Toplam süreyi hesapla
    totalDuration = Duration.zero;

    // Her task için logları bul ve süreleri topla
    for (var task in tasksWithTrait) {
      // Bu task için logları bul
      List<TaskLogModel> taskLogs = allLogs.where((log) => log.taskId == task.id).toList();

      // Tamamlanmış loglar için süreyi hesapla
      for (var log in taskLogs) {
        if (log.status == TaskStatusEnum.COMPLETED) {
          if (task.type == TaskTypeEnum.TIMER && log.duration != null) {
            totalDuration += log.duration!;
          } else if (task.type == TaskTypeEnum.COUNTER && log.count != null) {
            totalDuration += (task.remainingDuration ?? Duration.zero) * log.count!;
          } else if (task.type == TaskTypeEnum.CHECKBOX) {
            totalDuration += task.remainingDuration ?? Duration.zero;
          }
        }
      }
    }
  }

  void findRelatedTasks() {
    // Tüm taskları al
    List<TaskModel> allTasks = TaskProvider().taskList;

    // Tüm logları al
    List<TaskLogModel> allLogs = TaskLogProvider().taskLogList;

    // Trait ile ilgili taskları bul
    for (var task in allTasks) {
      bool hasThisTrait = (task.attributeIDList?.contains(widget.traitModel.id) ?? false) || (task.skillIDList?.contains(widget.traitModel.id) ?? false);

      if (hasThisTrait) {
        // Bu task için logları bul
        List<TaskLogModel> taskLogs = allLogs.where((log) => log.taskId == task.id).toList();

        // Toplam süreyi hesapla
        Duration taskDuration = Duration.zero;

        for (var log in taskLogs) {
          if (log.status == TaskStatusEnum.COMPLETED) {
            if (task.type == TaskTypeEnum.TIMER && log.duration != null) {
              taskDuration += log.duration!;
            } else if (task.type == TaskTypeEnum.COUNTER && log.count != null) {
              taskDuration += (task.remainingDuration ?? Duration.zero) * log.count!;
            } else if (task.type == TaskTypeEnum.CHECKBOX) {
              taskDuration += task.remainingDuration ?? Duration.zero;
            }
          }
        }

        // Süresi 0'dan büyük olanları listelere ekle
        if (taskDuration > Duration.zero) {
          if (task.routineID != null) {
            relatedRoutines.add(task);
          } else {
            relatedTasks.add(task);
          }
        }
      }
    }

    // Süreye göre sırala (büyükten küçüğe)
    relatedTasks.sort((a, b) {
      Duration aDuration = calculateTaskDuration(a);
      Duration bDuration = calculateTaskDuration(b);
      return bDuration.compareTo(aDuration);
    });

    relatedRoutines.sort((a, b) {
      Duration aDuration = calculateTaskDuration(a);
      Duration bDuration = calculateTaskDuration(b);
      return bDuration.compareTo(aDuration);
    });
  }

  Duration calculateTaskDuration(TaskModel task) {
    // Tüm logları al
    List<TaskLogModel> allLogs = TaskLogProvider().taskLogList;

    // Bu task için logları bul
    List<TaskLogModel> taskLogs = allLogs.where((log) => log.taskId == task.id).toList();

    // Toplam süreyi hesapla
    Duration taskDuration = Duration.zero;

    for (var log in taskLogs) {
      if (log.status == TaskStatusEnum.COMPLETED) {
        if (task.type == TaskTypeEnum.TIMER && log.duration != null) {
          taskDuration += log.duration!;
        } else if (task.type == TaskTypeEnum.COUNTER && log.count != null) {
          taskDuration += (task.remainingDuration ?? Duration.zero) * log.count!;
        } else if (task.type == TaskTypeEnum.CHECKBOX) {
          taskDuration += task.remainingDuration ?? Duration.zero;
        }
      }
    }

    return taskDuration;
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
        actions: [
          InkWell(
            borderRadius: AppColors.borderRadiusAll,
            onTap: () async {
              if (traitTitleController.text.trim().isEmpty) {
                traitTitleController.clear();
                Helper().getMessage(
                  message: LocaleKeys.NameEmpty.tr(),
                  status: StatusEnum.WARNING,
                );
                return;
              }

              final TraitModel updatedTrait = TraitModel(
                id: widget.traitModel.id,
                title: traitTitleController.text,
                icon: traitIcon,
                color: selectedColor,
                type: widget.traitModel.type == TraitTypeEnum.SKILL ? TraitTypeEnum.SKILL : TraitTypeEnum.ATTRIBUTE,
              );

              TraitProvider().editTrait(updatedTrait);
              Get.back();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check),
            ),
          ),
        ],
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: "Name",
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
                        const Text(
                          "Related Tasks",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
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
                                        style: const TextStyle(
                                          fontSize: 14,
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
                        ListView.builder(
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
                                        style: const TextStyle(
                                          fontSize: 14,
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
