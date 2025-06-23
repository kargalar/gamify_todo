import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorProvider extends ChangeNotifier {
  // Available colors for selection
  static const List<Color> availableColors = [
    Color.fromARGB(255, 23, 115, 219), // Default blue
    Color.fromARGB(255, 3, 137, 170), // Deep Blue
    Color.fromARGB(255, 3, 155, 71), // Yellow
    Color.fromARGB(255, 33, 151, 4), // Green
    Color.fromARGB(255, 211, 100, 10), // Orange
    Color.fromARGB(255, 218, 17, 17), // Red
    Color.fromARGB(255, 211, 12, 151), // Pink
    Color.fromARGB(255, 145, 3, 211), // Purple
  ];

  Color _currentColor = availableColors[0];

  Color get currentColor => _currentColor;

  // Load saved color from SharedPreferences
  Future<void> loadSavedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColorValue = prefs.getInt('main_color');

    if (savedColorValue != null) {
      final savedColor = Color(savedColorValue);
      // Check if the saved color is in our available colors
      if (availableColors.contains(savedColor)) {
        _currentColor = savedColor;
        AppColors.main = _currentColor;
        AppColors.lightMain = _getLightVariant(_currentColor);
        AppColors.deepMain = _getDarkVariant(_currentColor);
        AppColors.dirtyMain = _getDirtyVariant(_currentColor);
        notifyListeners();
      }
    }
  }

  Future<void> changeColor(Color newColor) async {
    _currentColor = newColor;

    // Update all main color variants in AppColors
    AppColors.main = newColor;
    AppColors.lightMain = _getLightVariant(newColor);
    AppColors.deepMain = _getDarkVariant(newColor);
    AppColors.dirtyMain = _getDirtyVariant(newColor);

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // ignore: deprecated_member_use
    await prefs.setInt('main_color', newColor.value);

    notifyListeners();
  }

  // Generate lighter variant of the color
  Color _getLightVariant(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
  }

  // Generate darker variant of the color
  Color _getDarkVariant(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }

  // Generate dirty variant of the color
  Color _getDirtyVariant(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withSaturation((hsl.saturation - 0.1).clamp(0.0, 1.0)).withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }

  String getColorName(Color color) {
    if (color == availableColors[0]) return 'Default Blue';
    if (color == availableColors[1]) return 'Red';
    if (color == availableColors[2]) return 'Green';
    if (color == availableColors[3]) return 'Orange';
    if (color == availableColors[4]) return 'Purple';
    if (color == availableColors[5]) return 'Pink';
    if (color == availableColors[6]) return 'Yellow';
    if (color == availableColors[7]) return 'Deep Blue';
    return 'Custom';
  }
}
