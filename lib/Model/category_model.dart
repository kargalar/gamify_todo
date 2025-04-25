import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'category_model.g.dart';

@HiveType(typeId: 7)
class CategoryModel extends HiveObject {
  @HiveField(0)
  int id;
  @HiveField(1)
  String title;
  @HiveField(2)
  Color color;
  @HiveField(3)
  bool isArchived;

  CategoryModel({
    this.id = 0,
    required this.title,
    required this.color,
    this.isArchived = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      title: json['title'],
      color: Color(int.parse(json['color'].toString().replaceAll("#", ""), radix: 16)),
      isArchived: json['is_archived'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
      'is_archived': isArchived,
    };
  }
}
