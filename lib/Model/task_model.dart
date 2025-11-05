import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  late Duration? currentDuration; // timer ise süre buradan takip edilecek
  @HiveField(10)
  late Duration? remainingDuration; // timer ise hedef süre timer değilse tecrübe puanı buna göre gelecek
  @HiveField(11)
  late int? currentCount; // counter ise sayı buradan takip edilecek
  @HiveField(12)
  late int? targetCount; // counter ise hedef sayı
  @HiveField(13)
  late bool? isTimerActive; // timer aktif mi
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
  String? categoryId; // kategori id'si
  @HiveField(21)
  bool? _showSubtasks; // subtask'ları göster/gizle durumu

  // Getter for showSubtasks with default value
  bool get showSubtasks => _showSubtasks ?? true;

  // Setter for showSubtasks
  set showSubtasks(bool value) => _showSubtasks = value;
  @HiveField(22)
  int? earlyReminderMinutes; // erken hatırlatma süresi (dakika cinsinden)
  @HiveField(23)
  List<String>? attachmentPaths; // dosya ekleri yolları
  @HiveField(24)
  bool? _isPinned; // task pinlenmiş mi (nullable for backward compatibility)

  // Getter for isPinned with default value
  bool get isPinned => _isPinned ?? false;

  // Setter for isPinned
  set isPinned(bool value) => _isPinned = value;

  @HiveField(25, defaultValue: 0)
  int sortOrder; // Sıralama için kullanılır (yüksek değer = üstte)

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
    Duration? currentDuration,
    Duration? remainingDuration,
    int? currentCount,
    int? targetCount,
    bool? isTimerActive,
    this.attributeIDList,
    this.skillIDList,
    this.status,
    this.priority = 3,
    this.subtasks,
    this.location,
    this.categoryId,
    bool? showSubtasks,
    this.earlyReminderMinutes,
    this.attachmentPaths,
    bool? isPinned,
    this.sortOrder = 0,
  })  : _showSubtasks = showSubtasks,
        _isPinned = isPinned,
        isTimerActive = type == TaskTypeEnum.TIMER ? (isTimerActive ?? false) : isTimerActive,
        currentDuration = type == TaskTypeEnum.TIMER ? (currentDuration ?? Duration.zero) : currentDuration,
        remainingDuration = type == TaskTypeEnum.TIMER ? (remainingDuration ?? const Duration(minutes: 30)) : remainingDuration,
        currentCount = type == TaskTypeEnum.COUNTER ? (currentCount ?? 0) : currentCount,
        targetCount = type == TaskTypeEnum.COUNTER ? (targetCount ?? 1) : targetCount;

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
      taskDate: json['task_date'] != null ? DateTime.parse(json['task_date']).toLocal() : null,
      time: json['time'] != null ? TimeOfDay.fromDateTime(DateTime.parse("1970-01-01 ${json['time']}")) : null,
      isNotificationOn: json['is_notification_on'],
      isAlarmOn: json['is_alarm_on'],
      currentDuration: json['current_duration'] != null ? stringToDuration(json['current_duration']) : (type == TaskTypeEnum.TIMER ? Duration.zero : null),
      remainingDuration: json['remaining_duration'] != null ? stringToDuration(json['remaining_duration']) : (type == TaskTypeEnum.TIMER ? const Duration(minutes: 30) : null),
      currentCount: json['current_count'] ?? (type == TaskTypeEnum.COUNTER ? 0 : null),
      targetCount: json['target_count'] ?? (type == TaskTypeEnum.COUNTER ? 1 : null),
      isTimerActive: json['is_timer_active'] ?? (type == TaskTypeEnum.TIMER ? false : null),
      attributeIDList: json['attribute_id_list'] != null ? (json['attribute_id_list'] as List).map((i) => i as int).toList() : null,
      skillIDList: json['skill_id_list'] != null ? (json['skill_id_list'] as List).map((i) => i as int).toList() : null,
      status: json['status'] != null ? TaskStatusEnum.values.firstWhere((e) => e.toString().split('.').last == (json['status'] == 'COMPLETED' ? 'DONE' : json['status'])) : null,
      priority: json['priority'] ?? 3,
      subtasks: json['subtasks'] != null ? SubTaskModel.fromJsonList(json['subtasks']) : null,
      location: json['location'],
      categoryId: json['category_id'],
      showSubtasks: json['show_subtasks'],
      earlyReminderMinutes: json['early_reminder_minutes'],
      attachmentPaths: json['attachment_paths'] != null ? (json['attachment_paths'] as List).map((i) => i as String).toList() : null,
      isPinned: json['is_pinned'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
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
      'show_subtasks': _showSubtasks,
      'early_reminder_minutes': earlyReminderMinutes,
      'attachment_paths': attachmentPaths,
      'is_pinned': isPinned,
      'sort_order': sortOrder,
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
      if (!isCompleted) return true; // showCompleted = true ise tüm taskları göster

      // showCompleted = false ise:
      // 1. Explicit status null olan taskları göster (in progress)
      // 2. Timer tipinde aktif olan taskları göster (hedef süre 0 olsa bile)
      // 3. FAILED status'u olan taskları göster (başarısız ama hala aktif sayılır - filtreleme ayarlarından kontrol edilir)
      // 4. DONE, CANCEL, OVERDUE status'u olan taskları gizle
      if (status == null) return true; // In progress tasks always show
      if (type == TaskTypeEnum.TIMER && (isTimerActive ?? false)) return true; // Active timers always show
      if (status == TaskStatusEnum.FAILED) return true; // 🔴 FAILED tasks always show - controlled by HomeViewModel filters
      return false; // Hide completed, cancelled, overdue tasks
    }

    return taskDate?.isSameDay(date) == true && isRoutineCheck() && isCompletedCheck();
  }
}

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 2;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return TaskModel(
      id: fields[0] as int,
      routineID: fields[1] as int?,
      title: fields[2] as String,
      description: fields[3] as String?,
      type: fields[4] as TaskTypeEnum,
      taskDate: fields[5] as DateTime?,
      time: fields[6] as TimeOfDay?,
      isNotificationOn: fields[7] as bool,
      isAlarmOn: fields[8] as bool,
      currentDuration: fields[9] as Duration?,
      remainingDuration: fields[10] as Duration?,
      currentCount: fields[11] as int?,
      targetCount: fields[12] as int?,
      isTimerActive: fields[13] as bool?,
      attributeIDList: (fields[14] as List?)?.cast<int>(),
      skillIDList: (fields[15] as List?)?.cast<int>(),
      status: fields[16] as TaskStatusEnum?,
      priority: fields[17] as int,
      subtasks: (fields[18] as List?)?.cast<SubTaskModel>(),
      location: fields[19] as String?,
      categoryId: fields[20] is int ? (fields[20] as int).toString() : fields[20] as String?,
      earlyReminderMinutes: fields[22] as int?,
      attachmentPaths: (fields[23] as List?)?.cast<String>(),
    )
      .._showSubtasks = fields[21] as bool?
      .._isPinned = fields[24] as bool?;
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.routineID)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.taskDate)
      ..writeByte(6)
      ..write(obj.time)
      ..writeByte(7)
      ..write(obj.isNotificationOn)
      ..writeByte(8)
      ..write(obj.isAlarmOn)
      ..writeByte(9)
      ..write(obj.currentDuration)
      ..writeByte(10)
      ..write(obj.remainingDuration)
      ..writeByte(11)
      ..write(obj.currentCount)
      ..writeByte(12)
      ..write(obj.targetCount)
      ..writeByte(13)
      ..write(obj.isTimerActive)
      ..writeByte(14)
      ..write(obj.attributeIDList)
      ..writeByte(15)
      ..write(obj.skillIDList)
      ..writeByte(16)
      ..write(obj.status)
      ..writeByte(17)
      ..write(obj.priority)
      ..writeByte(18)
      ..write(obj.subtasks)
      ..writeByte(19)
      ..write(obj.location)
      ..writeByte(20)
      ..write(obj.categoryId)
      ..writeByte(21)
      ..write(obj._showSubtasks)
      ..writeByte(22)
      ..write(obj.earlyReminderMinutes)
      ..writeByte(23)
      ..write(obj.attachmentPaths)
      ..writeByte(24)
      ..write(obj._isPinned);
  }
}
