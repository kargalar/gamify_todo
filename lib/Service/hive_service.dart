import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Service/file_storage_service.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:next_level/Model/user_model.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';

class HiveService {
  // TODO: singleton yap ve shared pefi de buradan çağır ??

  static const String _userBoxName = 'userBox';
  static const String _itemBoxName = 'itemBox';
  static const String _traitBoxName = 'traitBox';
  static const String _routineBoxName = 'routineBox';
  static const String _taskBoxName = 'taskBox';
  static const String _taskLogBoxName = 'taskLogBox';
  static const String _categoryBoxName = 'categoryBox';

  Future<Box<UserModel>> get _userBox async => await Hive.openBox<UserModel>(_userBoxName);
  Future<Box<ItemModel>> get _itemBox async => await Hive.openBox<ItemModel>(_itemBoxName);
  Future<Box<TraitModel>> get _traitBox async => await Hive.openBox<TraitModel>(_traitBoxName);
  Future<Box<RoutineModel>> get _routineBox async => await Hive.openBox<RoutineModel>(_routineBoxName);
  Future<Box<TaskModel>> get _taskBox async => await Hive.openBox<TaskModel>(_taskBoxName);
  Future<Box<TaskLogModel>> get _taskLogBox async => await Hive.openBox<TaskLogModel>(_taskLogBoxName);
  Future<Box<CategoryModel>> get _categoryBox async => await Hive.openBox<CategoryModel>(_categoryBoxName);

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
    debugPrint('Updating routine in Hive: ID=${routineModel.id}, Title=${routineModel.title}');

    try {
      // First save the HiveObject to ensure changes are persisted
      routineModel.save();

      // Then update the box with the routine model
      await box.put(routineModel.id, routineModel);

      // Verify the routine was saved correctly
      final savedRoutine = box.get(routineModel.id);
      if (savedRoutine != null) {
        debugPrint('Routine successfully saved to Hive: ID=${savedRoutine.id}, Title=${savedRoutine.title}');
      } else {
        debugPrint('ERROR: Failed to retrieve saved routine from Hive');
      }
    } catch (e) {
      debugPrint('ERROR saving routine to Hive: $e');
      rethrow;
    }
  }

  Future<void> deleteRoutine(int id) async {
    final box = await _routineBox;
    await box.delete(id);

    // delete success check
    if (!box.containsKey(id)) {
      debugPrint('Routine with ID $id deleted from Hive storage');
    } else {
      debugPrint('Routine with ID $id not deleted from Hive storage');
    }
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
    debugPrint('Updating task in Hive: ID=${taskModel.id}, Title=${taskModel.title}');

    try {
      // First save the HiveObject to ensure changes are persisted
      debugPrint('Calling save() on task: ID=${taskModel.id}');
      taskModel.save();
      debugPrint('save() completed successfully for task: ID=${taskModel.id}');

      // Then update the box with the task model
      debugPrint('Putting task in Hive box: ID=${taskModel.id}');
      await box.put(taskModel.id, taskModel);
      debugPrint('put() completed successfully for task: ID=${taskModel.id}');

      // Verify the task was saved correctly
      final savedTask = box.get(taskModel.id);
      if (savedTask != null) {
        debugPrint('Task successfully saved to Hive: ID=${savedTask.id}, Title=${savedTask.title}');
      } else {
        debugPrint('ERROR: Failed to retrieve saved task from Hive');
      }
    } catch (e) {
      debugPrint('ERROR saving task to Hive: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    final box = await _taskBox;
    await box.delete(id);

    // delete succes check
    if (!box.containsKey(id)) {
      debugPrint('Task with ID $id deleted from Hive storage');
    } else {
      debugPrint('Task with ID $id not deleted from Hive storage');
    }
  }

  // Category methods
  Future<void> addCategory(CategoryModel categoryModel) async {
    final box = await _categoryBox;
    await box.put(categoryModel.id, categoryModel);
  }

  Future<List<CategoryModel>> getCategories() async {
    final box = await _categoryBox;
    return box.values.toList();
  }

  Future<void> updateCategory(CategoryModel categoryModel) async {
    final box = await _categoryBox;
    await box.put(categoryModel.id, categoryModel);
  }

  Future<void> deleteCategory(int id) async {
    final box = await _categoryBox;
    await box.delete(id);
  }

  // Task Log methods
  Future<void> addTaskLog(TaskLogModel taskLogModel) async {
    final box = await _taskLogBox;
    await box.put(taskLogModel.id, taskLogModel);
  }

  Future<List<TaskLogModel>> getTaskLogs() async {
    final box = await _taskLogBox;
    return box.values.toList();
  }

  Future<List<TaskLogModel>> getTaskLogsByTaskId(int taskId) async {
    final box = await _taskLogBox;
    return box.values.where((log) => log.taskId == taskId).toList();
  }

  Future<List<TaskLogModel>> getTaskLogsByRoutineId(int routineId) async {
    final box = await _taskLogBox;
    return box.values.where((log) => log.routineId == routineId).toList();
  }

  Future<void> deleteTaskLog(int id) async {
    final box = await _taskLogBox;
    await box.delete(id);
  }

  Future<void> createTasksFromRoutines() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateTime today = DateTime.now();
    final String? lastLoginDateString = prefs.getString('lastLoginDate');
    final DateTime lastLoginDate = lastLoginDateString != null ? DateTime.parse(lastLoginDateString) : today;

    debugPrint('=== createTasksFromRoutines Debug ===');
    debugPrint('Today: $today');
    debugPrint('Last login date: $lastLoginDate');
    debugPrint('Routine count: ${TaskProvider().routineList.length}');

    if (TaskProvider().routineList.isNotEmpty) {
      // Get all existing tasks to find the highest ID
      final existingTasks = await getTasks();
      int highestTaskId = prefs.getInt("last_task_id") ?? 0;

      // Find the highest ID among existing tasks
      for (final task in existingTasks) {
        if (task.id > highestTaskId) {
          highestTaskId = task.id;
        }
      }

      int taskID = highestTaskId;
      int tasksCreated = 0;

      for (DateTime date = lastLoginDate.add(const Duration(days: 1)); date.isBeforeOrSameDay(today); date = date.add(const Duration(days: 1))) {
        debugPrint('Checking date: $date (weekday: ${date.weekday})');

        for (RoutineModel routine in TaskProvider().routineList) {
          debugPrint('  Routine: ${routine.title}');
          debugPrint('    Repeat days: ${routine.repeatDays}');
          debugPrint('    Start date: ${routine.startDate}');
          debugPrint('    Is archived: ${routine.isArchived}');
          debugPrint('    Date weekday-1: ${date.weekday - 1}');
          debugPrint('    Contains weekday: ${routine.repeatDays.contains(date.weekday - 1)}');

          if (routine.isActiveForThisDate(date)) {
            // Check if a task for this routine on this date already exists (e.g., from import)
            final bool taskAlreadyExists = TaskProvider().taskList.any((existingTask) => existingTask.routineID == routine.id && existingTask.taskDate != null && existingTask.taskDate!.year == date.year && existingTask.taskDate!.month == date.month && existingTask.taskDate!.day == date.day);

            if (taskAlreadyExists) {
              debugPrint('    SKIPPING task creation for routine ${routine.title} on $date as it already exists.');
            } else {
              debugPrint('    ✓ Creating task for routine ${routine.title} on $date');
              taskID++;
              tasksCreated++;

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

              await addTask(task);
              TaskProvider().taskList.add(task);

              // Bildirim veya alarm ayarla
              if (task.time != null && (task.isNotificationOn || task.isAlarmOn)) {
                debugPrint('    Setting notification for task: ${task.title}');
                TaskProvider().checkNotification(task);
              }
            }
          } else {
            debugPrint('    ✗ Routine ${routine.title} not active for $date');
          }
        }
      }

      debugPrint('Total tasks created: $tasksCreated');

      // Update the last task ID in SharedPreferences if tasks were created
      if (TaskProvider().taskList.isNotEmpty) {
        await prefs.setInt("last_task_id", taskID);
      }
    } else {
      debugPrint('No routines found to create tasks from');
    }

    if (TaskProvider().taskList.isNotEmpty) {
      // Mark past tasks as overdue and past routines as failed
      for (TaskModel task in TaskProvider().taskList) {
        if (task.status == null && task.taskDate != null && task.taskDate!.isBeforeDay(today)) {
          if (task.routineID != null) {
            // Routine tasks that are past due should be marked as failed
            task.status = TaskStatusEnum.FAILED;

            // Create log for failed routine task
            TaskLogProvider().addTaskLog(
              task,
              customStatus: TaskStatusEnum.FAILED,
            );
          } else {
            // Regular tasks that are past due should be marked as overdue
            task.status = TaskStatusEnum.OVERDUE;

            // Create log for overdue task
            TaskLogProvider().addTaskLog(
              task,
              customStatus: TaskStatusEnum.OVERDUE,
            );
          }

          updateTask(task);
        }
      }
    }

    prefs.setString('lastLoginDate', today.toIso8601String());
  }

  // delete all data
  Future<void> deleteAllData({bool isLogout = false}) async {
    // Cancel all notifications first
    await NotificationService().cancelAllNotifications();

    // Clear all attachment files
    try {
      await FileStorageService.instance.clearAllAttachments();
    } catch (e) {
      debugPrint('Error clearing attachment files: $e');
    }

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

    final box6 = await _taskLogBox;
    await box6.clear();

    final box7 = await _categoryBox;
    await box7.clear();

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Refresh providers
    TaskProvider().taskList.clear();
    TaskProvider().routineList.clear();
    TaskProvider().updateItems();

    TraitProvider().traitList.clear();

    StoreProvider().storeItemList.clear();
    StoreProvider().setStateItems();

    // Clear task logs in the provider
    await TaskLogProvider().clearAllLogs();

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

      // Export task logs
      final taskLogBox = await _taskLogBox;
      final taskLogMap = {};
      for (var key in taskLogBox.keys) {
        final taskLog = taskLogBox.get(key);
        if (taskLog != null) taskLogMap[key.toString()] = taskLog.toJson();
      }
      allData[_taskLogBoxName] = taskLogMap;

      // Export categories
      final categoryBox = await _categoryBox;
      final categoryMap = {};
      for (var key in categoryBox.keys) {
        final category = categoryBox.get(key);
        if (category != null) categoryMap[key.toString()] = category.toJson();
      }
      allData[_categoryBoxName] = categoryMap; // Export SharedPrefs
      final prefs = await SharedPreferences.getInstance();
      final sharedPrefsMap = {};

      // Export existing settings
      sharedPrefsMap["lastLoginDate"] = prefs.getString('lastLoginDate');
      sharedPrefsMap["last_task_id"] = prefs.getInt('last_task_id') ?? 0;
      sharedPrefsMap["last_routine_id"] = prefs.getInt('last_routine_id') ?? 0;
      sharedPrefsMap["last_trait_id"] = prefs.getInt('last_trait_id') ?? 0;
      sharedPrefsMap["last_category_id"] = prefs.getInt('last_category_id') ?? 0;

      // Export inbox page filter settings with default values
      sharedPrefsMap["categories_show_tasks"] = prefs.getBool('categories_show_tasks') ?? true;
      sharedPrefsMap["categories_show_routines"] = prefs.getBool('categories_show_routines') ?? true;
      sharedPrefsMap["categories_date_filter"] = prefs.getInt('categories_date_filter') ?? 0;
      sharedPrefsMap["categories_show_checkbox"] = prefs.getBool('categories_show_checkbox') ?? true;
      sharedPrefsMap["categories_show_counter"] = prefs.getBool('categories_show_counter') ?? true;
      sharedPrefsMap["categories_show_timer"] = prefs.getBool('categories_show_timer') ?? true;
      sharedPrefsMap["categories_show_completed"] = prefs.getBool('categories_show_completed') ?? true;
      sharedPrefsMap["categories_show_failed"] = prefs.getBool('categories_show_failed') ?? true;
      sharedPrefsMap["categories_show_cancel"] = prefs.getBool('categories_show_cancel') ?? true;
      sharedPrefsMap["categories_show_archived"] = prefs.getBool('categories_show_archived') ?? false;
      sharedPrefsMap["categories_show_overdue"] = prefs.getBool('categories_show_overdue') ?? true;
      sharedPrefsMap["categories_show_empty_status"] = prefs.getBool('categories_show_empty_status') ?? true;
      sharedPrefsMap["categories_selected_category_id"] = prefs.getInt('categories_selected_category_id') ?? -1;

      // Export home page setting
      sharedPrefsMap["show_completed"] = prefs.getBool('show_completed') ?? false;

      // Export theme setting
      sharedPrefsMap["isDark"] = prefs.getBool('isDark') ?? false;

      // Export task style setting
      sharedPrefsMap["task_style"] = prefs.getInt('task_style') ?? 0;

      // Export main color setting
      sharedPrefsMap["main_color"] = prefs.getInt('main_color') ?? 0;

      // Export language setting
      sharedPrefsMap["selected_language"] = prefs.getString('selected_language') ?? 'en';

      allData["SharedPreferances"] = sharedPrefsMap;

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
            final user = UserModel.fromJson(entry.value);
            await userBox.put(int.parse(entry.key), user);
            loginUser = user;
          }

          // Import items
          final itemBox = await _itemBox;
          final itemData = allData[_itemBoxName] as Map<String, dynamic>;
          for (var entry in itemData.entries) {
            final item = ItemModel.fromJson(entry.value);
            await itemBox.put(int.parse(entry.key), item);
            StoreProvider().storeItemList.add(item);
          }
          debugPrint(TraitProvider().traitList.toString());
          // Import traits
          final traitBox = await _traitBox;
          final traitData = allData[_traitBoxName] as Map<String, dynamic>;
          for (var entry in traitData.entries) {
            final trait = TraitModel.fromJson(entry.value);
            await traitBox.put(int.parse(entry.key), trait);
            TraitProvider().traitList.add(trait);
          }
          debugPrint(TraitProvider().traitList.toString());

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

          // Import categories if they exist
          if (allData.containsKey(_categoryBoxName)) {
            final categoryBox = await _categoryBox;
            final categoryData = allData[_categoryBoxName] as Map<String, dynamic>;
            for (var entry in categoryData.entries) {
              final category = CategoryModel.fromJson(entry.value);
              await categoryBox.put(int.parse(entry.key), category);
            }
          }

          // Import task logs if they exist
          if (allData.containsKey(_taskLogBoxName)) {
            final taskLogBox = await _taskLogBox;
            final taskLogData = allData[_taskLogBoxName] as Map<String, dynamic>;
            for (var entry in taskLogData.entries) {
              final taskLog = TaskLogModel.fromJson(entry.value);
              await taskLogBox.put(int.parse(entry.key), taskLog);
            }
          } // Import SharedPrefs
          final prefs = await SharedPreferences.getInstance();
          final sharedPrefsMap = allData["SharedPreferances"] as Map<String, dynamic>;

          // Set lastLoginDate to yesterday so that createTasksFromRoutines creates tasks for today
          // Because createTasksFromRoutines starts from lastLoginDate + 1 day
          await prefs.setString('lastLoginDate', DateTime.now().subtract(const Duration(days: 1)).toIso8601String());
          await prefs.setInt('last_task_id', sharedPrefsMap["last_task_id"] ?? 0);
          await prefs.setInt('last_routine_id', sharedPrefsMap["last_routine_id"] ?? 0);
          await prefs.setInt('last_trait_id', sharedPrefsMap["last_trait_id"] ?? 0);
          await prefs.setInt('last_category_id', sharedPrefsMap["last_category_id"] ?? 0);

          // Import inbox page filter settings with proper defaults
          await prefs.setBool('categories_show_tasks', sharedPrefsMap["categories_show_tasks"] ?? true);
          await prefs.setBool('categories_show_routines', sharedPrefsMap["categories_show_routines"] ?? true);
          await prefs.setInt('categories_date_filter', sharedPrefsMap["categories_date_filter"] ?? 0);
          await prefs.setBool('categories_show_checkbox', sharedPrefsMap["categories_show_checkbox"] ?? true);
          await prefs.setBool('categories_show_counter', sharedPrefsMap["categories_show_counter"] ?? true);
          await prefs.setBool('categories_show_timer', sharedPrefsMap["categories_show_timer"] ?? true);
          await prefs.setBool('categories_show_completed', sharedPrefsMap["categories_show_completed"] ?? true);
          await prefs.setBool('categories_show_failed', sharedPrefsMap["categories_show_failed"] ?? true);
          await prefs.setBool('categories_show_cancel', sharedPrefsMap["categories_show_cancel"] ?? true);
          await prefs.setBool('categories_show_archived', sharedPrefsMap["categories_show_archived"] ?? false);
          await prefs.setBool('categories_show_overdue', sharedPrefsMap["categories_show_overdue"] ?? true);
          await prefs.setBool('categories_show_empty_status', sharedPrefsMap["categories_show_empty_status"] ?? true);
          await prefs.setInt('categories_selected_category_id', sharedPrefsMap["categories_selected_category_id"] ?? -1);

          // Import home page setting
          await prefs.setBool('show_completed', sharedPrefsMap["show_completed"] ?? false);

          // Import theme setting
          await prefs.setBool('isDark', sharedPrefsMap["isDark"] ?? false);

          // Import task style setting
          await prefs.setInt('task_style', sharedPrefsMap["task_style"] ?? 0);

          // Import main color setting
          await prefs.setInt('main_color', sharedPrefsMap["main_color"] ?? 0);

          // Import language setting
          await prefs.setString('selected_language', sharedPrefsMap["selected_language"] ?? 'en');
          await createTasksFromRoutines();

          // Cancel all notifications after import and task creation to clean up any old notifications
          await NotificationService().cancelAllNotifications();

          // Re-schedule notifications for imported tasks that have notification/alarm settings
          for (TaskModel task in TaskProvider().taskList) {
            if ((task.isNotificationOn || task.isAlarmOn) && task.time != null && task.taskDate != null) {
              TaskProvider().checkNotification(task);
            }
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
