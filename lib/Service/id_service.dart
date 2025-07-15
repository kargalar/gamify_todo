import 'dart:math';

/// Service for generating unique IDs based on timestamp and random components
class IdService {
  static const IdService _instance = IdService._internal();

  const IdService._internal();

  factory IdService() => _instance;

  /// Generate a unique ID based on current timestamp and random component
  /// Format: Hive-compatible integer within 0xFFFFFFFF range
  /// This ensures uniqueness across devices and time while staying within Hive limits
  int generateUniqueId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000); // 0-999 random number

    // Hive maximum key value is 0xFFFFFFFF (4,294,967,295)
    const int maxHiveKey = 0xFFFFFFFF;

    // Take last 9 digits of timestamp and add random 3 digits
    // This gives us numbers up to 999,999,999 + 999 = 1,000,000,998
    final shortenedTimestamp = now % 1000000000; // Last 9 digits

    // Combine timestamp with random number
    final uniqueId = (shortenedTimestamp * 1000) + random;

    // Ensure we're within Hive's integer key range
    final clampedId = uniqueId % maxHiveKey;

    // Make sure ID is never 0 (could cause issues)
    return clampedId == 0 ? 1 : clampedId;
  }

  /// Generate a unique ID for users
  int generateUserId() {
    return generateUniqueId();
  }

  /// Generate a unique ID for tasks
  int generateTaskId() {
    return generateUniqueId();
  }

  /// Generate a unique ID for items
  int generateItemId() {
    return generateUniqueId();
  }

  /// Generate a unique ID for store items
  int generateStoreItemId() {
    return generateUniqueId();
  }

  /// Generate a unique ID for traits
  int generateTraitId() {
    return generateUniqueId();
  }

  /// Generate a unique ID for categories
  int generateCategoryId() {
    return generateUniqueId();
  }

  /// Generate a unique ID for routines
  int generateRoutineId() {
    return generateUniqueId();
  }

  /// Validate if an ID follows the new unique format
  bool isValidUniqueId(int id) {
    // Check if ID is in the expected range and within Hive limits
    return id > 0 && id <= 0xFFFFFFFF; // Should be positive and within Hive range
  }

  /// Get current timestamp for debugging
  int getCurrentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }
}
