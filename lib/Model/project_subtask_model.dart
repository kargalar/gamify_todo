import 'package:hive_flutter/hive_flutter.dart';

part 'project_subtask_model.g.dart';

@HiveType(typeId: 13)
class ProjectSubtaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String projectId;

  @HiveField(2)
  String title;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  int orderIndex;

  @HiveField(6)
  String? description;

  ProjectSubtaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    this.orderIndex = 0,
    this.description,
  });

  /// Copy with method
  ProjectSubtaskModel copyWith({
    String? id,
    String? projectId,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    int? orderIndex,
    String? description,
  }) {
    return ProjectSubtaskModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      orderIndex: orderIndex ?? this.orderIndex,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'ProjectSubtaskModel(id: $id, projectId: $projectId, title: $title, isCompleted: $isCompleted)';
  }
}
