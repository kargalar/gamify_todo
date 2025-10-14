// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryTypeAdapter extends TypeAdapter<CategoryType> {
  @override
  final int typeId = 15;

  @override
  CategoryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CategoryType.task;
      case 1:
        return CategoryType.note;
      case 2:
        return CategoryType.project;
      default:
        return CategoryType.task;
    }
  }

  @override
  void write(BinaryWriter writer, CategoryType obj) {
    switch (obj) {
      case CategoryType.task:
        writer.writeByte(0);
        break;
      case CategoryType.note:
        writer.writeByte(1);
        break;
      case CategoryType.project:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CategoryTypeAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 7;

  @override
  CategoryModel read(BinaryReader reader) {
    try {
      final numOfFields = reader.readByte();
      final fields = <int, dynamic>{
        for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
      };
      return CategoryModel(
        id: fields[0] is int ? (fields[0] as int).toString() : fields[0] as String,
        title: fields[1] as String,
        color: fields[2] as Color,
        isArchived: fields[3] as bool,
        iconCodePoint: fields[4] as int?,
        createdAt: fields[5] as DateTime?,
        categoryType: fields.containsKey(6) ? fields[6] as CategoryType : CategoryType.task,
      );
    } catch (e) {
      // If migration fails, return a default category
      return CategoryModel(
        id: 'migrated_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Migrated Category',
        color: const Color(0xFF2196F3),
        categoryType: CategoryType.task,
      );
    }
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.color)
      ..writeByte(3)
      ..write(obj.isArchived)
      ..writeByte(4)
      ..write(obj.iconCodePoint)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.categoryType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CategoryModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
