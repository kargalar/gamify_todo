import 'dart:async';

/// Service for optimizing Firebase write operations with throttling and batching
class FirebaseOptimizer {
  static final FirebaseOptimizer _instance = FirebaseOptimizer._internal();

  FirebaseOptimizer._internal();

  factory FirebaseOptimizer() => _instance;

  // Pending operations queues
  final Map<String, List<Function>> _pendingOperations = {};
  final Map<String, Timer?> _timers = {};

  // Throttling settings
  static const Duration _throttleDelay = Duration(seconds: 2); // Wait 2 seconds before executing
  static const int _maxBatchSize = 50; // Max operations per batch

  /// Add an operation to the throttled queue
  void addThrottledOperation(String operationType, Function operation) {
    // Initialize queue if not exists
    _pendingOperations[operationType] ??= [];

    // Add operation to queue
    _pendingOperations[operationType]!.add(operation);

    // Cancel existing timer
    _timers[operationType]?.cancel();

    // Start new timer
    _timers[operationType] = Timer(_throttleDelay, () {
      _executePendingOperations(operationType);
    });

    // If queue is too full, execute immediately
    if (_pendingOperations[operationType]!.length >= _maxBatchSize) {
      _timers[operationType]?.cancel();
      _executePendingOperations(operationType);
    }
  }

  /// Execute all pending operations for a type
  Future<void> _executePendingOperations(String operationType) async {
    final operations = _pendingOperations[operationType];
    if (operations == null || operations.isEmpty) return;

    // Clear the queue
    _pendingOperations[operationType] = [];
    _timers[operationType] = null;

    // Execute all operations
    for (final operation in operations) {
      try {
        await operation();
      } catch (e) {
        print('Error executing throttled operation: $e');
      }
    }
  }

  /// Force execute all pending operations immediately
  Future<void> flushAll() async {
    for (final operationType in _pendingOperations.keys.toList()) {
      _timers[operationType]?.cancel();
      await _executePendingOperations(operationType);
    }
  }

  /// Get pending operations count for debugging
  Map<String, int> getPendingCounts() {
    return _pendingOperations.map((key, value) => MapEntry(key, value.length));
  }
}
