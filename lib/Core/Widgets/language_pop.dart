import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/locales_enum.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/product_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSelectionPopup extends StatefulWidget {
  const LanguageSelectionPopup({super.key});

  @override
  LanguageSelectionPopupState createState() => LanguageSelectionPopupState();
}

class LanguageSelectionPopupState extends State<LanguageSelectionPopup> {
  late Locales _selectedLanguage;
  late Locales oldSelectedLanguage;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      // Shared preferences'ten seçilen dilin yüklenmesi
      _selectedLanguage = Locales.values.firstWhere((locale) => locale.toString() == (prefs.getString('selected_language') ?? Locales.en.toString()));
      oldSelectedLanguage = _selectedLanguage;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : AlertDialog(
            title: Text(LocaleKeys.SelectLanguage.tr()),
            content: RadioGroup<Locales>(
              groupValue: _selectedLanguage,
              onChanged: (Locales? value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                  _saveSelectedLanguage();
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: Locales.values
                    .map(
                      (locale) => RadioListTile<Locales>(
                        value: locale,
                        title: Text(
                          _getLocaleName(locale),
                          style: TextStyle(
                            fontWeight: locale == _selectedLanguage ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          );
  }

  String _getLocaleName(Locales locale) {
    switch (locale) {
      case Locales.en:
        return "English";
      // case Locales.de:
      //   return "Deutsch";
      // case Locales.fr:
      //   return "Français";
      // case Locales.ru:
      //   return "русский";
      // case Locales.tr:
      //   return "Türkçe";
    }
  }

  Future<void> _saveSelectedLanguage() async {
    await ProductLocalization.updateLanguage(
      context: context,
      value: _selectedLanguage,
    );

    ProductLocalization.saveSelectedLanguage(_selectedLanguage);
  }
}
