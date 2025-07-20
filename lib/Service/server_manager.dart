import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/firebase_service.dart';
import 'package:next_level/Service/id_service.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Model/user_model.dart';

class ServerManager extends ChangeNotifier {
  ServerManager._privateConstructor();
  static final ServerManager _instance = ServerManager._privateConstructor();
  factory ServerManager() {
    return _instance;
  }

  final FirebaseService _firebaseService = FirebaseService();

  // static const String _baseUrl = 'http://localhost:3001';
  // static const String _baseUrl = 'http://192.168.1.21:3001';
  // static const String _baseUrl = 'https://gamify-273bac1e9487.herokuapp.com';

  var dio = Dio();
  // --------------------------------------------

  // Sync all data bidirectionally
  Future<void> syncAllData() async {
    // Check if user is authenticated with Firebase
    if (_firebaseService.currentUserUid == null) {
      debugPrint('⚠️ User not authenticated with Firebase, skipping sync');
      return;
    }

    try {
      debugPrint('🔄 Starting bidirectional sync...');
      await _firebaseService.bidirectionalSync();
      debugPrint('✅ Bidirectional sync completed');
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
    }
  }

  // Sync data from Firebase to local (for app startup)
  Future<void> syncFromFirebase() async {
    // Check if user is authenticated with Firebase
    if (_firebaseService.currentUserUid == null) {
      debugPrint('⚠️ User not authenticated with Firebase, skipping sync');
      return;
    }

    try {
      debugPrint('🔄 Syncing from Firebase...');
      await _firebaseService.syncFromFirebase();
      debugPrint('✅ Firebase sync completed');
    } catch (e) {
      debugPrint('❌ Firebase sync failed: $e');
    }
  }

  // Sync data from local to Firebase (for app exit)
  Future<void> syncToFirebase() async {
    // Check if user is authenticated with Firebase
    if (_firebaseService.currentUserUid == null) {
      debugPrint('⚠️ User not authenticated with Firebase, skipping sync');
      return;
    }

    try {
      debugPrint('🔄 Syncing to Firebase...');
      await _firebaseService.syncToFirebase();
      debugPrint('✅ Firebase sync completed');
    } catch (e) {
      debugPrint('❌ Firebase sync failed: $e');
    }
  }

  // Start real-time sync
  Future<void> startRealTimeSync() async {
    // Check if user is authenticated with Firebase
    if (_firebaseService.currentUserUid == null) {
      debugPrint('⚠️ User not authenticated with Firebase, skipping real-time sync');
      return;
    }

    try {
      debugPrint('🔄 Starting real-time sync...');
      await _firebaseService.startRealTimeSync();
      debugPrint('✅ Real-time sync started');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Real-time sync failed to start: $e');
    }
  }

  // Stop real-time sync
  Future<void> stopRealTimeSync() async {
    try {
      debugPrint('🔄 Stopping real-time sync...');
      await _firebaseService.stopRealTimeSync();
      debugPrint('✅ Real-time sync stopped');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Real-time sync failed to stop: $e');
    }
  }

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
    // Generate unique timestamp-based ID
    itemModel.id = IdService().generateItemId();
    debugPrint('Generated unique item ID: ${itemModel.id}');

    // Save to local storage first
    await HiveService().addItem(itemModel);

    // Then sync to Firebase (only if user is authenticated)
    if (_firebaseService.currentUserUid != null) {
      await _firebaseService.addItemToFirebase(itemModel);
    } else {
      debugPrint('⚠️ User not authenticated, item not synced to Firebase');
    }

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
    // Generate unique timestamp-based ID
    traitModel.id = IdService().generateTraitId();
    debugPrint('Generated unique trait ID: ${traitModel.id}');

    // Save to local storage first
    await HiveService().addTrait(traitModel);

    // Then sync to Firebase (traits don't have individual Firebase methods yet, will be synced in bulk)
    // await _firebaseService.addTraitToFirebase(traitModel);

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
    // Generate unique timestamp-based ID
    routineModel.id = IdService().generateRoutineId();
    debugPrint('Generated unique routine ID: ${routineModel.id}');

    // Save to local storage first
    await HiveService().addRoutine(routineModel);

    // Then sync to Firebase (routines don't have individual Firebase methods yet, will be synced in bulk)
    // await _firebaseService.addRoutineToFirebase(routineModel);

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
    // Generate unique timestamp-based ID
    taskModel.id = IdService().generateTaskId();
    debugPrint('Generated unique task ID: ${taskModel.id}');

    // Save to local storage first
    await HiveService().addTask(taskModel);

    // Then sync to Firebase (only if user is authenticated)
    if (_firebaseService.currentUserUid != null) {
      await _firebaseService.addTaskToFirebase(taskModel);
    } else {
      debugPrint('⚠️ User not authenticated, task not synced to Firebase');
    }

    return taskModel.id;
  }

  // add category
  Future<int> addCategory({
    required CategoryModel categoryModel,
  }) async {
    // Generate unique timestamp-based ID
    categoryModel.id = IdService().generateCategoryId();
    debugPrint('Generated unique category ID: ${categoryModel.id}');

    HiveService().addCategory(categoryModel);

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
    // Update local storage first
    await HiveService().updateUser(userModel);

    // Then sync to Firebase (user updates are handled in bulk sync)
    // await _firebaseService.updateUserInFirebase(userModel);
  }

  // update items
  Future<void> updateItem({
    required ItemModel itemModel,
  }) async {
    // Update local storage first
    await HiveService().updateItem(itemModel);

    // Then sync to Firebase (only if user is authenticated)
    if (_firebaseService.currentUserUid != null) {
      await _firebaseService.updateItemInFirebase(itemModel);
    } else {
      debugPrint('⚠️ User not authenticated, item update not synced to Firebase');
    }
  }

  // update trait
  Future<void> updateTrait({
    required TraitModel traitModel,
  }) async {
    // Update local storage first
    await HiveService().updateTrait(traitModel);

    // Then sync to Firebase (traits are handled in bulk sync)
    // await _firebaseService.updateTraitInFirebase(traitModel);
  }

  // update routines
  Future<void> updateRoutine({
    required RoutineModel routineModel,
  }) async {
    // Update local storage first
    await HiveService().updateRoutine(routineModel);

    // Then sync to Firebase (routines are handled in bulk sync)
    // await _firebaseService.updateRoutineInFirebase(routineModel);
  }

  // update tasks
  Future<void> updateTask({
    required TaskModel taskModel,
  }) async {
    // Update local storage first
    await HiveService().updateTask(taskModel);

    // Then sync to Firebase (only if user is authenticated)
    if (_firebaseService.currentUserUid != null) {
      await _firebaseService.updateTaskInFirebase(taskModel);
    } else {
      debugPrint('⚠️ User not authenticated, task update not synced to Firebase');
    }
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
    // Delete from local storage first
    await HiveService().deleteItem(id);

    // Then delete from Firebase (only if user is authenticated)
    if (_firebaseService.currentUserUid != null) {
      await _firebaseService.deleteItemFromFirebase(id);
    } else {
      debugPrint('⚠️ User not authenticated, item deletion not synced to Firebase');
    }
  }

  // delete trait
  Future<void> deleteTrait({
    required int id,
  }) async {
    // Delete from local storage first
    await HiveService().deleteTrait(id);

    // Then sync to Firebase (traits are handled in bulk sync)
    // await _firebaseService.deleteTraitFromFirebase(id);
  }

  // delete routine
  Future<void> deleteRoutine({
    required int id,
  }) async {
    // Delete from local storage first
    await HiveService().deleteRoutine(id);

    // Then sync to Firebase (routines are handled in bulk sync)
    // await _firebaseService.deleteRoutineFromFirebase(id);
  }

  // delete task
  Future<void> deleteTask({
    required int id,
  }) async {
    // Delete from local storage first
    await HiveService().deleteTask(id);

    // Then delete from Firebase (only if user is authenticated)
    if (_firebaseService.currentUserUid != null) {
      await _firebaseService.deleteTaskFromFirebase(id);
    } else {
      debugPrint('⚠️ User not authenticated, task deletion not synced to Firebase');
    }
  }

  // delete category
  Future<void> deleteCategory({
    required CategoryModel categoryModel,
  }) async {
    HiveService().deleteCategory(categoryModel.id);
  }

  // trigger tasks !!!!! normalde bu kullanılmıyor. 00:00 olduğunda otomatik backendde yapılıyor. test etmek için böyle koyuldu.

  // Real-time sync status
  bool get isRealTimeSyncActive => _firebaseService.isRealTimeSyncActive;

  // Real-time sync methods
}
