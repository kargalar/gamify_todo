import 'package:hive_flutter/hive_flutter.dart';
import 'package:next_level/Core/firebase_utils.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0) // Changed from 0 to 1 for new version
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
  String username;
  @HiveField(6)
  DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.password,
    required this.username,
    this.creditProgress = const Duration(hours: 0, minutes: 0, seconds: 0),
    this.userCredit = 0,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      username: json['username'] ?? '',
      creditProgress: FirebaseUtils.parseDuration(json['credit_progress']) ?? const Duration(hours: 0, minutes: 0, seconds: 0),
      userCredit: json['user_credit'] ?? 0,
      updatedAt: FirebaseUtils.parseTimestamp(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'username': username,
      'credit_progress': FirebaseUtils.durationToString(creditProgress),
      'user_credit': userCredit,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
