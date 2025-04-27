import 'package:gamify_todo/Model/store_item_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Service/notification_services.dart';

class NotificationHelper {
  // Görev için bildirim durumunu kontrol et ve güncelle
  static void checkAndUpdateNotificationStatusForTask(TaskModel task) {
    final remainingDuration = task.remainingDuration!;
    final currentDuration = task.currentDuration!;
    final isTimerActive = task.isTimerActive ?? false;

    if (currentDuration < remainingDuration && isTimerActive) {
      // Zamanlanmış bildirimi yeniden hesapla
      final int secondsUntilCompletion = remainingDuration.inSeconds - currentDuration.inSeconds;
      NotificationService().scheduleNotification(
        id: task.id,
        title: '🎉 ${task.title} Tamamlandı',
        desc: 'Toplam süre: ${task.remainingDuration!}',
        scheduledDate: DateTime.now().add(Duration(seconds: secondsUntilCompletion)),
        isAlarm: task.isAlarmOn,
      );
    } else if (isTimerActive && currentDuration >= remainingDuration) {
      // Halihazırdaki zamanlanmış bildirimi iptal et
      NotificationService().cancelNotificationOrAlarm(task.id);
    }
  }

  // Mağaza öğesi için bildirim durumunu kontrol et ve güncelle
  static void checkAndUpdateNotificationStatusForStoreItem(ItemModel item) {
    final currentDuration = item.currentDuration!;
    final isTimerActive = item.isTimerActive ?? false;

    if (currentDuration.inSeconds > 0 && isTimerActive) {
      // Zamanlanmış bildirimi yeniden hesapla
      final int secondsUntilCompletion = currentDuration.inSeconds;
      NotificationService().scheduleNotification(
        id: item.id,
        title: '⚠️ ${item.title} Süre Doldu',
        desc: 'Sınırı Aşma!',
        scheduledDate: DateTime.now().add(Duration(seconds: secondsUntilCompletion)),
        isAlarm: true,
      );
    } else if (isTimerActive && currentDuration.inSeconds <= 0) {
      // Halihazırdaki zamanlanmış bildirimi iptal et
      NotificationService().cancelNotificationOrAlarm(item.id);
    }
  }
}
