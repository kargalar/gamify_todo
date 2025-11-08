import 'package:hive_flutter/hive_flutter.dart';
import 'package:next_level/Enum/task_type_enum.dart';

part 'store_item_log_model.g.dart';

@HiveType(typeId: 10)
class StoreItemLog extends HiveObject {
  @HiveField(0)
  final int itemId;

  @HiveField(1)
  final DateTime logDate;

  @HiveField(2)
  final String action;

  @HiveField(3)
  final dynamic value; // int for counter, Duration for timer (stored as is)

  @HiveField(4)
  final int typeValue; // 0 for COUNTER, 1 for TIMER

  @HiveField(5)
  final bool affectsProgress;

  @HiveField(6)
  final bool isPurchase;

  StoreItemLog({
    required this.itemId,
    required this.logDate,
    required this.action,
    required this.value,
    required this.typeValue,
    this.affectsProgress = false,
    this.isPurchase = false,
  });

  /// Factory constructor for creation with TaskTypeEnum
  factory StoreItemLog.create({
    required int itemId,
    required DateTime logDate,
    required String action,
    required dynamic value,
    required TaskTypeEnum type,
    bool affectsProgress = false,
    bool isPurchase = false,
  }) {
    return StoreItemLog(
      itemId: itemId,
      logDate: logDate,
      action: action,
      value: value,
      typeValue: type == TaskTypeEnum.COUNTER ? 0 : 1,
      affectsProgress: affectsProgress,
      isPurchase: isPurchase,
    );
  }

  TaskTypeEnum get type => typeValue == 0 ? TaskTypeEnum.COUNTER : TaskTypeEnum.TIMER;

  String get formattedValue {
    if (type == TaskTypeEnum.COUNTER) {
      int count = value as int;
      String sign = count >= 0 ? "+" : "";
      return "$sign$count";
    } else {
      Duration duration = value as Duration;
      bool isPositive = !duration.isNegative;
      int hours = isPositive ? duration.inHours : -duration.inHours;
      int minutes = isPositive ? duration.inMinutes.remainder(60) : -duration.inMinutes.remainder(60);
      int seconds = isPositive ? duration.inSeconds.remainder(60) : -duration.inSeconds.remainder(60);

      String sign = isPositive ? "+" : "-";

      // Saat, dakika ve saniye değerlerini göster
      if (hours > 0) {
        if (minutes > 0) {
          if (seconds > 0) {
            return "$sign${hours}h ${minutes}m ${seconds}s";
          } else {
            return "$sign${hours}h ${minutes}m";
          }
        } else {
          if (seconds > 0) {
            return "$sign${hours}h ${seconds}s";
          } else {
            return "$sign${hours}h";
          }
        }
      } else if (minutes > 0) {
        if (seconds > 0) {
          return "$sign${minutes}m ${seconds}s";
        } else {
          return "$sign${minutes}m";
        }
      } else if (seconds > 0) {
        return "$sign${seconds}s";
      } else {
        // Gerçekten sıfır ise (hiç süre geçmemiş)
        return "0s";
      }
    }
  }

  String get formattedDate {
    return "${logDate.day}/${logDate.month}/${logDate.year} ${logDate.hour.toString().padLeft(2, '0')}:${logDate.minute.toString().padLeft(2, '0')}:${logDate.second.toString().padLeft(2, '0')}";
  }
}
