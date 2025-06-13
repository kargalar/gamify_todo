import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_item_style_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskStyleProvider extends ChangeNotifier {
  TaskItemStyle _currentStyle = TaskItemStyle.card;

  TaskItemStyle get currentStyle => _currentStyle;

  // Load saved style from SharedPreferences
  Future<void> loadSavedStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStyleIndex = prefs.getInt('task_style') ?? TaskItemStyle.card.index;

    // Ensure the saved index is valid
    if (savedStyleIndex >= 0 && savedStyleIndex < TaskItemStyle.values.length) {
      _currentStyle = TaskItemStyle.values[savedStyleIndex];
      notifyListeners();
    }
  }

  Future<void> changeStyle(TaskItemStyle newStyle) async {
    _currentStyle = newStyle;

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('task_style', newStyle.index);

    notifyListeners();
  }

  Future<void> nextStyle() async {
    const styles = TaskItemStyle.values;
    final currentIndex = styles.indexOf(_currentStyle);
    final nextIndex = (currentIndex + 1) % styles.length;
    await changeStyle(styles[nextIndex]);
  }

  String get styleDisplayName {
    switch (_currentStyle) {
      case TaskItemStyle.card:
        return 'Card Style';
      case TaskItemStyle.minimal:
        return 'Minimal Style';
      case TaskItemStyle.flat:
        return 'Flat Style';
      case TaskItemStyle.glass:
        return 'Glass Style';
      case TaskItemStyle.modern:
        return 'Modern Style';
    }
  }
}
