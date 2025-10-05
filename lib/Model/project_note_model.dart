import 'package:hive_flutter/hive_flutter.dart';

part 'project_note_model.g.dart';

@HiveType(typeId: 14)
class ProjectNoteModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String projectId;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  String? title;

  ProjectNoteModel({
    required this.id,
    required this.projectId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.title,
  });

  /// Copy with method
  ProjectNoteModel copyWith({
    String? id,
    String? projectId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
  }) {
    return ProjectNoteModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
    );
  }

  @override
  String toString() {
    return 'ProjectNoteModel(id: $id, projectId: $projectId, content: ${content.length} chars)';
  }
}
