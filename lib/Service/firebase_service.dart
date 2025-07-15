import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Model/user_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  FirebaseService._privateConstructor();
  static final FirebaseService _instance = FirebaseService._privateConstructor();
  factory FirebaseService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final HiveService _hiveService = HiveService();

  // Get current user's UID
  String? get currentUserUid => _auth.currentUser?.uid;

  // Collection names
  static const String _usersCollection = 'users';
  static const String _tasksCollection = 'tasks';
  static const String _itemsCollection = 'items';
  static const String _traitsCollection = 'traits';
  static const String _routinesCollection = 'routines';
  static const String _categoriesCollection = 'categories';
  static const String _taskLogsCollection = 'task_logs';
  static const String _deletedItemsCollection = 'deleted_items';

  // Real-time sync subscriptions
  final List<StreamSubscription> _subscriptions = [];

  // ===============================
  // SYNC METHODS
  // ===============================

  /// Sync all data from Firebase to local storage
  Future<void> syncFromFirebase() async {
    if (currentUserUid == null) return;

    try {
      debugPrint('🔄 Starting sync from Firebase...');

      // Sync user data
      await _syncUserFromFirebase();

      // Sync all collections
      await _syncTasksFromFirebase();
      await _syncItemsFromFirebase();
      await _syncTraitsFromFirebase();
      await _syncRoutinesFromFirebase();
      await _syncCategoriesFromFirebase();
      await _syncTaskLogsFromFirebase();

      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', DateTime.now().toIso8601String());

      debugPrint('✅ Sync from Firebase completed successfully');
    } catch (e) {
      debugPrint('❌ Error syncing from Firebase: $e');
      rethrow;
    }
  }

  /// Sync all data from local storage to Firebase
  Future<void> syncToFirebase() async {
    if (currentUserUid == null) return;

    try {
      debugPrint('🔄 Starting sync to Firebase...');

      // Sync user data
      await _syncUserToFirebase();

      // Sync all collections
      await _syncTasksToFirebase();
      await _syncItemsToFirebase();
      await _syncTraitsToFirebase();
      await _syncRoutinesToFirebase();
      await _syncCategoriesToFirebase();
      await _syncTaskLogsToFirebase();

      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', DateTime.now().toIso8601String());

      debugPrint('✅ Sync to Firebase completed successfully');
    } catch (e) {
      debugPrint('❌ Error syncing to Firebase: $e');
      rethrow;
    }
  }

  /// Bidirectional sync - merge local and Firebase data
  Future<void> bidirectionalSync() async {
    if (currentUserUid == null) return;

    try {
      debugPrint('🔄 Starting bidirectional sync...');

      // Get last sync time
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTimeStr = prefs.getString('last_sync_time');
      final lastSyncTime = lastSyncTimeStr != null ? DateTime.parse(lastSyncTimeStr) : DateTime.now().subtract(const Duration(days: 365));

      // Sync each collection bidirectionally
      await _bidirectionalSyncTasks(lastSyncTime);
      await _bidirectionalSyncItems(lastSyncTime);
      await _bidirectionalSyncTraits(lastSyncTime);
      await _bidirectionalSyncRoutines(lastSyncTime);
      await _bidirectionalSyncCategories(lastSyncTime);
      await _bidirectionalSyncTaskLogs(lastSyncTime);

      // Update last sync time
      await prefs.setString('last_sync_time', DateTime.now().toIso8601String());

      debugPrint('✅ Bidirectional sync completed successfully');
    } catch (e) {
      debugPrint('❌ Error in bidirectional sync: $e');
      rethrow;
    }
  }

  // ===============================
  // USER METHODS
  // ===============================

  Future<void> _syncUserFromFirebase() async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(currentUserUid).get();

      if (doc.exists) {
        final userData = doc.data()!;
        final userModel = UserModel.fromJson(userData);
        await _hiveService.updateUser(userModel);
        loginUser = userModel;
      }
    } catch (e) {
      debugPrint('Error syncing user from Firebase: $e');
    }
  }

  Future<void> _syncUserToFirebase() async {
    try {
      if (loginUser != null) {
        await _firestore.collection(_usersCollection).doc(currentUserUid).set({
          ...loginUser!.toJson(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error syncing user to Firebase: $e');
    }
  }

  // ===============================
  // TASKS METHODS
  // ===============================

  Future<void> _syncTasksFromFirebase() async {
    try {
      debugPrint('🔄 Syncing tasks from Firebase...');
      final querySnapshot = await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_tasksCollection).get();

      debugPrint('Found ${querySnapshot.docs.length} tasks in Firebase');

      // Get all existing local tasks
      final localTasks = await _hiveService.getTasks();
      final Map<int, TaskModel> localTaskMap = {for (final task in localTasks) task.id: task};

      for (final doc in querySnapshot.docs) {
        try {
          final taskData = doc.data();
          final taskModel = TaskModel.fromJson(taskData);

          // Check if task exists locally
          if (localTaskMap.containsKey(taskModel.id)) {
            // Update existing task
            await _hiveService.updateTask(taskModel);
            debugPrint('Updated existing task: ${taskModel.title}');
          } else {
            // Add new task
            await _hiveService.addTask(taskModel);
            debugPrint('Added new task: ${taskModel.title}');
          }
        } catch (e) {
          debugPrint('Error processing task ${doc.id}: $e');
        }
      }

      debugPrint('✅ Tasks sync from Firebase completed');
    } catch (e) {
      debugPrint('❌ Error syncing tasks from Firebase: $e');
      rethrow;
    }
  }

  Future<void> _syncTasksToFirebase() async {
    try {
      final localTasks = await _hiveService.getTasks();
      final batch = _firestore.batch();

      for (final task in localTasks) {
        final docRef = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_tasksCollection).doc(task.id.toString());

        batch.set(docRef, {
          ...task.toJson(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error syncing tasks to Firebase: $e');
    }
  }

  Future<void> _bidirectionalSyncTasks(DateTime lastSyncTime) async {
    try {
      // Get deleted items list
      final deletedItems = await getDeletedItems();

      // Get Firebase tasks updated after last sync
      final firebaseSnapshot = await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_tasksCollection).where('updated_at', isGreaterThan: Timestamp.fromDate(lastSyncTime)).get();

      // Get local tasks
      final localTasks = await _hiveService.getTasks();
      final localTasksMap = {for (var task in localTasks) task.id: task};

      final batch = _firestore.batch();

      // Process Firebase tasks
      for (final doc in firebaseSnapshot.docs) {
        final firebaseTask = TaskModel.fromJson(doc.data());

        // Skip if task is marked as deleted
        if (_isItemDeleted(deletedItems, 'task', firebaseTask.id)) {
          continue;
        }

        final localTask = localTasksMap[firebaseTask.id];

        if (localTask == null) {
          // Firebase task doesn't exist locally, add it
          await _hiveService.addTask(firebaseTask);
        } else {
          // Both exist, use most recent (you can implement conflict resolution here)
          await _hiveService.updateTask(firebaseTask);
        }
      }

      // Process local tasks that might need to be uploaded
      for (final task in localTasks) {
        // Skip if task is marked as deleted
        if (_isItemDeleted(deletedItems, 'task', task.id)) {
          // Remove from local storage if it's marked as deleted
          await _hiveService.deleteTask(task.id);
          continue;
        }

        final docRef = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_tasksCollection).doc(task.id.toString());

        batch.set(
            docRef,
            {
              ...task.toJson(),
              'updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error in bidirectional sync for tasks: $e');
    }
  }

  // ===============================
  // STORE ITEMS METHODS
  // ===============================

  Future<void> _syncItemsFromFirebase() async {
    try {
      debugPrint('🔄 Syncing items from Firebase...');
      final querySnapshot = await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_itemsCollection).get();

      debugPrint('Found ${querySnapshot.docs.length} items in Firebase');

      // Get all existing local items
      final localItems = await _hiveService.getItems();
      final Map<int, ItemModel> localItemMap = {for (final item in localItems) item.id: item};

      for (final doc in querySnapshot.docs) {
        try {
          final itemData = doc.data();
          final itemModel = ItemModel.fromJson(itemData);

          // Check if item exists locally
          if (localItemMap.containsKey(itemModel.id)) {
            // Update existing item
            await _hiveService.updateItem(itemModel);
            debugPrint('Updated existing item: ${itemModel.title}');
          } else {
            // Add new item
            await _hiveService.addItem(itemModel);
            debugPrint('Added new item: ${itemModel.title}');
          }
        } catch (e) {
          debugPrint('Error processing item ${doc.id}: $e');
        }
      }

      debugPrint('✅ Items sync from Firebase completed');
    } catch (e) {
      debugPrint('❌ Error syncing items from Firebase: $e');
      rethrow;
    }
  }

  Future<void> _syncItemsToFirebase() async {
    try {
      final localItems = await _hiveService.getItems();
      final batch = _firestore.batch();

      for (final item in localItems) {
        final docRef = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_itemsCollection).doc(item.id.toString());

        batch.set(docRef, {
          ...item.toJson(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error syncing items to Firebase: $e');
    }
  }

  Future<void> _bidirectionalSyncItems(DateTime lastSyncTime) async {
    try {
      // Get deleted items list
      final deletedItems = await getDeletedItems();

      // Get Firebase items updated after last sync
      final firebaseSnapshot = await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_itemsCollection).where('updated_at', isGreaterThan: Timestamp.fromDate(lastSyncTime)).get();

      // Get local items
      final localItems = await _hiveService.getItems();
      final localItemsMap = {for (var item in localItems) item.id: item};

      final batch = _firestore.batch();

      // Process Firebase items
      for (final doc in firebaseSnapshot.docs) {
        final firebaseItem = ItemModel.fromJson(doc.data());

        // Skip if item is marked as deleted
        if (_isItemDeleted(deletedItems, 'item', firebaseItem.id)) {
          continue;
        }

        final localItem = localItemsMap[firebaseItem.id];

        if (localItem == null) {
          // Firebase item doesn't exist locally, add it
          await _hiveService.addItem(firebaseItem);
        } else {
          // Both exist, use most recent
          await _hiveService.updateItem(firebaseItem);
        }
      }

      // Process local items that might need to be uploaded
      for (final item in localItems) {
        // Skip if item is marked as deleted
        if (_isItemDeleted(deletedItems, 'item', item.id)) {
          // Remove from local storage if it's marked as deleted
          await _hiveService.deleteItem(item.id);
          continue;
        }

        final docRef = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_itemsCollection).doc(item.id.toString());

        batch.set(
            docRef,
            {
              ...item.toJson(),
              'updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error in bidirectional sync for items: $e');
    }
  }

  // ===============================
  // TRAITS METHODS
  // ===============================

  Future<void> _syncTraitsFromFirebase() async {
    try {
      debugPrint('🔄 Syncing traits from Firebase...');
      final querySnapshot = await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_traitsCollection).get();

      debugPrint('Found ${querySnapshot.docs.length} traits in Firebase');

      // Get all existing local traits
      final localTraits = await _hiveService.getTraits();
      final Map<int, TraitModel> localTraitMap = {for (final trait in localTraits) trait.id: trait};

      for (final doc in querySnapshot.docs) {
        try {
          final traitData = doc.data();
          final traitModel = TraitModel.fromJson(traitData);

          // Check if trait exists locally
          if (localTraitMap.containsKey(traitModel.id)) {
            // Update existing trait
            await _hiveService.updateTrait(traitModel);
            debugPrint('Updated existing trait: ${traitModel.title}');
          } else {
            // Add new trait
            await _hiveService.addTrait(traitModel);
            debugPrint('Added new trait: ${traitModel.title}');
          }
        } catch (e) {
          debugPrint('Error processing trait ${doc.id}: $e');
        }
      }

      debugPrint('✅ Traits sync from Firebase completed');
    } catch (e) {
      debugPrint('❌ Error syncing traits from Firebase: $e');
      rethrow;
    }
  }

  Future<void> _syncTraitsToFirebase() async {
    try {
      final localTraits = await _hiveService.getTraits();
      final batch = _firestore.batch();

      for (final trait in localTraits) {
        final docRef = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_traitsCollection).doc(trait.id.toString());

        batch.set(docRef, {
          ...trait.toJson(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error syncing traits to Firebase: $e');
    }
  }

  Future<void> _bidirectionalSyncTraits(DateTime lastSyncTime) async {
    try {
      // Get Firebase traits updated after last sync
      final firebaseSnapshot = await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_traitsCollection).where('updated_at', isGreaterThan: Timestamp.fromDate(lastSyncTime)).get();

      // Get local traits
      final localTraits = await _hiveService.getTraits();
      final localTraitsMap = {for (var trait in localTraits) trait.id: trait};

      final batch = _firestore.batch();

      // Process Firebase traits
      for (final doc in firebaseSnapshot.docs) {
        final firebaseTrait = TraitModel.fromJson(doc.data());
        final localTrait = localTraitsMap[firebaseTrait.id];

        if (localTrait == null) {
          // Firebase trait doesn't exist locally, add it
          await _hiveService.addTrait(firebaseTrait);
        } else {
          // Both exist, use most recent
          await _hiveService.updateTrait(firebaseTrait);
        }
      }

      // Process local traits that might need to be uploaded
      for (final trait in localTraits) {
        final docRef = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_traitsCollection).doc(trait.id.toString());

        batch.set(
            docRef,
            {
              ...trait.toJson(),
              'updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error in bidirectional sync for traits: $e');
    }
  }

  // ===============================
  // ROUTINES METHODS
  // ===============================

  Future<void> _syncRoutinesFromFirebase() async {
    try {
      debugPrint('🔄 Syncing routines from Firebase...');
      final querySnapshot = await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_routinesCollection).get();

      debugPrint('Found ${querySnapshot.docs.length} routines in Firebase');

      // Get all existing local routines
      final localRoutines = await _hiveService.getRoutines();
      final Map<int, RoutineModel> localRoutineMap = {for (final routine in localRoutines) routine.id: routine};

      for (final doc in querySnapshot.docs) {
        try {
          final routineData = doc.data();
          final routineModel = RoutineModel.fromJson(routineData);

          // Check if routine exists locally
          if (localRoutineMap.containsKey(routineModel.id)) {
            // Update existing routine
            await _hiveService.updateRoutine(routineModel);
            debugPrint('Updated existing routine: ${routineModel.title}');
          } else {
            // Add new routine
            await _hiveService.addRoutine(routineModel);
            debugPrint('Added new routine: ${routineModel.title}');
          }
        } catch (e) {
          debugPrint('Error processing routine ${doc.id}: $e');
        }
      }

      debugPrint('✅ Routines sync from Firebase completed');
    } catch (e) {
      debugPrint('❌ Error syncing routines from Firebase: $e');
      rethrow;
    }
  }

  Future<void> _syncRoutinesToFirebase() async {
    try {
      final localRoutines = await _hiveService.getRoutines();
      final batch = _firestore.batch();

      for (final routine in localRoutines) {
        final docRef = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_routinesCollection).doc(routine.id.toString());

        batch.set(docRef, {
          ...routine.toJson(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error syncing routines to Firebase: $e');
    }
  }

  Future<void> _bidirectionalSyncRoutines(DateTime lastSyncTime) async {
    try {
      // Get Firebase routines updated after last sync
      final firebaseSnapshot = await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_routinesCollection).where('updated_at', isGreaterThan: Timestamp.fromDate(lastSyncTime)).get();

      // Get local routines
      final localRoutines = await _hiveService.getRoutines();
      final localRoutinesMap = {for (var routine in localRoutines) routine.id: routine};

      final batch = _firestore.batch();

      // Process Firebase routines
      for (final doc in firebaseSnapshot.docs) {
        final firebaseRoutine = RoutineModel.fromJson(doc.data());
        final localRoutine = localRoutinesMap[firebaseRoutine.id];

        if (localRoutine == null) {
          // Firebase routine doesn't exist locally, add it
          await _hiveService.addRoutine(firebaseRoutine);
        } else {
          // Both exist, use most recent
          await _hiveService.updateRoutine(firebaseRoutine);
        }
      }

      // Process local routines that might need to be uploaded
      for (final routine in localRoutines) {
        final docRef = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_routinesCollection).doc(routine.id.toString());

        batch.set(
            docRef,
            {
              ...routine.toJson(),
              'updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error in bidirectional sync for routines: $e');
    }
  }

  // ===============================
  // CATEGORIES METHODS
  // ===============================

  Future<void> _syncCategoriesFromFirebase() async {
    try {
      debugPrint('🔄 Syncing categories from Firebase...');
      final querySnapshot = await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_categoriesCollection).get();

      debugPrint('Found ${querySnapshot.docs.length} categories in Firebase');

      // Get all existing local categories
      final localCategories = await _hiveService.getCategories();
      final Map<int, CategoryModel> localCategoryMap = {for (final category in localCategories) category.id: category};

      for (final doc in querySnapshot.docs) {
        try {
          final categoryData = doc.data();
          final categoryModel = CategoryModel.fromJson(categoryData);

          // Check if category exists locally
          if (localCategoryMap.containsKey(categoryModel.id)) {
            // Update existing category
            await _hiveService.updateCategory(categoryModel);
            debugPrint('Updated existing category: ${categoryModel.title}');
          } else {
            // Add new category
            await _hiveService.addCategory(categoryModel);
            debugPrint('Added new category: ${categoryModel.title}');
          }
        } catch (e) {
          debugPrint('Error processing category ${doc.id}: $e');
        }
      }

      debugPrint('✅ Categories sync from Firebase completed');
    } catch (e) {
      debugPrint('❌ Error syncing categories from Firebase: $e');
      rethrow;
    }
  }

  Future<void> _syncCategoriesToFirebase() async {
    try {
      final localCategories = await _hiveService.getCategories();
      final batch = _firestore.batch();

      for (final category in localCategories) {
        final docRef = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_categoriesCollection).doc(category.id.toString());

        batch.set(docRef, {
          ...category.toJson(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error syncing categories to Firebase: $e');
    }
  }

  Future<void> _bidirectionalSyncCategories(DateTime lastSyncTime) async {
    try {
      // Get Firebase categories updated after last sync
      final firebaseSnapshot = await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_categoriesCollection).where('updated_at', isGreaterThan: Timestamp.fromDate(lastSyncTime)).get();

      // Get local categories
      final localCategories = await _hiveService.getCategories();
      final localCategoriesMap = {for (var category in localCategories) category.id: category};

      final batch = _firestore.batch();

      // Process Firebase categories
      for (final doc in firebaseSnapshot.docs) {
        final firebaseCategory = CategoryModel.fromJson(doc.data());
        final localCategory = localCategoriesMap[firebaseCategory.id];

        if (localCategory == null) {
          // Firebase category doesn't exist locally, add it
          await _hiveService.addCategory(firebaseCategory);
        } else {
          // Both exist, use most recent
          await _hiveService.updateCategory(firebaseCategory);
        }
      }

      // Process local categories that might need to be uploaded
      for (final category in localCategories) {
        final docRef = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_categoriesCollection).doc(category.id.toString());

        batch.set(
            docRef,
            {
              ...category.toJson(),
              'updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error in bidirectional sync for categories: $e');
    }
  }

  // ===============================
  // TASK LOGS METHODS
  // ===============================

  Future<void> _syncTaskLogsFromFirebase() async {
    try {
      debugPrint('🔄 Syncing task logs from Firebase...');
      final querySnapshot = await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_taskLogsCollection).get();

      debugPrint('Found ${querySnapshot.docs.length} task logs in Firebase');

      // Get all existing local task logs
      final localTaskLogs = await _hiveService.getTaskLogs();
      final Map<int, TaskLogModel> localTaskLogMap = {for (final taskLog in localTaskLogs) taskLog.id: taskLog};

      for (final doc in querySnapshot.docs) {
        try {
          final taskLogData = doc.data();
          final taskLogModel = TaskLogModel.fromJson(taskLogData);

          // Check if task log exists locally
          if (!localTaskLogMap.containsKey(taskLogModel.id)) {
            // Add new task log (task logs are usually not updated, only added)
            await _hiveService.addTaskLog(taskLogModel);
            debugPrint('Added new task log: ${taskLogModel.id}');
          }
        } catch (e) {
          debugPrint('Error processing task log ${doc.id}: $e');
        }
      }

      debugPrint('✅ Task logs sync from Firebase completed');
    } catch (e) {
      debugPrint('❌ Error syncing task logs from Firebase: $e');
      rethrow;
    }
  }

  Future<void> _syncTaskLogsToFirebase() async {
    try {
      final localTaskLogs = await _hiveService.getTaskLogs();
      final batch = _firestore.batch();

      for (final taskLog in localTaskLogs) {
        final docRef = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_taskLogsCollection).doc(taskLog.id.toString());

        batch.set(docRef, {
          ...taskLog.toJson(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error syncing task logs to Firebase: $e');
    }
  }

  Future<void> _bidirectionalSyncTaskLogs(DateTime lastSyncTime) async {
    try {
      // Get Firebase task logs updated after last sync
      final firebaseSnapshot = await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_taskLogsCollection).where('updated_at', isGreaterThan: Timestamp.fromDate(lastSyncTime)).get();

      // Get local task logs
      final localTaskLogs = await _hiveService.getTaskLogs();
      final localTaskLogsMap = {for (var log in localTaskLogs) log.id: log};

      final batch = _firestore.batch();

      // Process Firebase task logs
      for (final doc in firebaseSnapshot.docs) {
        final firebaseTaskLog = TaskLogModel.fromJson(doc.data());
        final localTaskLog = localTaskLogsMap[firebaseTaskLog.id];

        if (localTaskLog == null) {
          // Firebase task log doesn't exist locally, add it
          await _hiveService.addTaskLog(firebaseTaskLog);
        }
      }

      // Process local task logs that might need to be uploaded
      for (final taskLog in localTaskLogs) {
        final docRef = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_taskLogsCollection).doc(taskLog.id.toString());

        batch.set(
            docRef,
            {
              ...taskLog.toJson(),
              'updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error in bidirectional sync for task logs: $e');
    }
  }

  // ===============================
  // INDIVIDUAL ITEM METHODS
  // ===============================

  /// Add single task to Firebase
  Future<void> addTaskToFirebase(TaskModel task) async {
    if (currentUserUid == null) return;

    try {
      await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_tasksCollection).doc(task.id.toString()).set({
        ...task.toJson(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding task to Firebase: $e');
    }
  }

  /// Update single task in Firebase
  Future<void> updateTaskInFirebase(TaskModel task) async {
    if (currentUserUid == null) return;

    try {
      await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_tasksCollection).doc(task.id.toString()).update({
        ...task.toJson(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating task in Firebase: $e');
    }
  }

  /// Delete single task from Firebase
  Future<void> deleteTaskFromFirebase(int taskId) async {
    if (currentUserUid == null) return;

    try {
      // Delete the task from Firebase
      await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_tasksCollection).doc(taskId.toString()).delete();

      // Track the deletion
      await _trackDeletedItem('task', taskId);

      debugPrint('✅ Deleted task from Firebase: $taskId');
    } catch (e) {
      debugPrint('❌ Error deleting task from Firebase: $e');
    }
  }

  /// Add single item to Firebase
  Future<void> addItemToFirebase(ItemModel item) async {
    if (currentUserUid == null) return;

    try {
      await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_itemsCollection).doc(item.id.toString()).set({
        ...item.toJson(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding item to Firebase: $e');
    }
  }

  /// Update single item in Firebase
  Future<void> updateItemInFirebase(ItemModel item) async {
    if (currentUserUid == null) return;

    try {
      await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_itemsCollection).doc(item.id.toString()).update({
        ...item.toJson(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating item in Firebase: $e');
    }
  }

  /// Delete single item from Firebase
  Future<void> deleteItemFromFirebase(int itemId) async {
    if (currentUserUid == null) return;

    try {
      // Delete the item from Firebase
      await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_itemsCollection).doc(itemId.toString()).delete();

      // Track the deletion
      await _trackDeletedItem('item', itemId);

      debugPrint('✅ Deleted item from Firebase: $itemId');
    } catch (e) {
      debugPrint('❌ Error deleting item from Firebase: $e');
    }
  }

  /// Update single routine in Firebase
  Future<void> updateRoutineInFirebase(RoutineModel routine) async {
    if (currentUserUid == null) return;

    try {
      await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_routinesCollection).doc(routine.id.toString()).update({
        ...routine.toJson(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating routine in Firebase: $e');
    }
  }

  /// Update single trait in Firebase
  Future<void> updateTraitInFirebase(TraitModel trait) async {
    if (currentUserUid == null) return;

    try {
      await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_traitsCollection).doc(trait.id.toString()).update({
        ...trait.toJson(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating trait in Firebase: $e');
    }
  }

  // ===============================
  // DELETED ITEMS TRACKING
  // ===============================

  /// Track a deleted item in Firebase
  Future<void> _trackDeletedItem(String itemType, int itemId) async {
    if (currentUserUid == null) return;

    try {
      await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_deletedItemsCollection).doc('${itemType}_$itemId').set({
        'item_type': itemType,
        'item_id': itemId,
        'deleted_at': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Tracked deleted item: $itemType $itemId');
    } catch (e) {
      debugPrint('❌ Error tracking deleted item: $e');
    }
  }

  /// Get list of deleted items from Firebase
  Future<Set<String>> getDeletedItems() async {
    if (currentUserUid == null) return {};

    try {
      final snapshot = await _firestore.collection(_usersCollection).doc(currentUserUid).collection(_deletedItemsCollection).get();

      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      debugPrint('❌ Error getting deleted items: $e');
      return {};
    }
  }

  /// Check if an item is deleted
  bool _isItemDeleted(Set<String> deletedItems, String itemType, int itemId) {
    return deletedItems.contains('${itemType}_$itemId');
  }

  // ===============================
  // REAL-TIME SYNC METHODS
  // ===============================

  /// Start real-time listeners for all collections
  Future<void> startRealTimeSync() async {
    if (currentUserUid == null) return;

    try {
      debugPrint('🔄 Starting real-time sync listeners...');

      // Start listeners for each collection
      await _startTasksListener();
      await _startItemsListener();
      await _startTraitsListener();
      await _startRoutinesListener();
      await _startCategoriesListener();
      await _startTaskLogsListener();
      await _startDeletedItemsListener();

      debugPrint('✅ Real-time sync listeners started successfully');
    } catch (e) {
      debugPrint('❌ Error starting real-time sync: $e');
    }
  }

  /// Stop all real-time listeners
  Future<void> stopRealTimeSync() async {
    try {
      debugPrint('🔄 Stopping real-time sync listeners...');

      // Cancel all subscriptions
      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();

      debugPrint('✅ Real-time sync listeners stopped successfully');
    } catch (e) {
      debugPrint('❌ Error stopping real-time sync: $e');
    }
  }

  /// Start real-time listener for tasks
  Future<void> _startTasksListener() async {
    if (currentUserUid == null) return;

    final subscription = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_tasksCollection).snapshots().listen((snapshot) async {
      try {
        debugPrint('🔄 Real-time tasks update: ${snapshot.docs.length} tasks');

        for (final change in snapshot.docChanges) {
          final taskData = change.doc.data();
          if (taskData != null) {
            final taskModel = TaskModel.fromJson(taskData);

            switch (change.type) {
              case DocumentChangeType.added:
                debugPrint('➕ Task added: ${taskModel.title}');
                // Check if task already exists locally to prevent duplicates
                final existingTask = await _hiveService.getTask(taskModel.id);
                if (existingTask == null) {
                  await _hiveService.addTask(taskModel);
                } else {
                  debugPrint('Task already exists locally, skipping add');
                }
                break;
              case DocumentChangeType.modified:
                debugPrint('✏️ Task modified: ${taskModel.title}');
                await _updateTaskDirectly(taskModel);
                break;
              case DocumentChangeType.removed:
                debugPrint('❌ Task removed: ${taskModel.title}');
                await _hiveService.deleteTask(taskModel.id);
                break;
            }
          }
        }

        // Update UI
        TaskProvider().updateItems();
      } catch (e) {
        debugPrint('❌ Error in tasks listener: $e');
      }
    });

    _subscriptions.add(subscription);
  }

  /// Start real-time listener for items
  Future<void> _startItemsListener() async {
    if (currentUserUid == null) return;

    final subscription = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_itemsCollection).snapshots().listen((snapshot) async {
      try {
        debugPrint('🔄 Real-time items update: ${snapshot.docs.length} items');

        for (final change in snapshot.docChanges) {
          final itemData = change.doc.data();
          if (itemData != null) {
            final itemModel = ItemModel.fromJson(itemData);

            switch (change.type) {
              case DocumentChangeType.added:
                debugPrint('➕ Item added: ${itemModel.title}');
                // Check if item already exists locally to prevent duplicates
                final existingItem = await _hiveService.getItem(itemModel.id);
                if (existingItem == null) {
                  await _hiveService.addItem(itemModel);
                } else {
                  debugPrint('Item already exists locally, skipping add');
                }
                break;
              case DocumentChangeType.modified:
                debugPrint('✏️ Item modified: ${itemModel.title}');
                await _updateItemDirectly(itemModel);
                break;
              case DocumentChangeType.removed:
                debugPrint('❌ Item removed: ${itemModel.title}');
                await _hiveService.deleteItem(itemModel.id);
                break;
            }
          }
        }

        // Update UI
        StoreProvider().setStateItems();
      } catch (e) {
        debugPrint('❌ Error in items listener: $e');
      }
    });

    _subscriptions.add(subscription);
  }

  /// Start real-time listener for traits
  Future<void> _startTraitsListener() async {
    if (currentUserUid == null) return;

    final subscription = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_traitsCollection).snapshots().listen((snapshot) async {
      try {
        debugPrint('🔄 Real-time traits update: ${snapshot.docs.length} traits');

        for (final change in snapshot.docChanges) {
          final traitData = change.doc.data();
          if (traitData != null) {
            final traitModel = TraitModel.fromJson(traitData);

            switch (change.type) {
              case DocumentChangeType.added:
                debugPrint('➕ Trait added: ${traitModel.title}');
                // Check if trait already exists locally to prevent duplicates
                final existingTrait = await _hiveService.getTrait(traitModel.id);
                if (existingTrait == null) {
                  await _hiveService.addTrait(traitModel);
                } else {
                  debugPrint('Trait already exists locally, skipping add');
                }
                break;
              case DocumentChangeType.modified:
                debugPrint('✏️ Trait modified: ${traitModel.title}');
                await _updateTraitDirectly(traitModel);
                break;
              case DocumentChangeType.removed:
                debugPrint('❌ Trait removed: ${traitModel.title}');
                await _hiveService.deleteTrait(traitModel.id);
                break;
            }
          }
        }

        // Update UI
        TraitProvider().updateItems();
      } catch (e) {
        debugPrint('❌ Error in traits listener: $e');
      }
    });

    _subscriptions.add(subscription);
  }

  /// Start real-time listener for routines
  Future<void> _startRoutinesListener() async {
    if (currentUserUid == null) return;

    final subscription = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_routinesCollection).snapshots().listen((snapshot) async {
      try {
        debugPrint('🔄 Real-time routines update: ${snapshot.docs.length} routines');

        for (final change in snapshot.docChanges) {
          final routineData = change.doc.data();
          if (routineData != null) {
            final routineModel = RoutineModel.fromJson(routineData);

            switch (change.type) {
              case DocumentChangeType.added:
                debugPrint('➕ Routine added: ${routineModel.title}');
                // Check if routine already exists locally to prevent duplicates
                final existingRoutine = await _hiveService.getRoutine(routineModel.id);
                if (existingRoutine == null) {
                  await _hiveService.addRoutine(routineModel);
                } else {
                  debugPrint('Routine already exists locally, skipping add');
                }
                break;
              case DocumentChangeType.modified:
                debugPrint('✏️ Routine modified: ${routineModel.title}');
                await _updateRoutineDirectly(routineModel);
                break;
              case DocumentChangeType.removed:
                debugPrint('❌ Routine removed: ${routineModel.title}');
                await _hiveService.deleteRoutine(routineModel.id);
                break;
            }
          }
        }

        // Update UI
        TaskProvider().updateItems();
      } catch (e) {
        debugPrint('❌ Error in routines listener: $e');
      }
    });

    _subscriptions.add(subscription);
  }

  /// Start real-time listener for categories
  Future<void> _startCategoriesListener() async {
    if (currentUserUid == null) return;

    final subscription = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_categoriesCollection).snapshots().listen((snapshot) async {
      try {
        debugPrint('🔄 Real-time categories update: ${snapshot.docs.length} categories');

        for (final change in snapshot.docChanges) {
          final categoryData = change.doc.data();
          if (categoryData != null) {
            final categoryModel = CategoryModel.fromJson(categoryData);

            switch (change.type) {
              case DocumentChangeType.added:
                debugPrint('➕ Category added: ${categoryModel.title}');
                // Check if category already exists locally to prevent duplicates
                final existingCategory = await _hiveService.getCategory(categoryModel.id);
                if (existingCategory == null) {
                  await _hiveService.addCategory(categoryModel);
                } else {
                  debugPrint('Category already exists locally, skipping add');
                }
                break;
              case DocumentChangeType.modified:
                debugPrint('✏️ Category modified: ${categoryModel.title}');
                await _hiveService.updateCategory(categoryModel);
                break;
              case DocumentChangeType.removed:
                debugPrint('❌ Category removed: ${categoryModel.title}');
                await _hiveService.deleteCategory(categoryModel.id);
                break;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error in categories listener: $e');
      }
    });

    _subscriptions.add(subscription);
  }

  /// Start real-time listener for task logs
  Future<void> _startTaskLogsListener() async {
    if (currentUserUid == null) return;

    final subscription = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_taskLogsCollection).snapshots().listen((snapshot) async {
      try {
        debugPrint('🔄 Real-time task logs update: ${snapshot.docs.length} task logs');

        for (final change in snapshot.docChanges) {
          final taskLogData = change.doc.data();
          if (taskLogData != null) {
            final taskLogModel = TaskLogModel.fromJson(taskLogData);

            switch (change.type) {
              case DocumentChangeType.added:
                debugPrint('➕ Task log added: ${taskLogModel.id}');
                // Check if task log already exists locally to prevent duplicates
                final existingTaskLog = await _hiveService.getTaskLog(taskLogModel.id);
                if (existingTaskLog == null) {
                  await _hiveService.addTaskLog(taskLogModel);
                } else {
                  debugPrint('Task log already exists locally, skipping add');
                }
                break;
              case DocumentChangeType.modified:
                debugPrint('✏️ Task log modified: ${taskLogModel.id}');
                // Task logs are usually not modified, but handle it just in case
                break;
              case DocumentChangeType.removed:
                debugPrint('❌ Task log removed: ${taskLogModel.id}');
                // Task logs are usually not removed, but handle it just in case
                break;
            }
          }
        }

        // Update UI
        TaskLogProvider().updateItems();
      } catch (e) {
        debugPrint('❌ Error in task logs listener: $e');
      }
    });

    _subscriptions.add(subscription);
  }

  /// Start real-time listener for deleted items
  Future<void> _startDeletedItemsListener() async {
    if (currentUserUid == null) return;

    final subscription = _firestore.collection(_usersCollection).doc(currentUserUid).collection(_deletedItemsCollection).snapshots().listen((snapshot) async {
      try {
        debugPrint('🔄 Real-time deleted items update: ${snapshot.docs.length} deleted items');

        for (final change in snapshot.docChanges) {
          final deletedData = change.doc.data();
          if (deletedData != null && change.type == DocumentChangeType.added) {
            final itemType = deletedData['item_type'] as String;
            final itemId = deletedData['item_id'] as int;

            debugPrint('🗑️ Item deleted remotely: $itemType $itemId');

            // Remove the item from local storage
            switch (itemType) {
              case 'task':
                await _hiveService.deleteTask(itemId);
                TaskProvider().updateItems();
                break;
              case 'item':
                await _hiveService.deleteItem(itemId);
                StoreProvider().setStateItems();
                break;
              case 'trait':
                await _hiveService.deleteTrait(itemId);
                TraitProvider().updateItems();
                break;
              case 'routine':
                await _hiveService.deleteRoutine(itemId);
                TaskProvider().updateItems();
                break;
              case 'category':
                await _hiveService.deleteCategory(itemId);
                break;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error in deleted items listener: $e');
      }
    });

    _subscriptions.add(subscription);
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Check if user is online
  Future<bool> isOnline() async {
    try {
      await _firestore.enableNetwork();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all Firebase data for current user
  Future<void> clearUserDataFromFirebase() async {
    if (currentUserUid == null) return;

    try {
      final batch = _firestore.batch();

      // Delete all subcollections
      final collections = [
        _tasksCollection,
        _itemsCollection,
        _traitsCollection,
        _routinesCollection,
        _categoriesCollection,
        _taskLogsCollection,
      ];

      for (final collection in collections) {
        final snapshot = await _firestore.collection(_usersCollection).doc(currentUserUid).collection(collection).get();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      // Delete user document
      batch.delete(_firestore.collection(_usersCollection).doc(currentUserUid));

      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing user data from Firebase: $e');
    }
  }

  /// Listen to real-time changes for tasks
  Stream<List<TaskModel>> listenToTasks() {
    if (currentUserUid == null) return Stream.value([]);

    return _firestore.collection(_usersCollection).doc(currentUserUid).collection(_tasksCollection).snapshots().map((snapshot) => snapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList());
  }

  /// Listen to real-time changes for items
  Stream<List<ItemModel>> listenToItems() {
    if (currentUserUid == null) return Stream.value([]);

    return _firestore.collection(_usersCollection).doc(currentUserUid).collection(_itemsCollection).snapshots().map((snapshot) => snapshot.docs.map((doc) => ItemModel.fromJson(doc.data())).toList());
  }

  // Add methods for direct Hive updates (used by real-time listeners)
  Future<void> _updateTaskDirectly(TaskModel taskModel) async {
    await _hiveService.updateTask(taskModel);
  }

  Future<void> _updateItemDirectly(ItemModel itemModel) async {
    await _hiveService.updateItem(itemModel);
  }

  Future<void> _updateTraitDirectly(TraitModel traitModel) async {
    await _hiveService.updateTrait(traitModel);
  }

  Future<void> _updateRoutineDirectly(RoutineModel routineModel) async {
    await _hiveService.updateRoutine(routineModel);
  }

  // Real-time sync status
  bool get isRealTimeSyncActive => _subscriptions.isNotEmpty;

  // Real-time sync methods
}
