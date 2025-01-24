import 'package:flutter/material.dart';

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

    pageController.animateToPage(
      currentIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    notifyListeners();
  }
}
