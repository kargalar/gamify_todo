import 'package:hive_flutter/hive_flutter.dart';

part 'project_model.g.dart';

@HiveType(typeId: 12)
class ProjectModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  bool isPinned;

  @HiveField(6)
  bool isArchived;

  @HiveField(7)
  int colorIndex;

  @HiveField(8)
  String? categoryId;

  ProjectModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.colorIndex = 0,
    this.categoryId,
  });

  /// Copy with method
  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isArchived,
    int? colorIndex,
    String? categoryId,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      colorIndex: colorIndex ?? this.colorIndex,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  String toString() {
    return 'ProjectModel(id: $id, title: $title, description: $description, isPinned: $isPinned, isArchived: $isArchived, categoryId: $categoryId)';
  }
}
