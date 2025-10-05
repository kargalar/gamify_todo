// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_category_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectCategoryModelAdapter extends TypeAdapter<ProjectCategoryModel> {
  @override
  final int typeId = 15;

  @override
  ProjectCategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectCategoryModel(
      id: fields[0] as String,
      name: fields[1] as String,
      iconCodePoint: fields[2] as int,
      colorValue: fields[3] as int,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectCategoryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconCodePoint)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectCategoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
