import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:next_level/Model/note_category_model.dart';

class NoteCategoryService {
  static const String _boxName = 'note_categories';
  static Box<NoteCategoryModel>? _box;

  /// Initialize Hive box
  static Future<void> initialize() async {
    try {
      _box = await Hive.openBox<NoteCategoryModel>(_boxName);
      debugPrint('✅ NoteCategoryService: Box initialized with ${_box!.length} categories');

      // İlk açılışta default kategoriler ekle
      if (_box!.isEmpty) {
        await _addDefaultCategories();
      }
    } catch (e) {
      debugPrint('❌ NoteCategoryService: Error initializing box: $e');
    }
  }

  /// Get all categories
  static List<NoteCategoryModel> getCategories() {
    try {
      if (_box == null || !_box!.isOpen) {
        debugPrint('❌ NoteCategoryService: Box is not initialized');
        return [];
      }

      final categories = _box!.values.toList();
      // Oluşturulma tarihine göre sırala
      categories.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      debugPrint('📋 NoteCategoryService: Retrieved ${categories.length} categories');
      return categories;
    } catch (e) {
      debugPrint('❌ NoteCategoryService: Error getting categories: $e');
      return [];
    }
  }

  /// Get category by ID
  static NoteCategoryModel? getCategoryById(String id) {
    try {
      if (_box == null || !_box!.isOpen) {
        debugPrint('❌ NoteCategoryService: Box is not initialized');
        return null;
      }

      return _box!.values.firstWhere(
        (category) => category.id == id,
        orElse: () => NoteCategoryModel(
          id: '',
          name: 'Kategori Yok',
          iconCodePoint: Icons.help_outline.codePoint,
          colorValue: Colors.grey.toARGB32(),
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('❌ NoteCategoryService: Error getting category by id: $e');
      return null;
    }
  }

  /// Add new category
  static Future<bool> addCategory(NoteCategoryModel category) async {
    try {
      if (_box == null || !_box!.isOpen) {
        debugPrint('❌ NoteCategoryService: Box is not initialized');
        return false;
      }

      await _box!.add(category);
      debugPrint('✅ NoteCategoryService: Category added: ${category.name}');
      return true;
    } catch (e) {
      debugPrint('❌ NoteCategoryService: Error adding category: $e');
      return false;
    }
  }

  /// Update category
  static Future<bool> updateCategory(NoteCategoryModel category) async {
    try {
      if (_box == null || !_box!.isOpen) {
        debugPrint('❌ NoteCategoryService: Box is not initialized');
        return false;
      }

      await category.save();
      debugPrint('✅ NoteCategoryService: Category updated: ${category.name}');
      return true;
    } catch (e) {
      debugPrint('❌ NoteCategoryService: Error updating category: $e');
      return false;
    }
  }

  /// Delete category
  static Future<bool> deleteCategory(String id) async {
    try {
      if (_box == null || !_box!.isOpen) {
        debugPrint('❌ NoteCategoryService: Box is not initialized');
        return false;
      }

      final category = _box!.values.firstWhere((cat) => cat.id == id);
      await category.delete();
      debugPrint('✅ NoteCategoryService: Category deleted: $id');
      return true;
    } catch (e) {
      debugPrint('❌ NoteCategoryService: Error deleting category: $e');
      return false;
    }
  }

  /// Add default categories on first launch
  static Future<void> _addDefaultCategories() async {
    final defaultCategories = [
      NoteCategoryModel(
        id: 'cat_general',
        name: 'Genel',
        iconCodePoint: Icons.note.codePoint,
        colorValue: Colors.blue.toARGB32(),
        createdAt: DateTime.now(),
      ),
      NoteCategoryModel(
        id: 'cat_ideas',
        name: 'Fikirler',
        iconCodePoint: Icons.lightbulb.codePoint,
        colorValue: Colors.amber.toARGB32(),
        createdAt: DateTime.now(),
      ),
      NoteCategoryModel(
        id: 'cat_quotes',
        name: 'Alıntılar',
        iconCodePoint: Icons.format_quote.codePoint,
        colorValue: Colors.purple.toARGB32(),
        createdAt: DateTime.now(),
      ),
    ];

    for (var category in defaultCategories) {
      await addCategory(category);
    }

    debugPrint('✅ NoteCategoryService: Default categories added');
  }
}
