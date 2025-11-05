import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'task_template_model.g.dart';

@HiveType(typeId: 50)
class TaskTemplateModel extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  TaskTypeEnum type;

  @HiveField(4)
  int priority;

  @HiveField(5)
  Duration? remainingDuration; // timer için hedef süre

  @HiveField(6)
  int? targetCount; // counter için hedef sayı

  @HiveField(7)
  List<int>? attributeIDList; // etki edeceği özellikler

  @HiveField(8)
  List<int>? skillIDList; // etki edecği yetenekler

  @HiveField(9)
  List<SubTaskModel>? subtasks; // alt görevler

  @HiveField(10)
  String? location; // konum bilgisi

  @HiveField(11)
  String? categoryId; // kategori id'si

  @HiveField(12)
  int? earlyReminderMinutes; // erken hatırlatma süresi

  @HiveField(13)
  bool isNotificationOn;

  @HiveField(14)
  bool isAlarmOn;

  @HiveField(15)
  DateTime createdAt; // template'in oluşturulduğu tarih

  @HiveField(16)
  int order; // template'lerin gösterilme sırası

  TaskTemplateModel({
    this.id = 0,
    required this.title,
    this.description,
    required this.type,
    this.priority = 3,
    this.remainingDuration,
    this.targetCount,
    this.attributeIDList,
    this.skillIDList,
    this.subtasks,
    this.location,
    this.categoryId,
    this.earlyReminderMinutes,
    this.isNotificationOn = false,
    this.isAlarmOn = false,
    DateTime? createdAt,
    this.order = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Template'ten bir copy oluştur
  TaskTemplateModel copyWith({
    int? id,
    String? title,
    String? description,
    TaskTypeEnum? type,
    int? priority,
    Duration? remainingDuration,
    int? targetCount,
    List<int>? attributeIDList,
    List<int>? skillIDList,
    List<SubTaskModel>? subtasks,
    String? location,
    String? categoryId,
    int? earlyReminderMinutes,
    bool? isNotificationOn,
    bool? isAlarmOn,
    DateTime? createdAt,
    int? order,
  }) {
    return TaskTemplateModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      targetCount: targetCount ?? this.targetCount,
      attributeIDList: attributeIDList ?? this.attributeIDList,
      skillIDList: skillIDList ?? this.skillIDList,
      subtasks: subtasks ?? this.subtasks,
      location: location ?? this.location,
      categoryId: categoryId ?? this.categoryId,
      earlyReminderMinutes: earlyReminderMinutes ?? this.earlyReminderMinutes,
      isNotificationOn: isNotificationOn ?? this.isNotificationOn,
      isAlarmOn: isAlarmOn ?? this.isAlarmOn,
      createdAt: createdAt ?? this.createdAt,
      order: order ?? this.order,
    );
  }
}
