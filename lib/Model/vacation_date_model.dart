import 'package:hive/hive.dart';

part 'vacation_date_model.g.dart';

@HiveType(typeId: 11) // Adjust typeId based on your existing models
class VacationDateModel extends HiveObject {
  @HiveField(0)
  late String dateString; // Format: 'yyyy-MM-dd'

  @HiveField(1)
  late bool isVacation;

  @HiveField(2)
  late DateTime createdAt;

  VacationDateModel({
    required this.dateString,
    required this.isVacation,
    DateTime? createdAt,
  }) {
    this.createdAt = createdAt ?? DateTime.now();
  }

  /// Parse date from string
  DateTime get date {
    final parts = dateString.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Create from DateTime
  static String dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'VacationDateModel(date: $dateString, isVacation: $isVacation)';
  }
}
