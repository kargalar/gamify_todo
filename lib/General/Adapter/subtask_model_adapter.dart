import 'package:gamify_todo/Model/subtask_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SubTaskModelAdapter extends TypeAdapter<SubTaskModel> {
  @override
  final int typeId = 5;

  @override
  SubTaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubTaskModel(
      id: fields[0] as int,
      title: fields[1] as String,
      isCompleted: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SubTaskModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.isCompleted);
  }
}
