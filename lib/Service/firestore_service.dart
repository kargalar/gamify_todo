import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/offline_mode_provider.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final HiveService _hiveService = HiveService();
  final OfflineModeProvider _offlineModeProvider = OfflineModeProvider();

  // Real-time listeners
  StreamSubscription<QuerySnapshot>? _tasksListener;
  StreamSubscription<QuerySnapshot>? _taskLogsListener;
  StreamSubscription<QuerySnapshot>? _storeItemsListener;
  StreamSubscription<QuerySnapshot>? _categoriesListener;
  StreamSubscription<QuerySnapshot>? _traitsListener;
  StreamSubscription<QuerySnapshot>? _routinesListener;

  // Collection names
  static const String _usersCollection = 'users';
  static const String _tasksCollection = 'tasks';
  static const String _taskLogsCollection = 'task_logs';
  static const String _categoriesCollection = 'categories';
  static const String _traitsCollection = 'traits';
  static const String _storeItemsCollection = 'store_items';
  static const String _routinesCollection = 'routines';
  static const String _syncMetadataCollection = 'sync_metadata';

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Check if user is authenticated and offline mode is disabled
  bool get isAuthenticated => _currentUserId != null && !_offlineModeProvider.shouldDisableFirebase();

  // Get user's document reference
  DocumentReference? get _userDoc => _currentUserId != null ? _firestore.collection(_usersCollection).doc(_currentUserId) : null;

  // Enable offline persistence
  Future<void> enableOfflinePersistence() async {
    if (_offlineModeProvider.shouldDisableFirebase()) {
      debugPrint('Offline mode enabled, skipping Firestore persistence');
      return;
    }

    try {
      // 'enablePersistence' is deprecated and shouldn't be used. Use Settings.persistenceEnabled instead.
      // Try replacing the use of the deprecated member with the replacement.dartdeprecated_member_use
      // ignore: deprecated_member_use
      await _firestore.enablePersistence();
      debugPrint('Firestore offline persistence enabled');
    } catch (e) {
      debugPrint('Error enabling offline persistence: $e');
    }
  }

  // ==================== SYNC METADATA ====================

  /// Get last sync timestamp for a collection
  Future<DateTime?> getLastSyncTime(String collection) async {
    if (!isAuthenticated) return null;

    try {
      final doc = await _userDoc!.collection(_syncMetadataCollection).doc(collection).get();

      if (doc.exists && doc.data() != null) {
        final timestamp = doc.data()!['lastSyncTime'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting last sync time for $collection: $e');
      return null;
    }
  }

  /// Update last sync timestamp for a collection
  Future<void> updateLastSyncTime(String collection) async {
    if (!isAuthenticated) return;

    try {
      await _userDoc!.collection(_syncMetadataCollection).doc(collection).set({'lastSyncTime': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error updating last sync time for $collection: $e');
    }
  }

  // ==================== TASKS ====================

  /// Upload all tasks to Firestore
  Future<bool> uploadTasks() async {
    if (!isAuthenticated) return false;

    try {
      final tasks = await _hiveService.getTasks();
      final batch = _firestore.batch();

      for (final task in tasks) {
        final taskData = _taskToFirestoreMap(task);
        final docRef = _userDoc!.collection(_tasksCollection).doc(task.id.toString());
        batch.set(docRef, taskData, SetOptions(merge: true));
      }

      await batch.commit();
      await updateLastSyncTime(_tasksCollection);
      debugPrint('Tasks uploaded successfully: ${tasks.length} tasks');
      return true;
    } catch (e) {
      debugPrint('Error uploading tasks: $e');
      return false;
    }
  }

  /// Download tasks from Firestore
  Future<bool> downloadTasks({DateTime? lastSyncTime}) async {
    if (!isAuthenticated) return false;

    try {
      Query query = _userDoc!.collection(_tasksCollection);

      // If lastSyncTime is provided, only get updated documents
      if (lastSyncTime != null) {
        query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get();
      final List<TaskModel> tasks = [];

      for (final doc in snapshot.docs) {
        try {
          final task = _firestoreMapToTask(doc.data() as Map<String, dynamic>);
          tasks.add(task);
        } catch (e) {
          debugPrint('Error parsing task ${doc.id}: $e');
        }
      }

      // Save tasks to local storage
      for (final task in tasks) {
        // Existing task varsa, mevcut task'ın durumunu koru
        final existingTasks = await _hiveService.getTasks();
        final existingTask = existingTasks.where((t) => t.id == task.id).isNotEmpty ? existingTasks.firstWhere((t) => t.id == task.id) : null;

        if (existingTask != null) {
          // Update existing task - sync all changes from remote including status
          existingTask.title = task.title;
          existingTask.description = task.description;
          existingTask.priority = task.priority;
          existingTask.categoryId = task.categoryId;
          existingTask.subtasks = task.subtasks;
          existingTask.location = task.location;
          existingTask.attachmentPaths = task.attachmentPaths;
          existingTask.attributeIDList = task.attributeIDList;
          existingTask.skillIDList = task.skillIDList;

          // Update progress values
          if (task.type == existingTask.type) {
            existingTask.currentDuration = task.currentDuration;
            existingTask.remainingDuration = task.remainingDuration;
            existingTask.currentCount = task.currentCount;
            existingTask.targetCount = task.targetCount;
            existingTask.isTimerActive = task.isTimerActive;
          }

          // IMPORTANT: Sync status changes from remote
          existingTask.status = task.status;

          // Sync date and time changes too
          if (task.taskDate != null) {
            existingTask.taskDate = task.taskDate;
          }
          if (task.time != null) {
            existingTask.time = task.time;
          }

          await _hiveService.updateTask(existingTask);
        } else {
          // Yeni task ise direkt ekle
          await _hiveService.addTask(task);
        }
      }

      await updateLastSyncTime(_tasksCollection);
      debugPrint('Tasks downloaded successfully: ${tasks.length} tasks');
      return true;
    } catch (e) {
      debugPrint('Error downloading tasks: $e');
      return false;
    }
  }

  /// Sync a single task to Firestore
  Future<bool> syncTask(TaskModel task) async {
    if (!isAuthenticated) return false;

    try {
      final taskData = _taskToFirestoreMap(task);
      final docRef = _userDoc!.collection(_tasksCollection).doc(task.id.toString());

      // Önce document'in var olup olmadığını kontrol et
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Document varsa merge ile güncelle
        await docRef.set(taskData, SetOptions(merge: true));
      } else {
        // Document yoksa direkt oluştur
        await docRef.set(taskData);
      }

      debugPrint('Task synced successfully: ${task.title}');
      return true;
    } catch (e) {
      debugPrint('Error syncing task: $e');
      return false;
    }
  }

  /// Delete task from Firestore
  Future<bool> deleteTaskFromFirestore(int taskId) async {
    if (!isAuthenticated) return false;

    try {
      await _userDoc!.collection(_tasksCollection).doc(taskId.toString()).delete();
      debugPrint('Task deleted from Firestore: $taskId');
      return true;
    } catch (e) {
      debugPrint('Error deleting task from Firestore: $e');
      return false;
    }
  }

  // ==================== TASK LOGS ====================

  /// Upload task logs to Firestore
  Future<bool> uploadTaskLogs() async {
    if (!isAuthenticated) return false;

    try {
      final logs = await _hiveService.getTaskLogs();
      final batch = _firestore.batch();

      for (final log in logs) {
        final logData = _taskLogToFirestoreMap(log);
        final docRef = _userDoc!.collection(_taskLogsCollection).doc(log.id.toString());
        batch.set(docRef, logData, SetOptions(merge: true));
      }

      await batch.commit();
      await updateLastSyncTime(_taskLogsCollection);
      debugPrint('Task logs uploaded successfully: ${logs.length} logs');
      return true;
    } catch (e) {
      debugPrint('Error uploading task logs: $e');
      return false;
    }
  }

  /// Download task logs from Firestore
  Future<bool> downloadTaskLogs({DateTime? lastSyncTime}) async {
    if (!isAuthenticated) return false;

    try {
      Query query = _userDoc!.collection(_taskLogsCollection);

      if (lastSyncTime != null) {
        query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get();
      final List<TaskLogModel> logs = [];

      for (final doc in snapshot.docs) {
        try {
          final log = _firestoreMapToTaskLog(doc.data() as Map<String, dynamic>);
          logs.add(log);
        } catch (e) {
          debugPrint('Error parsing task log ${doc.id}: $e');
        }
      }

      for (final log in logs) {
        await _hiveService.addTaskLog(log);
      }

      await updateLastSyncTime(_taskLogsCollection);
      debugPrint('Task logs downloaded successfully: ${logs.length} logs');
      return true;
    } catch (e) {
      debugPrint('Error downloading task logs: $e');
      return false;
    }
  }

  /// Sync a single task log to Firestore
  Future<bool> syncTaskLog(TaskLogModel log) async {
    if (!isAuthenticated) return false;

    try {
      final logData = _taskLogToFirestoreMap(log);
      final docRef = _userDoc!.collection(_taskLogsCollection).doc(log.id.toString());

      // Önce document'in var olup olmadığını kontrol et
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Document varsa merge ile güncelle
        await docRef.set(logData, SetOptions(merge: true));
      } else {
        // Document yoksa direkt oluştur
        await docRef.set(logData);
      }

      debugPrint('Task log synced successfully: ${log.taskTitle}');
      return true;
    } catch (e) {
      debugPrint('Error syncing task log: $e');
      return false;
    }
  }

  // ==================== CATEGORIES ====================

  /// Upload categories to Firestore
  Future<bool> uploadCategories() async {
    if (!isAuthenticated) return false;

    try {
      final categories = await _hiveService.getCategories();
      final batch = _firestore.batch();

      for (final category in categories) {
        final categoryData = _categoryToFirestoreMap(category);
        final docRef = _userDoc!.collection(_categoriesCollection).doc(category.id.toString());
        batch.set(docRef, categoryData, SetOptions(merge: true));
      }

      await batch.commit();
      await updateLastSyncTime(_categoriesCollection);
      debugPrint('Categories uploaded successfully: ${categories.length} categories');
      return true;
    } catch (e) {
      debugPrint('Error uploading categories: $e');
      return false;
    }
  }

  /// Download categories from Firestore
  Future<bool> downloadCategories({DateTime? lastSyncTime}) async {
    if (!isAuthenticated) return false;

    try {
      Query query = _userDoc!.collection(_categoriesCollection);

      if (lastSyncTime != null) {
        query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get();
      final List<CategoryModel> categories = [];

      for (final doc in snapshot.docs) {
        try {
          final category = _firestoreMapToCategory(doc.data() as Map<String, dynamic>);
          categories.add(category);
        } catch (e) {
          debugPrint('Error parsing category ${doc.id}: $e');
        }
      }

      for (final category in categories) {
        await _hiveService.addCategory(category);
      }

      await updateLastSyncTime(_categoriesCollection);
      debugPrint('Categories downloaded successfully: ${categories.length} categories');
      return true;
    } catch (e) {
      debugPrint('Error downloading categories: $e');
      return false;
    }
  }

  /// Sync a single category to Firestore
  Future<bool> syncCategory(CategoryModel category) async {
    if (!isAuthenticated) return false;

    try {
      final categoryData = _categoryToFirestoreMap(category);
      final docRef = _userDoc!.collection(_categoriesCollection).doc(category.id.toString());

      // Önce document'in var olup olmadığını kontrol et
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Document varsa merge ile güncelle
        await docRef.set(categoryData, SetOptions(merge: true));
      } else {
        // Document yoksa direkt oluştur
        await docRef.set(categoryData);
      }

      debugPrint('Category synced successfully: ${category.title}');
      return true;
    } catch (e) {
      debugPrint('Error syncing category: $e');
      return false;
    }
  }

  // ==================== TRAITS ====================

  /// Upload traits to Firestore
  Future<bool> uploadTraits() async {
    if (!isAuthenticated) return false;

    try {
      final traits = await _hiveService.getTraits();
      final batch = _firestore.batch();

      for (final trait in traits) {
        final traitData = _traitToFirestoreMap(trait);
        final docRef = _userDoc!.collection(_traitsCollection).doc(trait.id.toString());
        batch.set(docRef, traitData, SetOptions(merge: true));
      }

      await batch.commit();
      await updateLastSyncTime(_traitsCollection);
      debugPrint('Traits uploaded successfully: ${traits.length} traits');
      return true;
    } catch (e) {
      debugPrint('Error uploading traits: $e');
      return false;
    }
  }

  /// Download traits from Firestore
  Future<bool> downloadTraits({DateTime? lastSyncTime}) async {
    if (!isAuthenticated) return false;

    try {
      Query query = _userDoc!.collection(_traitsCollection);

      if (lastSyncTime != null) {
        query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get();
      final List<TraitModel> traits = [];

      for (final doc in snapshot.docs) {
        try {
          final trait = _firestoreMapToTrait(doc.data() as Map<String, dynamic>);
          traits.add(trait);
        } catch (e) {
          debugPrint('Error parsing trait ${doc.id}: $e');
        }
      }

      for (final trait in traits) {
        await _hiveService.addTrait(trait);
      }

      await updateLastSyncTime(_traitsCollection);
      debugPrint('Traits downloaded successfully: ${traits.length} traits');
      return true;
    } catch (e) {
      debugPrint('Error downloading traits: $e');
      return false;
    }
  }

  /// Sync a single trait to Firestore
  Future<bool> syncTrait(TraitModel trait) async {
    if (!isAuthenticated) return false;

    try {
      final traitData = _traitToFirestoreMap(trait);
      final docRef = _userDoc!.collection(_traitsCollection).doc(trait.id.toString());

      // Önce document'in var olup olmadığını kontrol et
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Document varsa merge ile güncelle
        await docRef.set(traitData, SetOptions(merge: true));
      } else {
        // Document yoksa direkt oluştur
        await docRef.set(traitData);
      }

      debugPrint('Trait synced successfully: ${trait.title}');
      return true;
    } catch (e) {
      debugPrint('Error syncing trait: $e');
      return false;
    }
  }

  // ==================== STORE ITEMS ====================

  /// Upload store items to Firestore
  Future<bool> uploadStoreItems() async {
    if (!isAuthenticated) return false;

    try {
      final storeItems = await _hiveService.getItems();
      final batch = _firestore.batch();

      for (final item in storeItems) {
        final itemData = _storeItemToFirestoreMap(item);
        final docRef = _userDoc!.collection(_storeItemsCollection).doc(item.id.toString());
        batch.set(docRef, itemData, SetOptions(merge: true));
      }

      await batch.commit();
      await updateLastSyncTime(_storeItemsCollection);
      debugPrint('Store items uploaded successfully: ${storeItems.length} items');
      return true;
    } catch (e) {
      debugPrint('Error uploading store items: $e');
      return false;
    }
  }

  /// Download store items from Firestore
  Future<bool> downloadStoreItems({DateTime? lastSyncTime}) async {
    if (!isAuthenticated) return false;

    try {
      Query query = _userDoc!.collection(_storeItemsCollection);

      if (lastSyncTime != null) {
        query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get();
      final List<ItemModel> storeItems = [];

      for (final doc in snapshot.docs) {
        try {
          final item = _firestoreMapToStoreItem(doc.data() as Map<String, dynamic>);
          storeItems.add(item);
        } catch (e) {
          debugPrint('Error parsing store item ${doc.id}: $e');
        }
      }

      for (final item in storeItems) {
        await _hiveService.addItem(item);
      }

      await updateLastSyncTime(_storeItemsCollection);
      debugPrint('Store items downloaded successfully: ${storeItems.length} items');
      return true;
    } catch (e) {
      debugPrint('Error downloading store items: $e');
      return false;
    }
  }

  /// Sync a single store item to Firestore
  Future<bool> syncStoreItem(ItemModel item) async {
    if (!isAuthenticated) return false;

    try {
      final itemData = _storeItemToFirestoreMap(item);
      final docRef = _userDoc!.collection(_storeItemsCollection).doc(item.id.toString());

      // Önce document'in var olup olmadığını kontrol et
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Document varsa merge ile güncelle
        await docRef.set(itemData, SetOptions(merge: true));
      } else {
        // Document yoksa direkt oluştur
        await docRef.set(itemData);
      }

      debugPrint('Store item synced successfully: ${item.title}');
      return true;
    } catch (e) {
      debugPrint('Error syncing store item: $e');
      return false;
    }
  }

  // ==================== ROUTINES ====================

  /// Upload routines to Firestore
  Future<bool> uploadRoutines() async {
    if (!isAuthenticated) return false;

    try {
      final routines = await _hiveService.getRoutines();
      final batch = _firestore.batch();

      for (final routine in routines) {
        final routineData = _routineToFirestoreMap(routine);
        final docRef = _userDoc!.collection(_routinesCollection).doc(routine.id.toString());
        batch.set(docRef, routineData, SetOptions(merge: true));
      }

      await batch.commit();
      await updateLastSyncTime(_routinesCollection);
      debugPrint('Routines uploaded successfully: ${routines.length} routines');
      return true;
    } catch (e) {
      debugPrint('Error uploading routines: $e');
      return false;
    }
  }

  /// Download routines from Firestore
  Future<bool> downloadRoutines({DateTime? lastSyncTime}) async {
    if (!isAuthenticated) return false;

    try {
      Query query = _userDoc!.collection(_routinesCollection);

      if (lastSyncTime != null) {
        query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncTime));
      }

      final snapshot = await query.get();
      final List<RoutineModel> routines = [];

      for (final doc in snapshot.docs) {
        try {
          final routine = _firestoreMapToRoutine(doc.data() as Map<String, dynamic>);
          routines.add(routine);
        } catch (e) {
          debugPrint('Error parsing routine ${doc.id}: $e');
        }
      }

      for (final routine in routines) {
        await _hiveService.addRoutine(routine);
      }

      await updateLastSyncTime(_routinesCollection);
      debugPrint('Routines downloaded successfully: ${routines.length} routines');
      return true;
    } catch (e) {
      debugPrint('Error downloading routines: $e');
      return false;
    }
  }

  /// Sync a single routine to Firestore
  Future<bool> syncRoutine(RoutineModel routine) async {
    if (!isAuthenticated) return false;

    try {
      final routineData = _routineToFirestoreMap(routine);
      final docRef = _userDoc!.collection(_routinesCollection).doc(routine.id.toString());

      // Önce document'in var olup olmadığını kontrol et
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Document varsa merge ile güncelle
        await docRef.set(routineData, SetOptions(merge: true));
      } else {
        // Document yoksa direkt oluştur
        await docRef.set(routineData);
      }

      debugPrint('Routine synced successfully: ${routine.title}');
      return true;
    } catch (e) {
      debugPrint('Error syncing routine: $e');
      return false;
    }
  }

  // ==================== FULL SYNC ====================

  /// Perform full sync of all data to Firestore
  Future<bool> performFullUpload() async {
    if (!isAuthenticated) {
      Helper().getMessage(
        status: StatusEnum.ERROR,
        message: "Kullanıcı kimlik doğrulaması yapılmamış",
      );
      return false;
    }

    try {
      debugPrint('Starting full upload to Firestore...');

      final results = await Future.wait([
        uploadTasks(),
        uploadTaskLogs(),
        uploadCategories(),
        uploadTraits(),
        uploadStoreItems(),
        uploadRoutines(),
      ]);

      final allSuccess = results.every((result) => result);

      if (allSuccess) {
        Helper().getMessage(
          status: StatusEnum.SUCCESS,
          message: "Tüm veriler başarıyla yedeklendi",
        );
        debugPrint('Full upload done successfully');
      } else {
        Helper().getMessage(
          status: StatusEnum.WARNING,
          message: "Bazı veriler yedeklenemedi",
        );
        debugPrint('Some uploads failed');
      }

      return allSuccess;
    } catch (e) {
      debugPrint('Error during full upload: $e');
      Helper().getMessage(
        status: StatusEnum.ERROR,
        message: "Yedekleme sırasında hata oluştu: $e",
      );
      return false;
    }
  }

  /// Perform full sync of all data from Firestore
  Future<bool> performFullDownload() async {
    if (!isAuthenticated) {
      Helper().getMessage(
        status: StatusEnum.ERROR,
        message: "Kullanıcı kimlik doğrulaması yapılmamış",
      );
      return false;
    }

    try {
      debugPrint('Starting full download from Firestore...');

      final results = await Future.wait([
        downloadTasks(),
        downloadTaskLogs(),
        downloadCategories(),
        downloadTraits(),
        downloadStoreItems(),
        downloadRoutines(),
      ]);

      final allSuccess = results.every((result) => result);

      if (allSuccess) {
        Helper().getMessage(
          status: StatusEnum.SUCCESS,
          message: "Tüm veriler başarıyla indirildi",
        );
        debugPrint('Full download done successfully');
      } else {
        Helper().getMessage(
          status: StatusEnum.WARNING,
          message: "Bazı veriler indirilemedi",
        );
        debugPrint('Some downloads failed');
      }

      return allSuccess;
    } catch (e) {
      debugPrint('Error during full download: $e');
      Helper().getMessage(
        status: StatusEnum.ERROR,
        message: "İndirme sırasında hata oluştu: $e",
      );
      return false;
    }
  }

  /// Perform incremental sync (download only updated data)
  Future<bool> performIncrementalSync() async {
    if (!isAuthenticated) return false;

    try {
      debugPrint('Starting incremental sync...');

      final collections = [
        _tasksCollection,
        _taskLogsCollection,
        _categoriesCollection,
        _traitsCollection,
        _storeItemsCollection,
        _routinesCollection,
      ];

      final futures = <Future<bool>>[];

      for (final collection in collections) {
        final lastSyncTime = await getLastSyncTime(collection);

        switch (collection) {
          case _tasksCollection:
            futures.add(downloadTasks(lastSyncTime: lastSyncTime));
            break;
          case _taskLogsCollection:
            futures.add(downloadTaskLogs(lastSyncTime: lastSyncTime));
            break;
          case _categoriesCollection:
            futures.add(downloadCategories(lastSyncTime: lastSyncTime));
            break;
          case _traitsCollection:
            futures.add(downloadTraits(lastSyncTime: lastSyncTime));
            break;
          case _storeItemsCollection:
            futures.add(downloadStoreItems(lastSyncTime: lastSyncTime));
            break;
          case _routinesCollection:
            futures.add(downloadRoutines(lastSyncTime: lastSyncTime));
            break;
        }
      }

      final results = await Future.wait(futures);
      final allSuccess = results.every((result) => result);

      debugPrint('Incremental sync completed. Success: $allSuccess');
      return allSuccess;
    } catch (e) {
      debugPrint('Error during incremental sync: $e');
      return false;
    }
  }

  // ==================== CONVERSION METHODS ====================

  /// Convert TaskModel to Firestore map
  Map<String, dynamic> _taskToFirestoreMap(TaskModel task) {
    final map = task.toJson();
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  /// Convert Firestore map to TaskModel
  TaskModel _firestoreMapToTask(Map<String, dynamic> data) {
    // Remove Firestore-specific fields
    data.remove('updatedAt');
    return TaskModel.fromJson(data);
  }

  /// Convert TaskLogModel to Firestore map
  Map<String, dynamic> _taskLogToFirestoreMap(TaskLogModel log) {
    final map = log.toJson();
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  /// Convert Firestore map to TaskLogModel
  TaskLogModel _firestoreMapToTaskLog(Map<String, dynamic> data) {
    data.remove('updatedAt');
    return TaskLogModel.fromJson(data);
  }

  /// Convert CategoryModel to Firestore map
  Map<String, dynamic> _categoryToFirestoreMap(CategoryModel category) {
    final map = category.toJson();
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  /// Convert Firestore map to CategoryModel
  CategoryModel _firestoreMapToCategory(Map<String, dynamic> data) {
    data.remove('updatedAt');
    return CategoryModel.fromJson(data);
  }

  /// Convert TraitModel to Firestore map
  Map<String, dynamic> _traitToFirestoreMap(TraitModel trait) {
    final map = trait.toJson();
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  /// Convert Firestore map to TraitModel
  TraitModel _firestoreMapToTrait(Map<String, dynamic> data) {
    data.remove('updatedAt');
    return TraitModel.fromJson(data);
  }

  /// Convert ItemModel to Firestore map
  Map<String, dynamic> _storeItemToFirestoreMap(ItemModel item) {
    final map = item.toJson();
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  /// Convert Firestore map to ItemModel
  ItemModel _firestoreMapToStoreItem(Map<String, dynamic> data) {
    data.remove('updatedAt');
    return ItemModel.fromJson(data);
  }

  /// Convert RoutineModel to Firestore map
  Map<String, dynamic> _routineToFirestoreMap(RoutineModel routine) {
    final map = routine.toJson();
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  /// Convert Firestore map to RoutineModel
  RoutineModel _firestoreMapToRoutine(Map<String, dynamic> data) {
    data.remove('updatedAt');
    return RoutineModel.fromJson(data);
  }

  // ==================== REAL-TIME LISTENERS ====================

  /// Start real-time listeners for all collections
  Future<void> startRealtimeListeners() async {
    if (!isAuthenticated) return;

    try {
      debugPrint('Starting real-time listeners...');
      await _startTasksListener();
      await _startTaskLogsListener();
      await _startStoreItemsListener();
      await _startCategoriesListener();
      await _startTraitsListener();
      await _startRoutinesListener();
      debugPrint('Real-time listeners started successfully');
    } catch (e) {
      debugPrint('Error starting real-time listeners: $e');
    }
  }

  /// Stop all real-time listeners
  void stopRealtimeListeners() {
    debugPrint('Stopping real-time listeners...');
    _tasksListener?.cancel();
    _taskLogsListener?.cancel();
    _storeItemsListener?.cancel();
    _categoriesListener?.cancel();
    _traitsListener?.cancel();
    _routinesListener?.cancel();

    _tasksListener = null;
    _taskLogsListener = null;
    _storeItemsListener = null;
    _categoriesListener = null;
    _traitsListener = null;
    _routinesListener = null;
    debugPrint('Real-time listeners stopped');
  }

  /// Start tasks real-time listener
  Future<void> _startTasksListener() async {
    if (!isAuthenticated) return;

    _tasksListener = _userDoc!.collection(_tasksCollection).snapshots().listen(
      (snapshot) async {
        debugPrint('Tasks snapshot received: ${snapshot.docs.length} tasks');

        for (final change in snapshot.docChanges) {
          try {
            final data = change.doc.data() as Map<String, dynamic>;
            final task = _firestoreMapToTask(data);

            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                // Check if task already exists locally
                final existingTasks = await _hiveService.getTasks();
                final existingTask = existingTasks.where((t) => t.id == task.id).isNotEmpty ? existingTasks.firstWhere((t) => t.id == task.id) : null;

                if (existingTask != null) {
                  debugPrint('Updating existing task from Firestore: ${task.title}');
                  // Update existing task - sync all changes from remote
                  existingTask.title = task.title;
                  existingTask.description = task.description;
                  existingTask.priority = task.priority;
                  existingTask.categoryId = task.categoryId;
                  existingTask.subtasks = task.subtasks;
                  existingTask.location = task.location;
                  existingTask.attachmentPaths = task.attachmentPaths;
                  existingTask.attributeIDList = task.attributeIDList;
                  existingTask.skillIDList = task.skillIDList;

                  // Update progress values
                  if (task.type == existingTask.type) {
                    existingTask.currentDuration = task.currentDuration;
                    existingTask.remainingDuration = task.remainingDuration;
                    existingTask.currentCount = task.currentCount;
                    existingTask.targetCount = task.targetCount;
                    existingTask.isTimerActive = task.isTimerActive;
                  }

                  // IMPORTANT: Sync status changes from remote
                  // Only preserve date/time, but sync status changes
                  existingTask.status = task.status;

                  // Keep local date and time if they exist and remote doesn't have them
                  if (task.taskDate != null) {
                    existingTask.taskDate = task.taskDate;
                  }
                  if (task.time != null) {
                    existingTask.time = task.time;
                  }

                  await _hiveService.updateTask(existingTask);
                  // Update UI
                  TaskProvider().updateItems();
                } else {
                  // Only add truly new tasks that don't exist locally
                  debugPrint('Adding new task from Firestore: ${task.title}');
                  await _hiveService.addTask(task);

                  // Check if task is already in provider list before adding
                  final existingInProvider = TaskProvider().taskList.any((t) => t.id == task.id);
                  if (!existingInProvider) {
                    TaskProvider().taskList.add(task);
                  }
                  TaskProvider().updateItems();
                }
                break;
              case DocumentChangeType.removed:
                await _hiveService.deleteTask(task.id);
                TaskProvider().taskList.removeWhere((t) => t.id == task.id);
                TaskProvider().updateItems();
                break;
            }
          } catch (e) {
            debugPrint('Error processing task change: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('Tasks listener error: $error');
      },
    );
  }

  /// Start task logs real-time listener
  Future<void> _startTaskLogsListener() async {
    if (!isAuthenticated) return;

    _taskLogsListener = _userDoc!.collection(_taskLogsCollection).snapshots().listen(
      (snapshot) async {
        debugPrint('Task logs snapshot received: ${snapshot.docs.length} logs');

        for (final change in snapshot.docChanges) {
          try {
            final data = change.doc.data() as Map<String, dynamic>;
            final log = _firestoreMapToTaskLog(data);

            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                await _hiveService.addTaskLog(log);

                // Check if log exists in provider
                final existingIndex = TaskLogProvider().taskLogList.indexWhere((l) => l.id == log.id);
                if (existingIndex != -1) {
                  TaskLogProvider().taskLogList[existingIndex] = log;
                } else {
                  TaskLogProvider().taskLogList.add(log);
                }
                break;
              case DocumentChangeType.removed:
                // Remove from local storage and provider
                final existingLogs = await _hiveService.getTaskLogs();
                final existingLog = existingLogs.where((l) => l.id == log.id).isNotEmpty ? existingLogs.firstWhere((l) => l.id == log.id) : null;
                if (existingLog != null) {
                  await _hiveService.deleteTaskLog(existingLog.id);
                }

                TaskLogProvider().taskLogList.removeWhere((l) => l.id == log.id);
                break;
            }
          } catch (e) {
            debugPrint('Error processing task log change: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('Task logs listener error: $error');
      },
    );
  }

  /// Start store items real-time listener
  Future<void> _startStoreItemsListener() async {
    if (!isAuthenticated) return;

    _storeItemsListener = _userDoc!.collection(_storeItemsCollection).snapshots().listen(
      (snapshot) async {
        debugPrint('Store items snapshot received: ${snapshot.docs.length} items');

        for (final change in snapshot.docChanges) {
          try {
            final data = change.doc.data() as Map<String, dynamic>;
            final item = _firestoreMapToStoreItem(data);

            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                // Check if item already exists locally
                final existingItems = await _hiveService.getItems();
                final existingItem = existingItems.where((i) => i.id == item.id).isNotEmpty ? existingItems.firstWhere((i) => i.id == item.id) : null;

                if (existingItem != null) {
                  // Update existing item properties (create new instance due to final fields)
                  final updatedItem = ItemModel(
                    id: existingItem.id,
                    title: item.title,
                    description: item.description,
                    credit: item.credit,
                    type: item.type,
                    addCount: item.addCount,
                    addDuration: item.addDuration,
                    currentCount: existingItem.isTimerActive == true ? existingItem.currentCount : item.currentCount,
                    currentDuration: existingItem.isTimerActive == true ? existingItem.currentDuration : item.currentDuration,
                    isTimerActive: existingItem.isTimerActive,
                  );

                  await _hiveService.updateItem(updatedItem);

                  // Update in provider
                  final providerIndex = StoreProvider().storeItemList.indexWhere((i) => i.id == item.id);
                  if (providerIndex != -1) {
                    StoreProvider().storeItemList[providerIndex] = updatedItem;
                  }
                } else {
                  // Add new item
                  await _hiveService.addItem(item);
                  StoreProvider().storeItemList.add(item);
                }

                StoreProvider().setStateItems();
                break;
              case DocumentChangeType.removed:
                await _hiveService.deleteItem(item.id);
                StoreProvider().storeItemList.removeWhere((i) => i.id == item.id);
                StoreProvider().setStateItems();
                break;
            }
          } catch (e) {
            debugPrint('Error processing store item change: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('Store items listener error: $error');
      },
    );
  }

  /// Start categories real-time listener
  Future<void> _startCategoriesListener() async {
    if (!isAuthenticated) return;

    _categoriesListener = _userDoc!.collection(_categoriesCollection).snapshots().listen(
      (snapshot) async {
        debugPrint('Categories snapshot received: ${snapshot.docs.length} categories');

        for (final change in snapshot.docChanges) {
          try {
            final data = change.doc.data() as Map<String, dynamic>;
            final category = _firestoreMapToCategory(data);

            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                await _hiveService.addCategory(category);
                // Reload categories in task provider
                TaskProvider().loadCategories();
                break;
              case DocumentChangeType.removed:
                await _hiveService.deleteCategory(category.id);
                TaskProvider().loadCategories();
                break;
            }
          } catch (e) {
            debugPrint('Error processing category change: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('Categories listener error: $error');
      },
    );
  }

  /// Start traits real-time listener
  Future<void> _startTraitsListener() async {
    if (!isAuthenticated) return;

    _traitsListener = _userDoc!.collection(_traitsCollection).snapshots().listen(
      (snapshot) async {
        debugPrint('Traits snapshot received: ${snapshot.docs.length} traits');

        for (final change in snapshot.docChanges) {
          try {
            final data = change.doc.data() as Map<String, dynamic>;
            final trait = _firestoreMapToTrait(data);

            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                await _hiveService.addTrait(trait);
                // You may want to update TraitProvider here if it exists
                break;
              case DocumentChangeType.removed:
                await _hiveService.deleteTrait(trait.id);
                // You may want to update TraitProvider here if it exists
                break;
            }
          } catch (e) {
            debugPrint('Error processing trait change: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('Traits listener error: $error');
      },
    );
  }

  /// Start routines real-time listener
  Future<void> _startRoutinesListener() async {
    if (!isAuthenticated) return;

    _routinesListener = _userDoc!.collection(_routinesCollection).snapshots().listen(
      (snapshot) async {
        debugPrint('Routines snapshot received: ${snapshot.docs.length} routines');

        for (final change in snapshot.docChanges) {
          try {
            final data = change.doc.data() as Map<String, dynamic>;
            final routine = _firestoreMapToRoutine(data);

            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                await _hiveService.addRoutine(routine);

                // Check if routine exists in provider
                final existingIndex = TaskProvider().routineList.indexWhere((r) => r.id == routine.id);
                if (existingIndex != -1) {
                  TaskProvider().routineList[existingIndex] = routine;
                } else {
                  TaskProvider().routineList.add(routine);
                }

                TaskProvider().updateItems();
                break;
              case DocumentChangeType.removed:
                await _hiveService.deleteRoutine(routine.id);
                TaskProvider().routineList.removeWhere((r) => r.id == routine.id);
                TaskProvider().updateItems();
                break;
            }
          } catch (e) {
            debugPrint('Error processing routine change: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('Routines listener error: $error');
      },
    );
  }
}
