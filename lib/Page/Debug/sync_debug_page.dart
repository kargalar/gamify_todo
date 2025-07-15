import 'package:flutter/material.dart';
import 'package:next_level/Service/firebase_service.dart';
import 'package:next_level/Service/sync_manager.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SyncDebugPage extends StatefulWidget {
  const SyncDebugPage({super.key});

  @override
  State<SyncDebugPage> createState() => _SyncDebugPageState();
}

class _SyncDebugPageState extends State<SyncDebugPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final SyncManager _syncManager = SyncManager();
  final ServerManager _serverManager = ServerManager();
  final HiveService _hiveService = HiveService();

  bool _isLoading = false;
  String _status = 'Ready';
  final List<String> _logs = [];

  void _addLog(String log) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $log');
    });
    debugPrint(log);
  }

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firebase connection...';
      _logs.clear();
    });

    try {
      _addLog('🔄 Testing Firebase connection...');

      // Check current user
      final uid = _firebaseService.currentUserUid;
      if (uid == null) {
        _addLog('❌ No authenticated user found');
        setState(() {
          _status = 'No authenticated user';
          _isLoading = false;
        });
        return;
      }

      _addLog('✅ User authenticated: $uid');

      // Test Firestore connection
      _addLog('🔄 Testing Firestore connection...');
      await _firebaseService.isOnline();
      _addLog('✅ Firestore connection successful');

      // Get sync stats
      final stats = _syncManager.getSyncStats();
      _addLog('📊 Sync stats: $stats');

      setState(() {
        _status = 'Firebase connection successful';
        _isLoading = false;
      });
    } catch (e) {
      _addLog('❌ Firebase connection failed: $e');
      setState(() {
        _status = 'Firebase connection failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _testAddTask() async {
    setState(() {
      _isLoading = true;
      _status = 'Adding test task...';
    });

    try {
      _addLog('🔄 Creating test task...');

      final testTask = TaskModel(
        id: 0, // Will be set by ServerManager
        title: 'Test Task ${DateTime.now().millisecondsSinceEpoch}',
        description: 'This is a test task for Firebase sync',
        type: TaskTypeEnum.CHECKBOX,
        taskDate: DateTime.now(),
        isNotificationOn: false,
        isAlarmOn: false,
        priority: 2,
        status: null, // No status initially
        routineID: null,
        time: null,
        currentDuration: null,
        remainingDuration: null,
        currentCount: null,
        targetCount: null,
        isTimerActive: null,
        attributeIDList: null,
        skillIDList: null,
        subtasks: null,
        categoryId: null,
      );

      final taskId = await _serverManager.addTask(taskModel: testTask);
      _addLog('✅ Test task created with ID: $taskId');

      setState(() {
        _status = 'Test task created successfully';
        _isLoading = false;
      });
    } catch (e) {
      _addLog('❌ Failed to create test task: $e');
      setState(() {
        _status = 'Failed to create test task';
        _isLoading = false;
      });
    }
  }

  Future<void> _testAddItem() async {
    setState(() {
      _isLoading = true;
      _status = 'Adding test item...';
    });

    try {
      _addLog('🔄 Creating test item...');

      final testItem = ItemModel(
        id: 0, // Will be set by ServerManager
        title: 'Test Item ${DateTime.now().millisecondsSinceEpoch}',
        description: 'This is a test item for Firebase sync',
        type: TaskTypeEnum.CHECKBOX,
        credit: 10,
        currentDuration: null,
        addDuration: null,
        currentCount: null,
        addCount: null,
        isTimerActive: null,
      );

      final itemId = await _serverManager.addItem(itemModel: testItem);
      _addLog('✅ Test item created with ID: $itemId');

      setState(() {
        _status = 'Test item created successfully';
        _isLoading = false;
      });
    } catch (e) {
      _addLog('❌ Failed to create test item: $e');
      setState(() {
        _status = 'Failed to create test item';
        _isLoading = false;
      });
    }
  }

  Future<void> _testSync() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing sync...';
    });

    try {
      _addLog('🔄 Testing sync...');

      // Force sync
      await _syncManager.forceSyncNow();
      _addLog('✅ Sync completed successfully');

      setState(() {
        _status = 'Sync completed successfully';
        _isLoading = false;
      });
    } catch (e) {
      _addLog('❌ Sync failed: $e');
      setState(() {
        _status = 'Sync failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _testFirebaseRules() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firebase security rules...';
    });

    try {
      _addLog('🔄 Testing Firebase security rules...');

      final uid = _firebaseService.currentUserUid;
      if (uid == null) {
        _addLog('❌ No authenticated user found');
        setState(() {
          _status = 'No authenticated user';
          _isLoading = false;
        });
        return;
      }

      _addLog('✅ User authenticated: $uid');

      // Test read permission
      try {
        _addLog('🔄 Testing read permission...');
        final tasks = await _hiveService.getTasks();
        _addLog('✅ Local tasks count: ${tasks.length}');

        // Try to read from Firebase directly
        final firestore = FirebaseFirestore.instance;
        final snapshot = await firestore.collection('users').doc(uid).collection('tasks').limit(1).get();
        _addLog('✅ Read permission: OK (${snapshot.docs.length} docs in Firebase)');
      } catch (e) {
        _addLog('❌ Read permission failed: $e');
      }

      // Test write permission
      try {
        _addLog('🔄 Testing write permission...');
        final testTask = TaskModel(
          id: DateTime.now().millisecondsSinceEpoch,
          title: 'Test Task for Rules',
          type: TaskTypeEnum.CHECKBOX,
          isNotificationOn: false,
          isAlarmOn: false,
          priority: 2,
          categoryId: null,
        );

        await _firebaseService.addTaskToFirebase(testTask);
        _addLog('✅ Write permission: OK');

        // Clean up test task
        await _firebaseService.deleteTaskFromFirebase(testTask.id);
        _addLog('✅ Delete permission: OK');
      } catch (e) {
        _addLog('❌ Write permission failed: $e');
      }

      setState(() {
        _status = 'Firebase rules test completed';
        _isLoading = false;
      });
    } catch (e) {
      _addLog('❌ Firebase rules test failed: $e');
      setState(() {
        _status = 'Firebase rules test failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _showFirebaseRulesHelp() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firebase Security Rules Help'),
        content: const SingleChildScrollView(
          child: Text('''
Firebase Firestore'da aşağıdaki security rules'ı kullanın:

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read/write their own documents
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}

Bu kurallar:
1. Kullanıcıların sadece kendi verilerine erişim sağlar
2. Kimlik doğrulaması gerektirir
3. Güvenli veri erişimi sağlar

Firebase Console'da:
1. Firestore Database'e gidin
2. Rules sekmesine tıklayın
3. Yukarıdaki kuralları yapıştırın
4. Publish butonuna basın
'''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearLocalData() async {
    setState(() {
      _isLoading = true;
      _status = 'Clearing local data...';
    });

    try {
      _addLog('🔄 Clearing all local data...');

      // Clear all local data using the existing method
      await _hiveService.deleteAllData(isLogout: false);

      _addLog('✅ All local data cleared');

      setState(() {
        _status = 'Local data cleared successfully';
        _isLoading = false;
      });
    } catch (e) {
      _addLog('❌ Failed to clear local data: $e');
      setState(() {
        _status = 'Failed to clear local data';
        _isLoading = false;
      });
    }
  }

  Future<void> _fullSyncFromFirebase() async {
    setState(() {
      _isLoading = true;
      _status = 'Full sync from Firebase...';
    });

    try {
      _addLog('🔄 Starting full sync from Firebase...');

      // Force sync from Firebase
      await _firebaseService.syncFromFirebase();
      _addLog('✅ Full sync from Firebase completed');

      setState(() {
        _status = 'Full sync completed successfully';
        _isLoading = false;
      });
    } catch (e) {
      _addLog('❌ Full sync failed: $e');
      setState(() {
        _status = 'Full sync failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkLocalDataCount() async {
    try {
      _addLog('🔄 Checking local data count...');

      final tasks = await _hiveService.getTasks();
      final items = await _hiveService.getItems();
      final traits = await _hiveService.getTraits();
      final routines = await _hiveService.getRoutines();
      final categories = await _hiveService.getCategories();
      final taskLogs = await _hiveService.getTaskLogs();

      _addLog('📊 Local data count:');
      _addLog('   Tasks: ${tasks.length}');
      _addLog('   Items: ${items.length}');
      _addLog('   Traits: ${traits.length}');
      _addLog('   Routines: ${routines.length}');
      _addLog('   Categories: ${categories.length}');
      _addLog('   Task Logs: ${taskLogs.length}');

      setState(() {
        _status = 'Local data count checked';
      });
    } catch (e) {
      _addLog('❌ Failed to check local data count: $e');
      setState(() {
        _status = 'Failed to check local data count';
      });
    }
  }

  Future<void> _checkDeletedItems() async {
    try {
      _addLog('🔄 Checking deleted items...');

      final deletedItems = await _firebaseService.getDeletedItems();

      _addLog('📊 Deleted items count: ${deletedItems.length}');

      for (final deletedItem in deletedItems) {
        _addLog('   - $deletedItem');
      }

      setState(() {
        _status = 'Deleted items checked';
      });
    } catch (e) {
      _addLog('❌ Failed to check deleted items: $e');
      setState(() {
        _status = 'Failed to check deleted items';
      });
    }
  }

  Future<void> _clearDeletedItems() async {
    setState(() {
      _isLoading = true;
      _status = 'Clearing deleted items...';
    });

    try {
      _addLog('🔄 Clearing deleted items...');

      final uid = _firebaseService.currentUserUid;
      if (uid == null) {
        _addLog('❌ No authenticated user found');
        setState(() {
          _status = 'No authenticated user';
          _isLoading = false;
        });
        return;
      }

      // Get all deleted items
      final deletedSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).collection('deleted_items').get();

      // Delete all deleted items records
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in deletedSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _addLog('✅ Deleted items cleared (${deletedSnapshot.docs.length} records)');

      setState(() {
        _status = 'Deleted items cleared successfully';
        _isLoading = false;
      });
    } catch (e) {
      _addLog('❌ Failed to clear deleted items: $e');
      setState(() {
        _status = 'Failed to clear deleted items';
        _isLoading = false;
      });
    }
  }

  Future<void> _startRealTimeSync() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting real-time sync...';
    });

    try {
      _addLog('🔄 Starting real-time sync...');

      await _serverManager.startRealTimeSync();
      _addLog('✅ Real-time sync started');

      setState(() {
        _status = 'Real-time sync started successfully';
        _isLoading = false;
      });
    } catch (e) {
      _addLog('❌ Failed to start real-time sync: $e');
      setState(() {
        _status = 'Failed to start real-time sync';
        _isLoading = false;
      });
    }
  }

  Future<void> _stopRealTimeSync() async {
    setState(() {
      _isLoading = true;
      _status = 'Stopping real-time sync...';
    });

    try {
      _addLog('🔄 Stopping real-time sync...');

      await _serverManager.stopRealTimeSync();
      _addLog('✅ Real-time sync stopped');

      setState(() {
        _status = 'Real-time sync stopped successfully';
        _isLoading = false;
      });
    } catch (e) {
      _addLog('❌ Failed to stop real-time sync: $e');
      setState(() {
        _status = 'Failed to stop real-time sync';
        _isLoading = false;
      });
    }
  }

  Future<void> _testRealTimeSync() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing real-time sync...';
      _logs.clear();
    });

    try {
      _addLog('🔄 Testing real-time sync...');

      // Check if real-time sync is active
      final isActive = _serverManager.isRealTimeSyncActive;
      _addLog('Real-time sync active: $isActive');

      if (!isActive) {
        _addLog('⚠️ Real-time sync is not active, starting...');
        await _serverManager.startRealTimeSync();
        _addLog('✅ Real-time sync started');
      }

      // Create a test task
      final testTask = TaskModel(
        id: DateTime.now().millisecondsSinceEpoch,
        title: 'Test Task ${DateTime.now().millisecondsSinceEpoch}',
        description: 'This is a test task for real-time sync',
        type: TaskTypeEnum.CHECKBOX,
        isNotificationOn: false,
        isAlarmOn: false,
        categoryId: 1,
      );

      _addLog('🔄 Creating test task...');
      await _serverManager.addTask(taskModel: testTask);
      _addLog('✅ Test task created with ID: ${testTask.id}');

      // Wait a bit for sync
      await Future.delayed(const Duration(seconds: 2));

      // Update the task
      testTask.title = 'Updated Test Task ${DateTime.now().millisecondsSinceEpoch}';
      _addLog('🔄 Updating test task...');
      await _serverManager.updateTask(taskModel: testTask);
      _addLog('✅ Test task updated');

      // Wait a bit for sync
      await Future.delayed(const Duration(seconds: 2));

      // Delete the task
      _addLog('🔄 Deleting test task...');
      await _serverManager.deleteTask(id: testTask.id);
      _addLog('✅ Test task deleted');

      _addLog('✅ Real-time sync test completed');
    } catch (e) {
      _addLog('❌ Real-time sync test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _status = 'Ready';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Sync Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $_status',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'User: ${loginUser?.email ?? 'Not authenticated'}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Firebase UID: ${_firebaseService.currentUserUid ?? 'None'}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                if (_isLoading) const LinearProgressIndicator(),
              ],
            ),
          ),

          // Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testFirebaseConnection,
                  child: const Text('Test Firebase Connection'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testAddTask,
                  child: const Text('Add Test Task'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testAddItem,
                  child: const Text('Add Test Item'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testSync,
                  child: const Text('Force Sync'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testFirebaseRules,
                  child: const Text('Test Firebase Rules'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                  child: const Text('Clear Logs'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _showFirebaseRulesHelp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Firebase Rules Help'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _clearLocalData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear Local Data'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _fullSyncFromFirebase,
                  child: const Text('Full Sync from Firebase'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkLocalDataCount,
                  child: const Text('Check Local Data Count'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkDeletedItems,
                  child: const Text('Check Deleted Items'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _clearDeletedItems,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear Deleted Items'),
                ),
                // Real-time sync controls
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _startRealTimeSync,
                        child: const Text('Start Real-time Sync'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _stopRealTimeSync,
                        child: const Text('Stop Real-time Sync'),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testRealTimeSync,
                  child: const Text('Test Real-Time Sync'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Logs:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            log,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
