// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectNoteModelAdapter extends TypeAdapter<ProjectNoteModel> {
  @override
  final int typeId = 14;

  @override
  ProjectNoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectNoteModel(
      id: fields[0] as String,
      projectId: fields[1] as String,
      content: fields[2] as String?,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      title: fields[5] as String?,
      orderIndex: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectNoteModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.title)
      ..writeByte(6)
      ..write(obj.orderIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectNoteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
