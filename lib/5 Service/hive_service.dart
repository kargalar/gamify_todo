import 'dart:convert';
import 'dart:io';

import 'package:gamify_todo/1%20Core/extensions.dart';
import 'package:gamify_todo/1%20Core/helper.dart';
import 'package:gamify_todo/5%20Service/locale_keys.g.dart';
import 'package:gamify_todo/5%20Service/navigator_service.dart';
import 'package:gamify_todo/6%20Provider/task_provider.dart';
import 'package:gamify_todo/6%20Provider/store_provider.dart';
import 'package:gamify_todo/6%20Provider/trait_provider.dart';
import 'package:gamify_todo/7%20Enum/task_status_enum.dart';
import 'package:gamify_todo/7%20Enum/task_type_enum.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gamify_todo/8%20Model/user_model.dart';
import 'package:gamify_todo/8%20Model/store_item_model.dart';
import 'package:gamify_todo/8%20Model/task_model.dart';
import 'package:gamify_todo/8%20Model/trait_model.dart';
import 'package:gamify_todo/8%20Model/routine_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';

class HiveService {
  static const String _userBoxName = 'userBox';
  static const String _itemBoxName = 'itemBox';
  static const String _traitBoxName = 'traitBox';
  static const String _routineBoxName = 'routineBox';
  static const String _taskBoxName = 'taskBox';

  Future<Box<UserModel>> get _userBox async => await Hive.openBox<UserModel>(_userBoxName);
  Future<Box<ItemModel>> get _itemBox async => await Hive.openBox<ItemModel>(_itemBoxName);
  Future<Box<TraitModel>> get _traitBox async => await Hive.openBox<TraitModel>(_traitBoxName);
  Future<Box<RoutineModel>> get _routineBox async => await Hive.openBox<RoutineModel>(_routineBoxName);
  Future<Box<TaskModel>> get _taskBox async => await Hive.openBox<TaskModel>(_taskBoxName);

  // User methods
  Future<void> addUser(UserModel userModel) async {
    final box = await _userBox;
    await box.put(userModel.id, userModel);
  }

  Future<UserModel?> getUser(int id) async {
    final box = await _userBox;
    return box.get(id);
  }

  Future<void> updateUser(UserModel userModel) async {
    final box = await _userBox;
    await box.put(userModel.id, userModel);
  }

  // Item methods
  Future<void> addItem(ItemModel itemModel) async {
    final box = await _itemBox;
    await box.put(itemModel.id, itemModel);
  }

  Future<List<ItemModel>> getItems() async {
    final box = await _itemBox;
    return box.values.toList();
  }

  Future<void> updateItem(ItemModel itemModel) async {
    final box = await _itemBox;
    await box.put(itemModel.id, itemModel);
  }

  Future<void> deleteItem(int id) async {
    final box = await _itemBox;
    await box.delete(id);
  }

  // Trait methods
  Future<void> addTrait(TraitModel traitModel) async {
    final box = await _traitBox;
    await box.put(traitModel.id, traitModel);
  }

  Future<List<TraitModel>> getTraits() async {
    final box = await _traitBox;
    return box.values.toList();
  }

  Future<void> updateTrait(TraitModel traitModel) async {
    final box = await _traitBox;
    await box.put(traitModel.id, traitModel);
  }

  Future<void> deleteTrait(int id) async {
    final box = await _traitBox;
    await box.delete(id);
  }

  // Routine methods
  Future<void> addRoutine(RoutineModel routineModel) async {
    final box = await _routineBox;
    await box.put(routineModel.id, routineModel);
  }

  Future<List<RoutineModel>> getRoutines() async {
    final box = await _routineBox;
    return box.values.toList();
  }

  Future<void> updateRoutine(RoutineModel routineModel) async {
    final box = await _routineBox;
    await box.put(routineModel.id, routineModel);
  }

  Future<void> deleteRoutine(int id) async {
    final box = await _routineBox;
    await box.delete(id);
  }

  // Task methods
  Future<void> addTask(TaskModel taskModel) async {
    final box = await _taskBox;
    await box.put(taskModel.id, taskModel);
  }

  Future<List<TaskModel>> getTasks() async {
    final box = await _taskBox;
    return box.values.toList();
  }

  Future<void> updateTask(TaskModel taskModel) async {
    final box = await _taskBox;
    await box.put(taskModel.id, taskModel);
  }

  Future<void> deleteTask(int id) async {
    final box = await _taskBox;
    await box.delete(id);
  }

  Future<void> createTasksFromRoutines() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateTime today = DateTime.now();
    final String? lastLoginDateString = prefs.getString('lastLoginDate');
    final DateTime lastLoginDate = lastLoginDateString != null ? DateTime.parse(lastLoginDateString) : today;

    if (TaskProvider().routineList.isNotEmpty) {
      // create new tasks from routines
      int taskID = prefs.getInt("last_task_id") ?? 0;

      for (DateTime date = lastLoginDate.add(const Duration(days: 1)); date.isBeforeOrSameDay(today); date = date.add(const Duration(days: 1))) {
        for (RoutineModel routine in TaskProvider().routineList) {
          if (routine.repeatDays.contains(date.weekday) && routine.startDate.isBeforeOrSameDay(date) && !routine.isArchived) {
            taskID++;

            final TaskModel task = TaskModel(
              id: taskID,
              title: routine.title,
              description: routine.description,
              taskDate: date,
              status: null,
              type: routine.type,
              isNotificationOn: routine.isNotificationOn,
              isAlarmOn: routine.isAlarmOn,
              priority: routine.priority,
              routineID: routine.id,
              time: routine.time,
              attributeIDList: routine.attirbuteIDList,
              skillIDList: routine.skillIDList,
              currentCount: routine.type == TaskTypeEnum.COUNTER ? 0 : null,
              targetCount: routine.targetCount,
              currentDuration: routine.type == TaskTypeEnum.TIMER ? Duration.zero : null,
              remainingDuration: routine.remainingDuration,
              isTimerActive: routine.type == TaskTypeEnum.TIMER ? false : null,
            );

            TaskProvider().taskList.add(task);
            addTask(task);

            // TODO: schedule notification or alarm
          }
        }
      }
      prefs.setInt("last_task_id", TaskProvider().taskList.last.id);
    }

    if (TaskProvider().taskList.isNotEmpty) {
      // failed all past tasks if status null
      for (TaskModel task in TaskProvider().taskList) {
        if (task.status == null && task.taskDate.isBeforeDay(today)) {
          task.status = TaskStatusEnum.FAILED;

          updateTask(task);
        }
      }
    }

    prefs.setString('lastLoginDate', today.toIso8601String());
  }

  // delete all data
  Future<void> deleteAllData({bool isLogout = false}) async {
    // Clear Hive boxes
    final box = await _userBox;
    await box.clear();

    final box2 = await _itemBox;
    await box2.clear();

    final box3 = await _traitBox;
    await box3.clear();

    final box4 = await _routineBox;
    await box4.clear();

    final box5 = await _taskBox;
    await box5.clear();

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Reset last task id
    await prefs.setInt("last_task_id", 0);

    // Reset last login date to today
    await prefs.setString('lastLoginDate', DateTime.now().toIso8601String());

    // Refresh providers
    TaskProvider().taskList.clear();
    TaskProvider().routineList.clear();
    TaskProvider().updateItems();

    StoreProvider().storeItemList.clear();
    StoreProvider().setStateItems();

    NavigatorService().goBackNavbar(
      isHome: true,
      isDialog: true,
    );

    Helper().getMessage(message: LocaleKeys.DeleteAllDataSuccess.tr());
  }

  Future<String?> exportData() async {
    try {
      final now = DateTime.now();
      final fileName = 'gamify_todo_backup_${now.year}${now.month}${now.day}_${now.hour}${now.minute}.json';
      late final String filePath;

      if (Platform.isAndroid) {
        // Request storage permissions based on Android version
        if (!await Permission.storage.isGranted) {
          // Request both permissions
          Map<Permission, PermissionStatus> statuses = await [
            Permission.storage,
            Permission.manageExternalStorage,
          ].request();

          // Check if any permission was denied
          if (!(statuses.values.any((status) => status.isGranted))) {
            Helper().getMessage(
              message: LocaleKeys.storage_permission_required.tr(),
            );
            return null;
          }
        }

        // Get the Downloads directory on Android
        Directory? directory;
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
            if (directory != null) {
              directory = Directory('${directory.path}/Download');
            }
          }
        }

        if (directory == null) {
          Helper().getMessage(
            message: LocaleKeys.storage_access_error.tr(),
          );
          return null;
        }

        // Create directory if it doesn't exist
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        filePath = path.join(directory.path, fileName);
      } else {
        // For Windows and other platforms
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir == null) {
          Helper().getMessage(
            message: LocaleKeys.downloads_access_error.tr(),
          );
          return null;
        }
        filePath = path.join(downloadsDir.path, fileName);
      }

      final file = File(filePath);
      final Map<String, dynamic> allData = {};

      // Export users
      final userBox = await _userBox;
      final userMap = {};
      for (var key in userBox.keys) {
        final user = userBox.get(key);
        if (user != null) userMap[key.toString()] = user.toJson();
      }
      allData[_userBoxName] = userMap;

      // Export items
      final itemBox = await _itemBox;
      final itemMap = {};
      for (var key in itemBox.keys) {
        final item = itemBox.get(key);
        if (item != null) itemMap[key.toString()] = item.toJson();
      }
      allData[_itemBoxName] = itemMap;

      // Export traits
      final traitBox = await _traitBox;
      final traitMap = {};
      for (var key in traitBox.keys) {
        final trait = traitBox.get(key);
        if (trait != null) traitMap[key.toString()] = trait.toJson();
      }
      allData[_traitBoxName] = traitMap;

      // Export routines
      final routineBox = await _routineBox;
      final routineMap = {};
      for (var key in routineBox.keys) {
        final routine = routineBox.get(key);
        if (routine != null) routineMap[key.toString()] = routine.toJson();
      }
      allData[_routineBoxName] = routineMap;

      // Export tasks
      final taskBox = await _taskBox;
      final taskMap = {};
      for (var key in taskBox.keys) {
        final task = taskBox.get(key);
        if (task != null) taskMap[key.toString()] = task.toJson();
      }
      allData[_taskBoxName] = taskMap;

      final jsonString = jsonEncode(allData);
      await file.writeAsString(jsonString);

      NavigatorService().back();

      Helper().getMessage(message: LocaleKeys.backup_created_successfully.tr());

      return filePath;
    } catch (e) {
      Helper().getMessage(
        message: LocaleKeys.backup_creation_error.tr(args: [e.toString()]),
      );
      rethrow;
    }
  }

  Future<bool> importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        if (await file.exists()) {
          final content = await file.readAsString();
          final Map<String, dynamic> allData = jsonDecode(content);

          // Clear existing data first (this will also clear SharedPreferences)
          await deleteAllData();

          // Import users
          final userBox = await _userBox;
          final userData = allData[_userBoxName] as Map<String, dynamic>;
          for (var entry in userData.entries) {
            await userBox.put(int.parse(entry.key), UserModel.fromJson(entry.value));
          }

          // Import items
          final itemBox = await _itemBox;
          final itemData = allData[_itemBoxName] as Map<String, dynamic>;
          for (var entry in itemData.entries) {
            final item = ItemModel.fromJson(entry.value);
            await itemBox.put(int.parse(entry.key), item);
            StoreProvider().storeItemList.add(item);
          }

          // Import traits
          final traitBox = await _traitBox;
          final traitData = allData[_traitBoxName] as Map<String, dynamic>;
          for (var entry in traitData.entries) {
            await traitBox.put(int.parse(entry.key), TraitModel.fromJson(entry.value));
          }

          // Import routines
          final routineBox = await _routineBox;
          final routineData = allData[_routineBoxName] as Map<String, dynamic>;
          for (var entry in routineData.entries) {
            final routine = RoutineModel.fromJson(entry.value);
            await routineBox.put(int.parse(entry.key), routine);
            TaskProvider().routineList.add(routine);
          }

          // Import tasks
          final taskBox = await _taskBox;
          final taskData = allData[_taskBoxName] as Map<String, dynamic>;
          for (var entry in taskData.entries) {
            final task = TaskModel.fromJson(entry.value);
            await taskBox.put(int.parse(entry.key), task);
            TaskProvider().taskList.add(task);
          }

          final prefs = await SharedPreferences.getInstance();
          // Update last ids SharedPreferences
          if (TaskProvider().taskList.isNotEmpty) {
            await prefs.setInt("last_task_id", TaskProvider().taskList.map((e) => e.id).reduce((max, id) => max > id ? max : id));
          }
          if (TaskProvider().routineList.isNotEmpty) {
            await prefs.setInt("last_routine_id", TaskProvider().routineList.map((e) => e.id).reduce((max, id) => max > id ? max : id));
          }
          if (TraitProvider().traitList.isNotEmpty) {
            await prefs.setInt("last_trait_id", TraitProvider().traitList.map((e) => e.id).reduce((max, id) => max > id ? max : id));
          }

          // Refresh providers
          TaskProvider().updateItems();
          StoreProvider().setStateItems();

          NavigatorService().goBackNavbar(
            isHome: true,
            isDialog: true,
          );

          Helper().getMessage(message: LocaleKeys.backup_restored_successfully.tr());

          return true;
        }
      }
      Helper().getMessage(
        message: LocaleKeys.backup_restore_cancelled.tr(),
      );
      return false;
    } catch (e) {
      Helper().getMessage(
        message: LocaleKeys.backup_restore_error.tr(args: [e.toString()]),
      );
      rethrow;
    }
  }
}
