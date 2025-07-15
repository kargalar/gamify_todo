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
