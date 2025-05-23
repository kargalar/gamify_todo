import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  int aaa = 1;
  Future<bool> getSavedTheme() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getBool('isDark') ?? true;
  }

  void changeTheme() async {
    AppColors.updateTheme(isDarkTheme: !AppColors.isDark);

    final SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setBool('isDark', AppColors.isDark);

    notifyListeners();
  }
}
