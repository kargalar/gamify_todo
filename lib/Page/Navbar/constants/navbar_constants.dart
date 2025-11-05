import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class NavbarConstants {
  static List<BottomNavigationBarItem> getNavbarItems() {
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.store),
        label: StringTranslateExtension(LocaleKeys.Store).tr(),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.list),
        label: StringTranslateExtension(LocaleKeys.Inbox).tr(),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.tag),
        label: StringTranslateExtension(LocaleKeys.Categories).tr(),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.note),
        label: StringTranslateExtension(LocaleKeys.MyNotes).tr(),
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.folder_outlined),
        label: 'Projects',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_rounded),
        label: StringTranslateExtension(LocaleKeys.Profile).tr(),
      ),
    ];
  }
}
