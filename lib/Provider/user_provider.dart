import 'package:flutter/material.dart';
import 'package:next_level/Model/user_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

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
  int get disciplinePoints => _currentUser?.disciplinePoints ?? 0;

  String get disciplineLevelName {
    final dp = disciplinePoints;

    if (dp >= 2500) return LocaleKeys.LevelSpartan.tr();
    if (dp >= 1500) return LocaleKeys.LevelLegendary.tr();
    if (dp >= 1000) return LocaleKeys.LevelWise.tr(); // Re-adjusting order to make sense for Wise
    if (dp >= 750) return LocaleKeys.LevelMaster.tr();
    if (dp >= 500) return LocaleKeys.LevelFocused.tr();
    if (dp >= 250) return LocaleKeys.LevelDetermined.tr();
    if (dp >= 100) return LocaleKeys.LevelDisciplined.tr();
    if (dp >= 50) return LocaleKeys.LevelConsistent.tr();
    if (dp >= 0) return LocaleKeys.LevelRookie.tr();
    return LocaleKeys.LevelReckless.tr();
  }

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

  Future<void> updateDisciplinePoints(int pointsToAdd) async {
    if (_currentUser != null) {
      _currentUser!.disciplinePoints += pointsToAdd;
      await HiveService().updateUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> setLastRoutineBonusDate(DateTime? date) async {
    if (_currentUser != null) {
      _currentUser!.lastRoutineBonusDate = date;
      await HiveService().updateUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> setLastTaskBonusDate(DateTime? date) async {
    if (_currentUser != null) {
      _currentUser!.lastTaskBonusDate = date;
      await HiveService().updateUser(_currentUser!);
      notifyListeners();
    }
  }
}
