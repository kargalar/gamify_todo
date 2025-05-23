import 'package:flutter/material.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Service/server_manager.dart';

class CategoryProvider extends ChangeNotifier {
  static final CategoryProvider _instance = CategoryProvider._internal();

  factory CategoryProvider() {
    return _instance;
  }

  CategoryProvider._internal();

  List<CategoryModel> categoryList = [];

  void addCategory(CategoryModel categoryModel) async {
    final int categoryId = await ServerManager().addCategory(categoryModel: categoryModel);

    categoryModel.id = categoryId;
    categoryList.add(categoryModel);

    notifyListeners();
  }

  void updateCategory(CategoryModel categoryModel) async {
    await ServerManager().updateCategory(categoryModel: categoryModel);

    final index = categoryList.indexWhere((category) => category.id == categoryModel.id);
    if (index != -1) {
      categoryList[index] = categoryModel;
    }

    notifyListeners();
  }

  void deleteCategory(CategoryModel categoryModel) async {
    await ServerManager().deleteCategory(categoryModel: categoryModel);

    categoryList.removeWhere((category) => category.id == categoryModel.id);

    notifyListeners();
  }

  void archiveCategory(CategoryModel categoryModel) async {
    categoryModel.isArchived = true;
    await ServerManager().updateCategory(categoryModel: categoryModel);

    final index = categoryList.indexWhere((category) => category.id == categoryModel.id);
    if (index != -1) {
      categoryList[index] = categoryModel;
    }

    notifyListeners();
  }

  CategoryModel? getCategoryById(int? categoryId) {
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
