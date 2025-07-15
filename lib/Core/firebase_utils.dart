import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseUtils {
  /// Helper function to parse Firebase Timestamp or String to DateTime
  static DateTime? parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  /// Helper function to parse Duration from String format "HH:MM:SS"
  static Duration? parseDuration(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        List<String> split = value.split(':');
        if (split.length == 3) {
          return Duration(
            hours: int.parse(split[0]),
            minutes: int.parse(split[1]),
            seconds: int.parse(split[2]),
          );
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Helper function to convert Duration to String format "HH:MM:SS"
  static String durationToString(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
