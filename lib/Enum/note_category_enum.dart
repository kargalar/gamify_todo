import 'package:flutter/material.dart';

/// Not kategorileri için enum
enum NoteCategory {
  general,
  ideas,
  quotes,
  movies,
  books,
  music,
  learning,
  personal,
  work,
  other;

  /// Kategori için görünen isim (çoklu dil desteği için key)
  String get displayName {
    switch (this) {
      case NoteCategory.general:
        return 'Genel';
      case NoteCategory.ideas:
        return 'Fikirler';
      case NoteCategory.quotes:
        return 'Alıntılar';
      case NoteCategory.movies:
        return 'Film & Dizi';
      case NoteCategory.books:
        return 'Kitaplar';
      case NoteCategory.music:
        return 'Müzik';
      case NoteCategory.learning:
        return 'Öğrendiklerim';
      case NoteCategory.personal:
        return 'Kişisel';
      case NoteCategory.work:
        return 'İş';
      case NoteCategory.other:
        return 'Diğer';
    }
  }

  /// Kategori için ikon
  IconData get icon {
    switch (this) {
      case NoteCategory.general:
        return Icons.note;
      case NoteCategory.ideas:
        return Icons.lightbulb;
      case NoteCategory.quotes:
        return Icons.format_quote;
      case NoteCategory.movies:
        return Icons.movie;
      case NoteCategory.books:
        return Icons.menu_book;
      case NoteCategory.music:
        return Icons.music_note;
      case NoteCategory.learning:
        return Icons.school;
      case NoteCategory.personal:
        return Icons.person;
      case NoteCategory.work:
        return Icons.work;
      case NoteCategory.other:
        return Icons.more_horiz;
    }
  }

  /// Kategori için renk
  Color get color {
    switch (this) {
      case NoteCategory.general:
        return Colors.blue;
      case NoteCategory.ideas:
        return Colors.amber;
      case NoteCategory.quotes:
        return Colors.purple;
      case NoteCategory.movies:
        return Colors.red;
      case NoteCategory.books:
        return Colors.brown;
      case NoteCategory.music:
        return Colors.pink;
      case NoteCategory.learning:
        return Colors.green;
      case NoteCategory.personal:
        return Colors.teal;
      case NoteCategory.work:
        return Colors.indigo;
      case NoteCategory.other:
        return Colors.grey;
    }
  }
}
