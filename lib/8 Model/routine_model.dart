import 'package:flutter/material.dart';
import 'package:gamify_todo/7%20Enum/task_type_enum.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'routine_model.g.dart';

@HiveType(typeId: 4)
class RoutineModel extends HiveObject {
  @HiveField(0)
  int id; // id si
  @HiveField(1)
  String title; // başlığı
  @HiveField(2)
  String? description; // başlığı
  @HiveField(3)
  TaskTypeEnum type; // türü
  @HiveField(4)
  final DateTime createdDate; // oluşturulma tarihi
  @HiveField(5)
  DateTime startDate; // başlama tarihi
  @HiveField(6)
  TimeOfDay? time; // saati
  @HiveField(7)
  bool isNotificationOn; // notification açık mı
  @HiveField(8)
  bool isAlarmOn; // notification açık mı
  @HiveField(9)
  Duration? remainingDuration; // timer ise hedef süre timer değilse tecrübe puanı buna göre gelecek
  @HiveField(10)
  int? targetCount; // counter ise hedef sayı
  @HiveField(11)
  List<int> repeatDays; // tekrar günleri
  @HiveField(12)
  List<int>? attirbuteIDList; // etki edeceği özellikler
  @HiveField(13)
  List<int>? skillIDList; // etki edecği yetenekler
  @HiveField(14)
  bool isArchived; // tamamlandı mı
  @HiveField(15)
  int priority; // öncelik değeri (1: Yüksek, 2: Orta, 3: Düşük)

  RoutineModel({
    this.id = 0,
    required this.title,
    required this.description,
    required this.type,
    required this.createdDate,
    required this.startDate,
    this.time,
    required this.isNotificationOn,
    required this.isAlarmOn,
    this.remainingDuration,
    this.targetCount,
    required this.repeatDays,
    this.attirbuteIDList,
    this.skillIDList,
    required this.isArchived,
    this.priority = 3,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    Duration stringToDuration(String timeString) {
      List<String> split = timeString.split(':');
      return Duration(hours: int.parse(split[0]), minutes: int.parse(split[1]), seconds: int.parse(split[2]));
    }

    TaskTypeEnum type = TaskTypeEnum.values.firstWhere((e) => e.toString().split('.').last == json['type']);

    return RoutineModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: type,
      createdDate: DateTime.parse(json['created_date']),
      startDate: DateTime.parse(json['start_date']),
      time: json['time'] != null ? TimeOfDay.fromDateTime(DateTime.parse("1970-01-01 ${json['time']}")) : null,
      isNotificationOn: json['is_notification_on'],
      isAlarmOn: json['is_alarm_on'],
      remainingDuration: json['remaining_duration'] != null ? stringToDuration(json['remaining_duration']) : null,
      targetCount: json['target_count'],
      repeatDays: (json['repeat_days'] as List).map((e) => int.parse(e.toString())).toList(),
      attirbuteIDList: json['attribute_id_list'] != null ? List<int>.from(json['attribute_id_list']) : null,
      skillIDList: json['skill_id_list'] != null ? List<int>.from(json['skill_id_list']) : null,
      isArchived: json['is_completed'],
      priority: json['priority'] ?? 3,
    );
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
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'created_date': createdDate.toIso8601String(),
      'start_date': startDate.toIso8601String(),
      'time': time != null ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}:00' : null,
      'is_notification_on': isNotificationOn,
      'is_alarm_on': isAlarmOn,
      'remaining_duration': remainingDuration != null ? durationToString(remainingDuration!) : null,
      'target_count': targetCount,
      'repeat_days': repeatDays,
      'attribute_id_list': attirbuteIDList,
      'skill_id_list': skillIDList,
      'is_completed': isArchived,
      'priority': priority,
    };
  }
}
