import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerManager {
  ServerManager._privateConstructor();
  static final ServerManager _instance = ServerManager._privateConstructor();
  factory ServerManager() {
    return _instance;
  }

  // static const String _baseUrl = 'http://localhost:3001';
  // static const String _baseUrl = 'http://192.168.1.21:3001';
  // static const String _baseUrl = 'https://gamify-273bac1e9487.herokuapp.com';

  var dio = Dio();
  // --------------------------------------------w

  // check request
  void checkRequest(Response response) {
    if (response.statusCode == 200) {
      // debugPrint(json.encode(response.data));
    } else {
      debugPrint(response.statusMessage);
    }
  }

  // ********************************************

  Future<UserModel?> login({
    required String email,
    required String password,
    bool isAutoLogin = false,
  }) async {
    return null;

    // try {
    //   var response = await dio.post(
    //     "$_baseUrl/login",
    //     data: {
    //       'email': email,
    //       'password': password,
    //     },
    //   );

    //   return UserModel.fromJson(response.data);
    // } on DioException catch (e) {
    //   if (isAutoLogin) return null;

    //   if (e.response?.statusCode == 404) {
    //     // Show error message to the user
    //     Helper().getMessage(
    //       status: StatusEnum.WARNING,
    //       message: 'Email not found',
    //     );
    //   } else if (e.response?.statusCode == 401) {
    //     // Show error message to the user
    //     Helper().getMessage(
    //       status: StatusEnum.WARNING,
    //       message: 'Incorrect password',
    //     );
    //   } else {
    //     // Handle other errors
    //     Helper().getMessage(
    //       status: StatusEnum.WARNING,
    //       message: 'An error occurred: ${e.message}',
    //     );
    //   }
    //   return null;
    // }
  }

  Future<UserModel?> register({
    required String email,
    required String password,
  }) async {
    return null;

    // try {
    //   var response = await dio.post(
    //     "$_baseUrl/register",
    //     data: {
    //       'email': email,
    //       'password': password,
    //     },
    //   );

    //   checkRequest(response);

    //   return UserModel.fromJson(response.data);
    // } on DioException catch (e) {
    //   if (e.response?.statusCode == 409) {
    //     Helper().getMessage(
    //       status: StatusEnum.WARNING,
    //       message: 'User already exists',
    //     );
    //   } else {
    //     Helper().getMessage(
    //       status: StatusEnum.WARNING,
    //       message: 'An error occurred: ${e.message}',
    //     );
    //   }
    //   return null;
    // }
  }

  // get user
  // TODO: auto login system
  Future<UserModel?> getUser() async {
    // Return user only if exists, don't create guest user automatically
    return await HiveService().getUser(0);

    // var response = await dio.get(
    //   // TODO: user id shared pref den alınacak
    //   "$_baseUrl/getUser",
    //   queryParameters: {
    //     'user_id': loginUser!.id,
    //   },
    // );

    // checkRequest(response);

    // return UserModel.fromJson(response.data[0]);
  }

  // get items
  Future<List<ItemModel>> getItems() async {
    return await HiveService().getItems();

    // var response = await dio.get(
    //   "$_baseUrl/getItems",
    //   queryParameters: {
    //     'user_id': loginUser!.id,
    //   },
    // );

    // checkRequest(response);

    // return (response.data as List).map((e) => ItemModel.fromJson(e)).toList();
  }

  // get traits
  Future<List<TraitModel>> getTraits() async {
    return await HiveService().getTraits();

    // var response = await dio.get(
    //   "$_baseUrl/getTraits",
    //   queryParameters: {
    //     'user_id': loginUser!.id,
    //   },
    // );

    // checkRequest(response);

    // return (response.data as List).map((e) => TraitModel.fromJson(e)).toList();
  }

  // get routines
  Future<List<RoutineModel>> getRoutines() async {
    return await HiveService().getRoutines();

    // var response = await dio.get(
    //   "$_baseUrl/getRoutines",
    //   queryParameters: {
    //     'user_id': loginUser!.id,
    //   },
    // );

    // checkRequest(response);

    // return (response.data as List).map((e) => RoutineModel.fromJson(e)).toList();
  }

  // get tasks
  Future<List<TaskModel>> getTasks() async {
    return await HiveService().getTasks();

    // var response = await dio.get(
    //   "$_baseUrl/getTasks",
    //   queryParameters: {
    //     'user_id': loginUser!.id,
    //   },
    // );

    // checkRequest(response);

    // return (response.data as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  // get categories
  Future<List<CategoryModel>> getCategories() async {
    return await HiveService().getCategories();
  }

// -------------------

// // add user
//   Future<int> addUser({
//     required UserModel userModel,
//   }) async {
//     try {
//       var response = await dio.post(
//         "$_baseUrl/addUser",
//         data: userModel.toJson(),
//       );

//       checkRequest(response);

//       return response.data['id'];
//     } on DioException catch (e) {
//       debugPrint('Error adding user: ${e.message}');
//       rethrow;
//     }
//   }

// add item
  Future<int> addItem({
    required ItemModel itemModel,
  }) async {
    // TODO: SERVER MANAGER AKTİF OLDUĞUNDA ID SERVER MANAGERDAN GELEN İD OLACAK. yani zaten buna gerek olmayacak. server managere kaydeildikten sonra hive kaydedilecek ???????????

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int id = prefs.getInt("last_item_id") ?? 0;

    itemModel.id = id + 1;

    // Save locally first
    HiveService().addItem(itemModel);

    prefs.setInt("last_item_id", itemModel.id);

    return itemModel.id;

    // try {
    //   var response = await dio.post(
    //     "$_baseUrl/addItem",
    //     queryParameters: {
    //       'user_id': loginUser!.id,
    //     },
    //     data: itemModel.toJson(),
    //   );

    //   checkRequest(response);

    //   return response.data['id'];
    // } on DioException catch (e) {
    //   debugPrint('Error adding item: ${e.message}');
    //   rethrow;
    // }
  }

// add trait
  Future<int> addTrait({
    required TraitModel traitModel,
  }) async {
    // TODO: SERVER MANAGER AKTİF OLDUĞUNDA ID SERVER MANAGERDAN GELEN İD OLACAK. yani zaten buna gerek olmayacak. server managere kaydeildikten sonra hive kaydedilecek ???????????

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int id = prefs.getInt("last_trait_id") ?? 0;

    traitModel.id = id + 1;

    HiveService().addTrait(traitModel);

    prefs.setInt("last_trait_id", traitModel.id);

    return traitModel.id;

    // try {
    //   var response = await dio.post(
    //     "$_baseUrl/addTrait",
    //     queryParameters: {
    //       'user_id': loginUser!.id,
    //     },
    //     data: traitModel.toJson(),
    //   );

    //   checkRequest(response);

    //   return response.data['id'];
    // } on DioException catch (e) {
    //   debugPrint('Error adding trait: ${e.message}');
    //   rethrow;
    // }
  }

// add routine
  Future<int> addRoutine({
    required RoutineModel routineModel,
  }) async {
    // TODO: SERVER MANAGER AKTİF OLDUĞUNDA ID SERVER MANAGERDAN GELEN İD OLACAK. yani zaten buna gerek olmayacak. server managere kaydeildikten sonra hive kaydedilecek ???????????

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int lastId = prefs.getInt("last_routine_id") ?? 0;

    // Get all existing routines to ensure we don't have ID conflicts
    final existingRoutines = await HiveService().getRoutines();

    // Find the highest ID among existing routines
    int highestId = lastId;
    for (final routine in existingRoutines) {
      if (routine.id > highestId) {
        highestId = routine.id;
      }
    }

    // Set the new routine ID to be one higher than the highest existing ID
    routineModel.id = highestId + 1;

    // Save the routine
    await HiveService().addRoutine(routineModel);

    // Update the last routine ID in SharedPreferences
    await prefs.setInt("last_routine_id", routineModel.id);

    return routineModel.id;

    // try {
    //   var response = await dio.post(
    //     "$_baseUrl/addRoutine",
    //     queryParameters: {
    //       'user_id': loginUser!.id,
    //     },
    //     data: routineModel.toJson(),
    //   );

    //   checkRequest(response);

    //   return response.data['id'];
    // } on DioException catch (e) {
    //   debugPrint('Error adding routine: ${e.message}');
    //   rethrow;
    // }
  }

// add task
  Future<int> addTask({
    required TaskModel taskModel,
  }) async {
    // TODO: SERVER MANAGER AKTİF OLDUĞUNDA ID SERVER MANAGERDAN GELEN İD OLACAK. yani zaten buna gerek olmayacak. server managere kaydeildikten sonra hive kaydedilecek ???????????

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int lastId = prefs.getInt("last_task_id") ?? 0;

    // Get all existing tasks to ensure we don't have ID conflicts
    final existingTasks = await HiveService().getTasks();

    // Find the highest ID among existing tasks
    int highestId = lastId;
    for (final task in existingTasks) {
      if (task.id > highestId) {
        highestId = task.id;
      }
    }

    // Set the new task ID to be one higher than the highest existing ID
    taskModel.id = highestId + 1;

    // Save the task locally
    await HiveService().addTask(taskModel);

    // Update the last task ID in SharedPreferences
    await prefs.setInt("last_task_id", taskModel.id);

    return taskModel.id;
  }

  // add category
  Future<int> addCategory({
    required CategoryModel categoryModel,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int id = prefs.getInt("last_category_id") ?? 0;

    categoryModel.id = id + 1;

    HiveService().addCategory(categoryModel);

    prefs.setInt("last_category_id", categoryModel.id);

    return categoryModel.id;

    // return uniqueID;

    // var response = await dio.post(
    //   "$_baseUrl/addTask",
    //   queryParameters: {
    //     'user_id': loginUser!.id,
    //   },
    //   data: taskModel.toJson(),
    // );

    // checkRequest(response);

    // return response.data['id'];
  }

  // ------------------------

  // update user
  Future<void> updateUser({
    required UserModel userModel,
  }) async {
    HiveService().updateUser(userModel);

    // var response = await dio.put(
    //   "$_baseUrl/updateUser",
    //   data: userModel.toJson(),
    // );

    // checkRequest(response);
  }

  // update items
  Future<void> updateItem({
    required ItemModel itemModel,
  }) async {
    // Save locally first
    HiveService().updateItem(itemModel);

    // var response = await dio.put(
    //   "$_baseUrl/updateItem",
    //   data: itemModel.toJson(),
    // );

    // checkRequest(response);
  }

  // update trait
  Future<void> updateTrait({
    required TraitModel traitModel,
  }) async {
    HiveService().updateTrait(traitModel);

    // var response = await dio.put(
    //   "$_baseUrl/updateTrait",
    //   data: traitModel.toJson(),
    // );

    // checkRequest(response);
  }

  // update routines
  Future<void> updateRoutine({
    required RoutineModel routineModel,
  }) async {
    HiveService().updateRoutine(routineModel);

    // var response = await dio.put(
    //   "$_baseUrl/updateRoutine",
    //   data: routineModel.toJson(),
    // );

    // checkRequest(response);
  }

  // update tasks
  Future<void> updateTask({
    required TaskModel taskModel,
  }) async {
    // Save locally first
    HiveService().updateTask(taskModel);

    // var response = await dio.put(
    //   "$_baseUrl/updateTask",
    //   data: taskModel.toJson(),
    // );

    // checkRequest(response);
  }

  // update category
  Future<void> updateCategory({
    required CategoryModel categoryModel,
  }) async {
    HiveService().updateCategory(categoryModel);
  }

  // delete item
  Future<void> deleteItem({
    required int id,
  }) async {
    HiveService().deleteItem(id);

    // var response = await dio.delete(
    //   "$_baseUrl/deleteItem",
    //   queryParameters: {
    //     'item_id': id,
    //   },
    // );

    // checkRequest(response);
  }

  // delete trait
  Future<void> deleteTrait({
    required int id,
  }) async {
    HiveService().deleteTrait(id);

    // var response = await dio.delete(
    //   "$_baseUrl/deleteTrait",
    //   queryParameters: {
    //     'trait_id': id,
    //   },
    // );

    // checkRequest(response);
  }

  // delete routine
  Future<void> deleteRoutine({
    required int id,
  }) async {
    HiveService().deleteRoutine(id);

    // var response = await dio.delete(
    //   "$_baseUrl/deleteRoutine",
    //   queryParameters: {
    //     'routine_id': id,
    //   },
    // );

    // checkRequest(response);
  }

  // delete task
  Future<void> deleteTask({
    required int id,
  }) async {
    await HiveService().deleteTask(id);

    // var response = await dio.delete(
    //   "$_baseUrl/deleteTask",
    //   queryParameters: {
    //     'task_id': id,
    //   },
    // );

    // checkRequest(response);
  }

  // delete category
  Future<void> deleteCategory({
    required CategoryModel categoryModel,
  }) async {
    HiveService().deleteCategory(categoryModel.id);
  }

  // trigger tasks !!!!! normalde bu kullanılmıyor. 00:00 olduğunda otomatik backendde yapılıyor. test etmek için böyle koyuldu.
}
