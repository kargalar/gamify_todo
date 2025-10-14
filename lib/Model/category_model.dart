import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'category_model.g.dart';

@HiveType(typeId: 15)
enum CategoryType {
  @HiveField(0)
  task,
  @HiveField(1)
  note,
  @HiveField(2)
  project,
}

@HiveType(typeId: 7)
class CategoryModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  Color color;
  @HiveField(3)
  bool isArchived;
  @HiveField(4)
  int? iconCodePoint;
  @HiveField(5)
  DateTime? createdAt;
  @HiveField(6)
  CategoryType categoryType;

  CategoryModel({
    required this.id,
    required this.title,
    required this.color,
    this.isArchived = false,
    this.iconCodePoint,
    this.createdAt,
    this.categoryType = CategoryType.task,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      title: json['title'],
      color: Color(int.parse(json['color'].toString().replaceAll("#", ""), radix: 16)),
      isArchived: json['is_archived'] ?? false,
      iconCodePoint: json['icon_code_point'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      categoryType: json['category_type'] != null ? CategoryType.values[json['category_type']] : CategoryType.task,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
      'is_archived': isArchived,
      'icon_code_point': iconCodePoint,
      'created_at': createdAt?.toIso8601String(),
      'category_type': categoryType.index,
    };
  }

  // Getters for compatibility with ProjectCategoryModel
  int get colorValue => color.toARGB32();
  String get name => title;
}
