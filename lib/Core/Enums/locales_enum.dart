import 'package:flutter/material.dart';

/// Project locale enum for operation and configuration
enum Locales {
  /// English locale
  en(Locale('en', 'US')),

  /// French locale
  fr(Locale('fr', 'FR')),

  /// German locale
  de(Locale('de', 'DE')),

  /// Russian locale
  ru(Locale('ru', 'RU')),

  /// Turkish locale
  tr(Locale('tr', 'TR'));

  /// Locale value
  final Locale locale;

  const Locales(this.locale);
}
