import 'package:flutter/material.dart';
import 'package:gamify_todo/Enum/trait_type_enum.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'trait_model.g.dart';

@HiveType(typeId: 1)
class TraitModel extends HiveObject {
  @HiveField(0)
  int id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String icon;
  @HiveField(3)
  Color color;
  @HiveField(4)
  TraitTypeEnum type;
  @HiveField(5)
  bool isArchived;
  @HiveField(6)
  DateTime? lastUpdated;
  @HiveField(7)
  String? firebaseId;

  TraitModel({
    this.id = 0,
    required this.title,
    required this.icon,
    required this.color,
    required this.type,
    this.isArchived = false,
    this.lastUpdated,
    this.firebaseId,
  });

  factory TraitModel.fromJson(Map<String, dynamic> json) {
    TraitTypeEnum type = TraitTypeEnum.values.firstWhere((e) => e.toString().split('.').last == json['type']);

    return TraitModel(
      id: json['id'],
      title: json['title'],
      icon: json['icon'],
      color: Color(int.parse(json['color'].toString().replaceAll("#", ""), radix: 16)),
      type: type,
      isArchived: json['is_archived'],
      lastUpdated: json['last_updated'] != null ? DateTime.parse(json['last_updated']) : null,
      firebaseId: json['firebase_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      // ignore: deprecated_member_use
      'color': color.value.toRadixString(16),
      'type': type.toString().split('.').last,
      'is_archived': isArchived,
      'last_updated': lastUpdated?.toIso8601String(),
      'firebase_id': firebaseId,
    };
  }
}
