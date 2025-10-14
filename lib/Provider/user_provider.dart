import 'package:flutter/material.dart';
import 'package:next_level/Model/user_model.dart';
import 'package:next_level/Service/hive_service.dart';

class UserProvider with ChangeNotifier {
  static final UserProvider _instance = UserProvider._internal();

  factory UserProvider() {
    return _instance;
  }

  UserProvider._internal();

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  int get userCredit => _currentUser?.userCredit ?? 0;
  Duration get creditProgress => _currentUser?.creditProgress ?? Duration.zero;
  String get username => _currentUser?.username ?? 'User';
  String get email => _currentUser?.email ?? '';

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateUserCredit(int credit) async {
    if (_currentUser != null) {
      _currentUser!.userCredit = credit;
      await HiveService().updateUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> updateCreditProgress(Duration progress) async {
    if (_currentUser != null) {
      _currentUser!.creditProgress = progress;
      await HiveService().updateUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> addCredit(int amount) async {
    if (_currentUser != null) {
      _currentUser!.userCredit += amount;
      await HiveService().updateUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> resetCredit() async {
    if (_currentUser != null) {
      _currentUser!.userCredit = 0;
      _currentUser!.creditProgress = Duration.zero;
      await HiveService().updateUser(_currentUser!);
      notifyListeners();
    }
  }
}
