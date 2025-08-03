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

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final HiveService _hiveService = HiveService();

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

  // Check if user is authenticated
  bool get isAuthenticated => _currentUserId != null;

  // Get user's document reference
  DocumentReference? get _userDoc => _currentUserId != null ? _firestore.collection(_usersCollection).doc(_currentUserId) : null;

  // Enable offline persistence
  Future<void> enableOfflinePersistence() async {
    try {
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
          // Mevcut task varsa, sadece belirli alanları güncelle
          // Tarih, durum ve zaman bilgilerini KORUYARAK güncelle
          existingTask.title = task.title;
          existingTask.description = task.description;
          existingTask.priority = task.priority;
          existingTask.categoryId = task.categoryId;
          existingTask.subtasks = task.subtasks;
          existingTask.location = task.location;
          existingTask.attachmentPaths = task.attachmentPaths;
          existingTask.attributeIDList = task.attributeIDList;
          existingTask.skillIDList = task.skillIDList;

          // Sadece current değerleri güncelle (duration, count vs.)
          if (task.type == existingTask.type) {
            existingTask.currentDuration = task.currentDuration;
            existingTask.remainingDuration = task.remainingDuration;
            existingTask.currentCount = task.currentCount;
            existingTask.targetCount = task.targetCount;
            existingTask.isTimerActive = task.isTimerActive;
          }

          // Tarih, status ve time bilgilerini KORUR
          // existingTask.taskDate = KORUNUR
          // existingTask.time = KORUNUR
          // existingTask.status = KORUNUR

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
        debugPrint('Full upload completed successfully');
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
        debugPrint('Full download completed successfully');
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
}
