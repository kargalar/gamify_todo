import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'task_model.g.dart';

@HiveType(typeId: 2)
class TaskModel extends HiveObject {
  @HiveField(0)
  int id; // id si
  @HiveField(1)
  final int? routineID; // eğer varsa rutin id si
  @HiveField(2)
  String title; // başlığı
  @HiveField(3)
  String? description; // açıklama
  @HiveField(4)
  final TaskTypeEnum type; // türü
  @HiveField(5)
  DateTime? taskDate; // yapılacağı tarih
  @HiveField(6)
  TimeOfDay? time; // saati
  @HiveField(7)
  bool isNotificationOn; // notification açık mı
  @HiveField(8)
  bool isAlarmOn; // notification açık mı
  @HiveField(9)
  Duration? currentDuration; // timer ise süre buradan takip edilecek
  @HiveField(10)
  Duration? remainingDuration; // timer ise hedef süre timer değilse tecrübe puanı buna göre gelecek
  @HiveField(11)
  int? currentCount; // counter ise sayı buradan takip edilecek
  @HiveField(12)
  int? targetCount; // counter ise hedef sayı
  @HiveField(13)
  bool? isTimerActive; // timer aktif mi
  @HiveField(14)
  List<int>? attributeIDList; // etki edeceği özellikler
  @HiveField(15)
  List<int>? skillIDList; // etki edecği yetenekler
  @HiveField(16)
  TaskStatusEnum? status; // tamamlandı mı
  @HiveField(17)
  int priority; // öncelik değeri (1: Yüksek, 2: Orta, 3: Düşük)
  @HiveField(18)
  List<SubTaskModel>? subtasks; // alt görevler
  @HiveField(19)
  String? location; // konum bilgisi
  @HiveField(20)
  int? categoryId; // kategori id'si
  @HiveField(21)
  bool? showSubtasks; // alt görevlerin gösterilip gösterilmeyeceği
  @HiveField(22)
  int? earlyReminderMinutes; // erken hatırlatma süresi (dakika cinsinden)

  TaskModel({
    this.id = 0,
    this.routineID,
    required this.title,
    this.description,
    required this.type,
    this.taskDate,
    this.time,
    required this.isNotificationOn,
    required this.isAlarmOn,
    this.currentDuration,
    this.remainingDuration,
    this.currentCount,
    this.targetCount,
    this.isTimerActive,
    this.attributeIDList,
    this.skillIDList,
    this.status,
    this.priority = 3,
    this.subtasks,
    this.location,
    this.categoryId,
    this.showSubtasks = true,
    this.earlyReminderMinutes,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    Duration stringToDuration(String timeString) {
      List<String> split = timeString.split(':');
      return Duration(hours: int.parse(split[0]), minutes: int.parse(split[1]), seconds: int.parse(split[2]));
    }

    final TaskTypeEnum type = TaskTypeEnum.values.firstWhere((e) => e.toString().split('.').last == json['type']);

    TaskModel taskModel = TaskModel(
      id: json['id'],
      routineID: json['routine_id'],
      title: json['title'],
      description: json['description'],
      type: type,
      taskDate: json['task_date'] != null ? DateTime.parse(json['task_date']) : null,
      time: json['time'] != null ? TimeOfDay.fromDateTime(DateTime.parse("1970-01-01 ${json['time']}")) : null,
      isNotificationOn: json['is_notification_on'],
      isAlarmOn: json['is_alarm_on'],
      currentDuration: json['current_duration'] != null ? stringToDuration(json['current_duration']) : null,
      remainingDuration: json['remaining_duration'] != null ? stringToDuration(json['remaining_duration']) : null,
      currentCount: json['current_count'],
      targetCount: json['target_count'],
      isTimerActive: json['is_timer_active'] ?? (type == TaskTypeEnum.TIMER ? false : null),
      attributeIDList: json['attribute_id_list'] != null ? (json['attribute_id_list'] as List).map((i) => i as int).toList() : null,
      skillIDList: json['skill_id_list'] != null ? (json['skill_id_list'] as List).map((i) => i as int).toList() : null,
      status: json['status'] != null ? TaskStatusEnum.values.firstWhere((e) => e.toString().split('.').last == json['status']) : null,
      priority: json['priority'] ?? 3,
      subtasks: json['subtasks'] != null ? SubTaskModel.fromJsonList(json['subtasks']) : null,
      location: json['location'],
      categoryId: json['category_id'],
      showSubtasks: json['show_subtasks'] ?? true,
      earlyReminderMinutes: json['early_reminder_minutes'],
    );

    return taskModel;
  }

  static List<TaskModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((i) => TaskModel.fromJson(i)).toList();
  }

  Map<String, dynamic> toJson() {
    String durationToString(Duration duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);

      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return {
      'id': id,
      'routine_id': routineID,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'task_date': taskDate?.toIso8601String(),
      'time': time != null ? "${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}:00" : null,
      'is_notification_on': isNotificationOn,
      'is_alarm_on': isAlarmOn,
      'current_duration': currentDuration != null ? durationToString(currentDuration!) : null,
      'remaining_duration': remainingDuration != null ? durationToString(remainingDuration!) : null,
      'current_count': currentCount,
      'target_count': targetCount,
      'attribute_id_list': attributeIDList,
      'skill_id_list': skillIDList,
      'status': status?.toString().split('.').last,
      'priority': priority,
      'is_timer_active': isTimerActive,
      'subtasks': subtasks?.map((subtask) => subtask.toJson()).toList(),
      'location': location,
      'category_id': categoryId,
      'show_subtasks': showSubtasks,
      'early_reminder_minutes': earlyReminderMinutes,
    };
  }
}

extension TaskModelExtension on TaskModel {
  bool checkForThisDate(
    DateTime date, {
    required bool isRoutine,
    required bool isCompleted,
  }) {
    bool isRoutineCheck() {
      return isRoutine ? routineID != null : routineID == null;
    }

    bool isCompletedCheck() {
      return isCompleted ? status == null || (type == TaskTypeEnum.TIMER && isTimerActive == true && isRoutineCheck()) : true;
    }

    return taskDate?.isSameDay(date) == true && isRoutineCheck() && isCompletedCheck();
  }
}
