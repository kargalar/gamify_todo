// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as int,
      email: fields[1] as String,
      password: fields[2] as String,
      username: fields[5] as String,
      creditProgress: fields[3] as Duration,
      userCredit: fields[4] as int,
      disciplinePoints: fields[6] == null ? 0 : fields[6] as int,
      lastRoutineBonusDate: fields[7] as DateTime?,
      lastTaskBonusDate: fields[8] as DateTime?,
      lastRoutinePenaltyDate: fields[9] as DateTime?,
      lastTaskPenaltyDate: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.password)
      ..writeByte(3)
      ..write(obj.creditProgress)
      ..writeByte(4)
      ..write(obj.userCredit)
      ..writeByte(5)
      ..write(obj.username)
      ..writeByte(6)
      ..write(obj.disciplinePoints)
      ..writeByte(7)
      ..write(obj.lastRoutineBonusDate)
      ..writeByte(8)
      ..write(obj.lastTaskBonusDate)
      ..writeByte(9)
      ..write(obj.lastRoutinePenaltyDate)
      ..writeByte(10)
      ..write(obj.lastTaskPenaltyDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
