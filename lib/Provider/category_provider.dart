import 'package:flutter/material.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Service/hive_service.dart';

class CategoryProvider extends ChangeNotifier {
  static final CategoryProvider _instance = CategoryProvider._internal();

  factory CategoryProvider() {
    return _instance;
  }

  CategoryProvider._internal();

  List<CategoryModel> categoryList = [];

  Future<void> initialize() async {
    try {
      categoryList = await HiveService().getCategories();
      debugPrint('✅ CategoryProvider: Loaded ${categoryList.length} categories');
    } catch (e) {
      debugPrint('⚠️ CategoryProvider: Error loading categories (possibly data migration issue): $e');
      debugPrint('🧹 CategoryProvider: Clearing category box and starting fresh');

      // Clear the box if there's a migration error
      await HiveService().clearCategoryBox();
      categoryList = [];
      debugPrint('✅ CategoryProvider: Category box cleared, starting with empty list');
    }
    notifyListeners();
  }

  Future<void> addCategory(CategoryModel categoryModel) async {
    final String categoryId = await ServerManager().addCategory(categoryModel: categoryModel);

    categoryModel.id = categoryId;
    categoryList.add(categoryModel);

    notifyListeners();
  }

  Future<void> updateCategory(CategoryModel categoryModel) async {
    await ServerManager().updateCategory(categoryModel: categoryModel);

    final index = categoryList.indexWhere((category) => category.id == categoryModel.id);
    if (index != -1) {
      categoryList[index] = categoryModel;
    }

    notifyListeners();
  }

  Future<void> deleteCategory(CategoryModel categoryModel) async {
    debugPrint('🗑️ CategoryProvider: Deleting category ${categoryModel.id}');

    await ServerManager().deleteCategory(categoryModel: categoryModel);

    categoryList.removeWhere((category) => category.id == categoryModel.id);

    debugPrint('✅ CategoryProvider: Category deleted, remaining: ${categoryList.length}');

    notifyListeners();
  }

  Future<void> archiveCategory(CategoryModel categoryModel) async {
    categoryModel.isArchived = true;
    await ServerManager().updateCategory(categoryModel: categoryModel);

    final index = categoryList.indexWhere((category) => category.id == categoryModel.id);
    if (index != -1) {
      categoryList[index] = categoryModel;
    }

    notifyListeners();
  }

  CategoryModel? getCategoryById(String? categoryId) {
    if (categoryId == null) return null;

    try {
      return categoryList.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  List<CategoryModel> getActiveCategories() {
    return categoryList.where((category) => !category.isArchived).toList();
  }
}
