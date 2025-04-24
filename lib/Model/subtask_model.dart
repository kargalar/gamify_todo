import 'package:hive_flutter/hive_flutter.dart';

part 'subtask_model.g.dart';

@HiveType(typeId: 5)
class SubTaskModel extends HiveObject {
  @HiveField(0)
  int id;
  @HiveField(1)
  String title;
  @HiveField(2)
  bool isCompleted;

  SubTaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  factory SubTaskModel.fromJson(Map<String, dynamic> json) {
    return SubTaskModel(
      id: json['id'],
      title: json['title'],
      isCompleted: json['is_completed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'is_completed': isCompleted,
    };
  }

  static List<SubTaskModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((i) => SubTaskModel.fromJson(i)).toList();
  }

  List<Map<String, dynamic>> toJsonList(List<SubTaskModel> models) {
    return models.map((i) => i.toJson()).toList();
  }
}
