import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_item_style_enum.dart';

class TaskStyleProvider extends ChangeNotifier {
  TaskItemStyle _currentStyle = TaskItemStyle.card;

  TaskItemStyle get currentStyle => _currentStyle;

  void changeStyle(TaskItemStyle newStyle) {
    _currentStyle = newStyle;
    notifyListeners();
  }

  void nextStyle() {
    const styles = TaskItemStyle.values;
    final currentIndex = styles.indexOf(_currentStyle);
    final nextIndex = (currentIndex + 1) % styles.length;
    _currentStyle = styles[nextIndex];
    notifyListeners();
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
