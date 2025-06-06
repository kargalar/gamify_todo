import 'package:flutter/material.dart';
import 'package:next_level/Provider/task_provider.dart';

class NavbarProvider with ChangeNotifier {
  static final NavbarProvider _instance = NavbarProvider._internal();
  factory NavbarProvider() {
    return _instance;
  }
  NavbarProvider._internal();

  int currentIndex = 1;

  late PageController pageController;

  void updateIndex(int index) {
    currentIndex = index;

    // Eğer home page'e (index 1) geçiş yapılıyorsa, selected date'i bugüne resetle
    if (index == 1) {
      TaskProvider().changeSelectedDate(DateTime.now());
    }

    pageController.animateToPage(
      currentIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    notifyListeners();
  }
}
