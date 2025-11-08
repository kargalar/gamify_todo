import 'package:next_level/Enum/task_type_enum.dart';

class StoreItemLog {
  final int itemId;
  final DateTime logDate;
  final String action;
  final dynamic value; // int for counter, Duration for timer
  final TaskTypeEnum type;
  // Whether this log should affect the item's persisted progress (manual logs)
  final bool affectsProgress;
  // Whether this log is a purchase (satın alma) - shows as credit deduction in transactions
  final bool isPurchase;

  StoreItemLog({
    required this.itemId,
    required this.logDate,
    required this.action,
    required this.value,
    required this.type,
    this.affectsProgress = false,
    this.isPurchase = false,
  });
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
