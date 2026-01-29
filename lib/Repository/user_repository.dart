import 'package:flutter/foundation.dart';
import 'package:next_level/Model/user_model.dart';
import 'package:next_level/Service/hive_service.dart';

class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  HiveService _hiveService = HiveService();

  @visibleForTesting
  void setHiveService(HiveService service) {
    _hiveService = service;
  }

  Future<void> addUser(UserModel userModel) async {
    await _hiveService.addUser(userModel);
  }

  Future<UserModel?> getUser(int id) async {
    return await _hiveService.getUser(id);
  }

  Future<void> updateUser(UserModel userModel) async {
    await _hiveService.updateUser(userModel);
  }

  Future<List<UserModel>> getUsers() async {
    return await _hiveService.getUsers();
  }
}
