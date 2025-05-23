import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';

class AppTheme {
  ThemeData theme = ThemeData(
    // Scaffold Background Color
    scaffoldBackgroundColor: AppColors.background,

    // Bottom Navigation Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.panelBackground,
      elevation: 0,
      unselectedIconTheme: IconThemeData(
        color: AppColors.text.withValues(alpha: 0.7),
        size: 27,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
      ),
      selectedItemColor: AppColors.text,
      selectedIconTheme: IconThemeData(
        color: AppColors.text,
        size: 30,
      ),
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
      ),
      showSelectedLabels: false,
      showUnselectedLabels: false,
    ),
    // AppBar
    appBarTheme: AppBarTheme(
      toolbarHeight: 40,
      backgroundColor: AppColors.appbar,
      surfaceTintColor: AppColors.appbar,
      iconTheme: IconThemeData(
        color: AppColors.text,
      ),
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      actionsIconTheme: IconThemeData(
        color: AppColors.text,
      ),
      toolbarTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      foregroundColor: AppColors.red,
      centerTitle: true,
    ),
    // List Tile
    listTileTheme: ListTileThemeData(
      tileColor: AppColors.background,
      selectedTileColor: AppColors.background,
      iconColor: AppColors.text,
      textColor: AppColors.text,
    ),
    // Divider
    dividerTheme: DividerThemeData(
      color: AppColors.onBackground,
      thickness: 1,
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.all<Color>(AppColors.main),
    ),
    // Icon
    iconTheme: IconThemeData(
      color: AppColors.text,
    ),
    // Dialog
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: AppColors.grey,
          width: 1,
        ),
      ),
    ),
    // IconButton
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        overlayColor: WidgetStatePropertyAll<Color>(AppColors.hover),
      ),
    ),
    // Time Picker
    timePickerTheme: TimePickerThemeData(
      backgroundColor: AppColors.background,
      hourMinuteColor: AppColors.panelBackground,
      dialBackgroundColor: AppColors.panelBackground,
      dialTextColor: AppColors.text,
      entryModeIconColor: AppColors.text,
      confirmButtonStyle: ElevatedButton.styleFrom(
        backgroundColor: AppColors.main,
        shape: RoundedRectangleBorder(
          borderRadius: AppColors.borderRadiusAll,
        ),
      ),
      hourMinuteTextColor: AppColors.text,
      dayPeriodColor: AppColors.main,
      dayPeriodBorderSide: BorderSide(
        color: AppColors.main,
        width: 2,
      ),
      dayPeriodShape: RoundedRectangleBorder(
        borderRadius: AppColors.borderRadiusAll,
      ),
      dayPeriodTextColor: AppColors.text,
    ),
    // Textfield
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      // border: OutlineInputBorder(
      //   borderRadius: AppColors.borderRadiusAll,
      //   borderSide: BorderSide(
      //     color: AppColors.onBackground,
      //     width: 0.2,
      //   ),
      // ),
      // focusedBorder: OutlineInputBorder(
      //   borderRadius: AppColors.borderRadiusAll * 1.2,
      //   borderSide: BorderSide(
      //     color: AppColors.onBackground,
      //     width: 0.5,
      //   ),
      // ),
      // enabledBorder: OutlineInputBorder(
      //   borderRadius: AppColors.borderRadiusAll,
      //   borderSide: BorderSide(
      //     color: AppColors.onBackground,
      //     width: 0.2,
      //   ),
      // ),
      // errorBorder: OutlineInputBorder(
      //   borderRadius: AppColors.borderRadiusAll,
      //   borderSide: const BorderSide(
      //     color: AppColors.red,
      //     width: 0.5,
      //   ),
      // ),
      // focusedErrorBorder: OutlineInputBorder(
      //   borderRadius: AppColors.borderRadiusAll,
      //   borderSide: const BorderSide(
      //     color: AppColors.red,
      //     width: 1,
      //   ),
      // ),
      // disabledBorder: OutlineInputBorder(
      //   borderRadius: AppColors.borderRadiusAll,
      //   borderSide: BorderSide(
      //     color: AppColors.onBackground,
      //     width: 0.2,
      //   ),
      // ),
      labelStyle: TextStyle(
        color: AppColors.text,
      ),
      hintStyle: const TextStyle(
        color: AppColors.dirtyWhite,
      ),
    ),

    // PopMenu
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: AppColors.borderRadiusAll,
      ),
      textStyle: TextStyle(
        color: AppColors.text,
      ),
      labelTextStyle: WidgetStateProperty.all<TextStyle>(
        TextStyle(
          color: AppColors.text,
        ),
      ),
    ),

    // Date Picker
    datePickerTheme: DatePickerThemeData(
      confirmButtonStyle: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(AppColors.main),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: AppColors.borderRadiusAll,
          ),
        ),
        foregroundColor: WidgetStateProperty.all<Color>(AppColors.deepWhite),
      ),
      cancelButtonStyle: ButtonStyle(
        overlayColor: WidgetStateProperty.all<Color>(AppColors.hover),
        foregroundColor: WidgetStateProperty.all<Color>(AppColors.text),
      ),
    ),

    // Slider
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 8.0,
      ),
      overlayShape: const RoundSliderOverlayShape(
        overlayRadius: 8.0,
      ),
      thumbColor: AppColors.onBackground,
      activeTrackColor: AppColors.main,
      inactiveTrackColor: AppColors.grey,
    ),
    // BottomSheet
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: AppColors.borderRadiusTop,
      ),
    ),
    // Progress Indicator
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.main,
    ),
    // AppColors.text
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: AppColors.text, decorationColor: AppColors.text),
      bodyMedium: TextStyle(color: AppColors.text, decorationColor: AppColors.text),
      bodySmall: TextStyle(color: AppColors.text, decorationColor: AppColors.text),
      displayLarge: TextStyle(color: AppColors.text, decorationColor: AppColors.text),
      displayMedium: TextStyle(color: AppColors.text, decorationColor: AppColors.text),
      displaySmall: TextStyle(color: AppColors.text, decorationColor: AppColors.text),
      labelLarge: TextStyle(color: AppColors.text, decorationColor: AppColors.text),
      labelMedium: TextStyle(color: AppColors.text, decorationColor: AppColors.text),
      labelSmall: TextStyle(color: AppColors.text, decorationColor: AppColors.text),
      titleLarge: TextStyle(color: AppColors.text, decorationColor: AppColors.text, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: AppColors.text, decorationColor: AppColors.text, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(color: AppColors.text, decorationColor: AppColors.text, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: AppColors.text, decorationColor: AppColors.text, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: AppColors.text, decorationColor: AppColors.text, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: AppColors.text, decorationColor: AppColors.text, fontWeight: FontWeight.bold),
    ),
    // AppColors.text Button
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(AppColors.text),
        overlayColor: WidgetStateProperty.all<Color>(AppColors.text.withValues(alpha: 0.1)),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: AppColors.borderRadiusAll,
          ),
        ),
      ),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(AppColors.main),
        foregroundColor: WidgetStateProperty.all<Color>(AppColors.text),
        surfaceTintColor: WidgetStateProperty.all<Color>(AppColors.background),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: AppColors.borderRadiusAll,
          ),
        ),
        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
        ),
      ),
    ),
    // Checkbox
    checkboxTheme: CheckboxThemeData(
      checkColor: WidgetStateProperty.all<Color>(AppColors.background),
      overlayColor: WidgetStateProperty.all<Color>(AppColors.hover),
      side: BorderSide(
        color: AppColors.main,
        width: 2,
      ),
    ),
    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.deepWhite,
      foregroundColor: AppColors.black,
      splashColor: AppColors.hover,
      elevation: 3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(50)),
      ),
    ),
    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all<Color>(AppColors.lightMain),
      trackOutlineColor: WidgetStateProperty.all<Color>(AppColors.transparent),
    ),
    hintColor: AppColors.dirtyWhite,
    textSelectionTheme: TextSelectionThemeData(cursorColor: AppColors.cursor),
    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.appbar,
      contentTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 16,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    // card
    cardTheme: CardTheme(
      color: AppColors.background,
      shadowColor: AppColors.black,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppColors.borderRadiusAll,
      ),
    ),
    // TODO:default container radius

    // ---------------------

    // Color Scheme
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      // primary: AppColors.main,
      // onPrimary: AppColors.lightMain,
      // secondary: const Color.fromARGB(255, 0, 255, 213),
      // onSecondary: const Color.fromARGB(255, 0, 255, 0),
      // error: Colors.AppColors.red,
      // onError: const Color.fromARGB(255, 255, 0, 13),
      // surface: AppColors.onBackground,
      // onSurface: AppColors.background,

      primary: AppColors.main,
      onPrimary: AppColors.background,
      secondary: AppColors.lightMain,
      onSecondary: const Color.fromARGB(157, 0, 241, 0),
      error: AppColors.red,
      onError: const Color.fromARGB(255, 255, 0, 13),
      surface: AppColors.panelBackground2,
      onSurface: AppColors.text,

      // TODO: düzenlenecek. gerekli değilse kaldır
      // errorContainer: const Color(0xFF93000A),
      // onErrorContainer: const Color(0xFFFFDAD6),
      // primaryContainer: AppColors.main,
      // onPrimaryContainer: const Color(0xFFDCE1FF),
      // secondaryContainer: const Color(0xFF424659),
      // onSben önceliklecondaryContainer: const Color(0xFFDEE1F9),
      // tertiary: const Color(0xFFE3BADA),
      // onTertiary: const Color(0xFF43273F),
      // tertiaryContainer: const Color(0xFF5B3D57),
      // onTertiaryContainer: const Color(0xFFFFD7F5),
      // surfaceVariant: const Color(0xFF45464F),
      // onSurfaceVariant: const Color(0xFFC6C5D0),
      // outline: const Color(0xFF90909A),
      // onInverseSurface: const Color(0xFF1B1B1F),
      // inverseSurface: const Color(0xFFE4E1E6),
      // inversePrimary: AppColors.lightMain,
      // shadow: const Color(0xFF000000),
      // surfaceTint: const Color(0xFFB7C4FF),
      // outlineVariant: const Color(0xFF45464F),
      // scrim: const Color(0xFF000000),
    ),
  );
}
