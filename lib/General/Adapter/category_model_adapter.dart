import 'package:flutter/material.dart';
import 'package:gamify_todo/Model/category_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 7;

  @override
  CategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryModel(
      id: fields[0] as int,
      title: fields[1] as String,
      color: fields[2] as Color,
      isArchived: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.color)
      ..writeByte(3)
      ..write(obj.isArchived);
  }
}
