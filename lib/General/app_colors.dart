import 'package:flutter/material.dart';

// TODO: Denemelerin bittikten sonra hepsini static yap. setstate olunca değişmesi için static değil. en son halinde de neden statik olmalı öğren.
class AppColors {
  // static late bool _isDark;
  // static bool get isDark => _isDark;
  static bool get isDark => true;

  static void updateTheme({
    required bool isDarkTheme,
  }) {
    // _isDark = isDarkTheme;
    // _isDark = true;
  }

  // Border Radius
  static const double borderRadius = 8;
  static BorderRadius borderRadiusAll = const BorderRadius.all(Radius.circular(borderRadius));
  static BorderRadius highBorderRadiusAll = const BorderRadius.all(Radius.circular(borderRadius * 3));
  static BorderRadius borderRadiusTop = const BorderRadius.vertical(top: Radius.circular(borderRadius));
  static BorderRadius borderRadiusBottom = const BorderRadius.vertical(bottom: Radius.circular(borderRadius));
  static BorderRadius borderRadiusCircular = const BorderRadius.all(Radius.circular(125));

  // Padding
  static const EdgeInsets showcasePadding = EdgeInsets.all(3);

  // TODO: boxShadows için de yap
  // Shadows
  static const List<Shadow> basicShadow = [
    Shadow(
      color: AppColors.transparantBlack,
      offset: Offset(1, 1),
      blurRadius: 2,
    ),
  ];
  static const List<BoxShadow> bottomShadow = [
    BoxShadow(
      spreadRadius: 0,
      blurRadius: 5,
      offset: Offset(0, 2),
    ),
  ];

  // Main Colors
  static const Color transparent = Color.fromRGBO(0, 0, 0, 0);
  static const Color deepBlack = Color.fromRGBO(15, 15, 15, 1);
  static const Color deepWhite = Color.fromARGB(255, 255, 255, 255);
  static const Color black = Color.fromRGBO(16, 16, 16, 1);
  static const Color lightblack = Color.fromRGBO(32, 32, 32, 1);
  static const Color transparantBlack = Color.fromRGBO(16, 16, 16, 0.5);
  static const Color grey = Color.fromARGB(255, 99, 99, 99);
  static const Color dirtyWhite = Color.fromARGB(255, 168, 168, 168);
  static const Color white = Color.fromARGB(255, 250, 250, 250);
  static const Color red = Color.fromARGB(255, 218, 17, 17);
  static const Color dirtyRed = Color.fromARGB(255, 182, 28, 28);
  static const Color pink = Color.fromARGB(255, 224, 18, 163);
  static const Color blue = Color.fromARGB(255, 13, 121, 209);
  static const Color deepBlue = Color.fromARGB(255, 0, 83, 151);
  static const Color yellow = Color.fromARGB(255, 238, 196, 10);
  static const Color orange = Color.fromARGB(255, 238, 113, 10);
  static const Color orange2 = Color.fromARGB(255, 255, 152, 0);
  static const Color green = Color.fromARGB(255, 53, 226, 10);
  static const Color deepGreen = Color.fromARGB(255, 37, 184, 0);
  static const Color purple = Color.fromARGB(255, 145, 3, 211);
  static const Color deepPurple = Color.fromARGB(255, 96, 3, 158);
  static const Color lightGreen = Color.fromARGB(255, 137, 224, 140);

  // Matte Colors
  static const Color matteRed = Color.fromARGB(255, 195, 85, 85);
  static const Color matteBlue = Color.fromARGB(255, 85, 145, 195);
  static const Color matteOrange = Color.fromARGB(255, 195, 135, 85);
  static const Color matteYellow = Color.fromARGB(255, 195, 185, 85);
  static const Color matteGrey = Color.fromARGB(255, 120, 120, 120);
  static const Color mattePurple = Color.fromARGB(255, 145, 85, 195);
  static const Color matteGreen = Color.fromARGB(255, 85, 195, 105);

  // General Colors
  static Color get cursor {
    if (isDark) {
      return const Color.fromARGB(255, 204, 204, 204);
    } else {
      return const Color.fromARGB(255, 66, 66, 66);
    }
  }

  // Button Colors
  static Color hover = const Color.fromARGB(48, 73, 73, 73);

  // Theme Colors
  static Color main = const Color.fromARGB(255, 23, 115, 219);
  static Color lightMain = const Color.fromARGB(255, 70, 150, 241);
  static Color deepMain = const Color.fromARGB(255, 10, 64, 126);
  static Color dirtyMain = const Color.fromARGB(255, 19, 94, 180);

  // Dynamic Colors
  static Color get background {
    if (isDark) {
      return const Color.fromARGB(255, 15, 15, 15);
    } else {
      return const Color.fromARGB(255, 226, 226, 226);
    }
  }

  static Color get onBackground {
    if (isDark) {
      return const Color.fromARGB(255, 247, 247, 247);
    } else {
      return const Color.fromARGB(255, 32, 32, 32);
    }
  }

  static Color get deepContrast {
    if (isDark) {
      return const Color.fromARGB(255, 0, 0, 0);
    } else {
      return const Color.fromARGB(255, 255, 255, 255);
    }
  }

  static Color get panelBackground {
    if (isDark) {
      return const Color.fromARGB(255, 31, 31, 31);
    } else {
      return const Color.fromARGB(255, 247, 247, 247);
    }
  }

  static Color get panelBackgroundDark {
    if (isDark) {
      return const Color.fromARGB(255, 22, 22, 22);
    } else {
      return const Color.fromARGB(255, 236, 236, 236);
    }
  }

  static Color get panelBackground2 {
    if (isDark) {
      return const Color.fromARGB(255, 54, 54, 54);
    } else {
      return const Color.fromARGB(255, 231, 231, 231);
    }
  }

  static Color get panelBackground3 {
    if (isDark) {
      return const Color.fromARGB(255, 70, 70, 70);
    } else {
      return const Color.fromARGB(255, 214, 214, 214);
    }
  }

  static Color get panelBackground4 {
    if (isDark) {
      return const Color.fromARGB(255, 53, 53, 53);
    } else {
      return const Color.fromARGB(255, 170, 170, 170);
    }
  }

  static Color get panelBackground5 {
    if (isDark) {
      return const Color.fromARGB(255, 31, 31, 31);
    } else {
      return const Color.fromARGB(255, 247, 247, 247);
    }
  }

  static Color get panelBackground6 {
    if (isDark) {
      return const Color.fromARGB(255, 22, 22, 22);
    } else {
      return const Color.fromARGB(255, 247, 247, 247);
    }
  }

  static Color get text {
    if (isDark) {
      return const Color.fromARGB(255, 245, 245, 245);
    } else {
      return const Color.fromARGB(255, 19, 19, 19);
    }
  }

  static Color get appbar {
    if (isDark) {
      return const Color.fromARGB(255, 32, 32, 32);
    } else {
      return const Color.fromARGB(255, 218, 218, 218);
    }
  }

  // skillColors
  static List<Color> skillColors = [
    const Color.fromARGB(255, 255, 105, 0),
    const Color.fromARGB(255, 107, 65, 18),
    const Color.fromARGB(255, 110, 194, 0),
    const Color.fromARGB(255, 0, 195, 255),
    const Color.fromARGB(255, 255, 0, 221),
    const Color.fromARGB(255, 0, 3, 204),
    const Color.fromARGB(255, 228, 194, 0),
    const Color.fromARGB(255, 221, 7, 0),
    const Color.fromARGB(255, 89, 0, 255),
    const Color.fromARGB(255, 0, 88, 27),
    const Color.fromARGB(255, 129, 49, 29),
    const Color.fromARGB(255, 67, 0, 155),
  ];

  // ---------------------------------------------------------------------------------------------------------------
}
