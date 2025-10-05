import 'package:hive_flutter/hive_flutter.dart';

part 'note_model.g.dart';

@HiveType(typeId: 8)
class NoteModel extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  String? categoryId; // Kategori ID'si (nullable)

  @HiveField(4)
  int colorIndex;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool isPinned;

  @HiveField(8)
  bool isArchived;

  NoteModel({
    this.id = 0,
    required this.title,
    this.content = '',
    this.categoryId,
    this.colorIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
  });

  /// Copy with method
  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    String? categoryId,
    int? colorIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isArchived,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      categoryId: categoryId ?? this.categoryId,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  String toString() {
    return 'NoteModel(id: $id, title: $title, categoryId: $categoryId, isPinned: $isPinned, isArchived: $isArchived)';
  }
}
