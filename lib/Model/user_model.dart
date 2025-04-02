import 'package:hive_flutter/hive_flutter.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String email;

  @HiveField(2)
  String password;

  @HiveField(3)
  Duration creditProgress;

  @HiveField(4)
  int userCredit;

  @HiveField(5)
  DateTime? lastUpdated;

  @HiveField(6)
  String? firebaseId;

  @HiveField(7)
  bool hasLocalChanges = false;

  UserModel({
    required this.id,
    required this.email,
    required this.password,
    this.creditProgress = const Duration(hours: 0, minutes: 0, seconds: 0),
    this.userCredit = 0,
    this.lastUpdated,
    this.firebaseId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    Duration stringToDuration(String timeString) {
      List<String> split = timeString.split(':');
      return Duration(hours: int.parse(split[0]), minutes: int.parse(split[1]), seconds: int.parse(split[2]));
    }

    return UserModel(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      creditProgress: stringToDuration(json['credit_progress']),
      userCredit: json['user_credit'],
    );
  }

  Map<String, dynamic> toJson() {
    String durationToString(Duration duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);

      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return {
      'id': id,
      'email': email,
      'password': password,
      'credit_progress': durationToString(creditProgress),
      'user_credit': userCredit,
    };
  }
}
