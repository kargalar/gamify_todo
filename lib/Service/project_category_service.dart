import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:next_level/Model/project_category_model.dart';

class ProjectCategoryService {
  static const String _boxName = 'project_categories';
  static Box<ProjectCategoryModel>? _box;

  /// Initialize Hive box
  static Future<void> initialize() async {
    try {
      _box = await Hive.openBox<ProjectCategoryModel>(_boxName);
      debugPrint('✅ ProjectCategoryService: Box initialized with ${_box!.length} categories');

      // İlk açılışta default kategoriler ekle
      if (_box!.isEmpty) {
        await _addDefaultCategories();
      }
    } catch (e) {
      debugPrint('❌ ProjectCategoryService: Error initializing box: $e');
    }
  }

  /// Get all categories
  static List<ProjectCategoryModel> getCategories() {
    try {
      if (_box == null || !_box!.isOpen) {
        debugPrint('❌ ProjectCategoryService: Box is not initialized');
        return [];
      }

      final categories = _box!.values.toList();
      // Oluşturulma tarihine göre sırala
      categories.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      debugPrint('📋 ProjectCategoryService: Retrieved ${categories.length} categories');
      return categories;
    } catch (e) {
      debugPrint('❌ ProjectCategoryService: Error getting categories: $e');
      return [];
    }
  }

  /// Get category by ID
  static ProjectCategoryModel? getCategoryById(String id) {
    try {
      if (_box == null || !_box!.isOpen) {
        debugPrint('❌ ProjectCategoryService: Box is not initialized');
        return null;
      }

      return _box!.values.firstWhere(
        (category) => category.id == id,
        orElse: () => ProjectCategoryModel(
          id: '',
          name: 'Kategori Yok',
          iconCodePoint: Icons.help_outline.codePoint,
          colorValue: Colors.grey.toARGB32(),
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('❌ ProjectCategoryService: Error getting category by id: $e');
      return null;
    }
  }

  /// Add new category
  static Future<bool> addCategory(ProjectCategoryModel category) async {
    try {
      if (_box == null || !_box!.isOpen) {
        debugPrint('❌ ProjectCategoryService: Box is not initialized');
        return false;
      }

      await _box!.add(category);
      debugPrint('✅ ProjectCategoryService: Category added: ${category.name}');
      return true;
    } catch (e) {
      debugPrint('❌ ProjectCategoryService: Error adding category: $e');
      return false;
    }
  }

  /// Update category
  static Future<bool> updateCategory(ProjectCategoryModel category) async {
    try {
      if (_box == null || !_box!.isOpen) {
        debugPrint('❌ ProjectCategoryService: Box is not initialized');
        return false;
      }

      await category.save();
      debugPrint('✅ ProjectCategoryService: Category updated: ${category.name}');
      return true;
    } catch (e) {
      debugPrint('❌ ProjectCategoryService: Error updating category: $e');
      return false;
    }
  }

  /// Delete category
  static Future<bool> deleteCategory(String id) async {
    try {
      if (_box == null || !_box!.isOpen) {
        debugPrint('❌ ProjectCategoryService: Box is not initialized');
        return false;
      }

      final category = _box!.values.firstWhere((cat) => cat.id == id);
      await category.delete();
      debugPrint('✅ ProjectCategoryService: Category deleted: $id');
      return true;
    } catch (e) {
      debugPrint('❌ ProjectCategoryService: Error deleting category: $e');
      return false;
    }
  }

  /// Add default categories on first launch
  static Future<void> _addDefaultCategories() async {
    final defaultCategories = [
      ProjectCategoryModel(
        id: 'proj_cat_work',
        name: 'İş',
        iconCodePoint: Icons.work.codePoint,
        colorValue: Colors.blue.toARGB32(),
        createdAt: DateTime.now(),
      ),
      ProjectCategoryModel(
        id: 'proj_cat_personal',
        name: 'Kişisel',
        iconCodePoint: Icons.person.codePoint,
        colorValue: Colors.green.toARGB32(),
        createdAt: DateTime.now(),
      ),
      ProjectCategoryModel(
        id: 'proj_cat_learning',
        name: 'Öğrenme',
        iconCodePoint: Icons.school.codePoint,
        colorValue: Colors.orange.toARGB32(),
        createdAt: DateTime.now(),
      ),
      ProjectCategoryModel(
        id: 'proj_cat_hobby',
        name: 'Hobi',
        iconCodePoint: Icons.sports_esports.codePoint,
        colorValue: Colors.purple.toARGB32(),
        createdAt: DateTime.now(),
      ),
    ];

    for (var category in defaultCategories) {
      await addCategory(category);
    }

    debugPrint('✅ ProjectCategoryService: Default categories added');
  }
}
