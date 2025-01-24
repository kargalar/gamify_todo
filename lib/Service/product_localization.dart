import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/Enums/locales_enum.dart';
import 'package:get/route_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable

/// Product localization manager
final class ProductLocalization extends EasyLocalization {
  /// ProductLocalization need to [child] for a wrap locale item
  ProductLocalization({
    required super.child,
    super.key,
  }) : super(
          supportedLocales: _supportedItems,
          path: _translationPath,
          useOnlyLangCode: true,
        );

  static final List<Locale> _supportedItems = [
    Locales.en.locale,
    Locales.fr.locale,
    Locales.de.locale,
    Locales.ru.locale,
    Locales.tr.locale,
  ];

  static const String _translationPath = 'assets/translations';

  /// Change project language by using [Locales]
  static Future<void> updateLanguage({
    required BuildContext context,
    required Locales value,
  }) =>
      context.setLocale(value.locale);

  static void saveSelectedLanguage(Locales value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', value.toString());
    Get.updateLocale(value.locale);
  }
}
