import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:next_level/Service/logging_service.dart';

/// Uygulama açılış sayacını yöneten ve belirli açılış sayısında
/// kullanıcıdan rating istemek için kullanılan servis
class AppLaunchService {
  static const String _launchCountKey = 'app_launch_count';
  static const String _lastReviewRequestCountKey = 'last_review_request_count';
  static const String _reviewCompletedKey = 'review_completed';

  // Review isteme eşik değerleri (3, 7, 15, 25, 50, 75, 100, 125, 150...)
  // 3, 7, 15, 25'ten sonra her +25'te bir
  static List<int> get _reviewRequestThresholds {
    List<int> thresholds = [3, 7, 15, 25];
    // 50'den başlayarak +25'lik artışlarla 1000'e kadar devam et
    for (int i = 50; i <= 1000; i += 25) {
      thresholds.add(i);
    }
    return thresholds;
  }

  final InAppReview _inAppReview = InAppReview.instance;

  /// Uygulama açılış sayısını artırır ve gerekirse review dialog'unu gösterir
  Future<void> incrementLaunchCountAndRequestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Kullanıcı review'u tamamladı mı kontrol et
      final reviewCompleted = prefs.getBool(_reviewCompletedKey) ?? false;

      if (reviewCompleted) {
        LogService.debug('AppLaunchService: Kullanıcı review\'u tamamladı, tekrar sorulmayacak');
        // Sadece açılış sayısını artır, review sorma
        final currentCount = prefs.getInt(_launchCountKey) ?? 0;
        await prefs.setInt(_launchCountKey, currentCount + 1);
        return;
      }

      // Mevcut açılış sayısını al
      final currentCount = prefs.getInt(_launchCountKey) ?? 0;
      final newCount = currentCount + 1;

      // Yeni sayıyı kaydet
      await prefs.setInt(_launchCountKey, newCount);

      LogService.debug('AppLaunchService: Uygulama açılış sayısı güncellendi: $newCount');

      // Son review isteği hangi sayıda yapıldı
      final lastReviewRequestCount = prefs.getInt(_lastReviewRequestCountKey) ?? 0;

      // Eşik değerlerinden birini kontrol et
      for (int threshold in _reviewRequestThresholds) {
        // Bu eşiğe ulaşıldı mı ve daha önce bu eşikte sorulmamış mı?
        if (newCount >= threshold && lastReviewRequestCount < threshold) {
          LogService.debug('AppLaunchService: $threshold. açılış eşiğine ulaşıldı, review dialog gösteriliyor');

          await _requestReview();

          // Son review isteği sayısını güncelle
          await prefs.setInt(_lastReviewRequestCountKey, threshold);

          LogService.debug('AppLaunchService: Review dialog gösterildi (Eşik: $threshold)');
          break; // Sadece bir kez sor
        }
      }
    } catch (e) {
      LogService.error('AppLaunchService: Açılış sayısı güncellenirken hata: $e');
    }
  }

  /// Review dialog'unu gösterir
  Future<void> _requestReview() async {
    try {
      // Review özelliği cihazda mevcut mu kontrol et
      if (await _inAppReview.isAvailable()) {
        LogService.debug('AppLaunchService: In-app review mevcut, dialog açılıyor...');
        await _inAppReview.requestReview();
      } else {
        LogService.debug('AppLaunchService: In-app review bu cihazda desteklenmiyor');
      }
    } catch (e) {
      LogService.error('AppLaunchService: Review isteği sırasında hata: $e');
    }
  }

  /// Açılış sayısını ve review durumunu sıfırlar (test amaçlı)
  Future<void> resetLaunchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_launchCountKey);
      await prefs.remove(_lastReviewRequestCountKey);
      await prefs.remove(_reviewCompletedKey);
      LogService.debug('AppLaunchService: Tüm review verileri sıfırlandı');
    } catch (e) {
      LogService.error('AppLaunchService: Sıfırlama hatası: $e');
    }
  }

  /// Mevcut açılış sayısını getirir
  Future<int> getLaunchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_launchCountKey) ?? 0;
    } catch (e) {
      LogService.error('AppLaunchService: Açılış sayısı alınırken hata: $e');
      return 0;
    }
  }

  /// Son review isteğinin hangi eşikte yapıldığını getirir
  Future<int> getLastReviewRequestCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_lastReviewRequestCountKey) ?? 0;
    } catch (e) {
      LogService.error('AppLaunchService: Son review isteği sayısı alınırken hata: $e');
      return 0;
    }
  }

  /// Review'un tamamlanıp tamamlanmadığını kontrol eder
  Future<bool> isReviewCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_reviewCompletedKey) ?? false;
    } catch (e) {
      LogService.error('AppLaunchService: Review tamamlanma durumu kontrol edilirken hata: $e');
      return false;
    }
  }

  /// Kullanıcının review'u tamamladığını işaretle (manuel olarak)
  /// Bu metod gelecekte kullanıcı "review yaptım" dediğinde kullanılabilir
  Future<void> markReviewAsCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reviewCompletedKey, true);
      LogService.debug('AppLaunchService: Review tamamlandı olarak işaretlendi');
    } catch (e) {
      LogService.error('AppLaunchService: Review tamamlanma durumu kaydedilirken hata: $e');
    }
  }

  /// Review eşik değerlerini getirir (bilgilendirme amaçlı)
  List<int> getReviewThresholds() {
    return _reviewRequestThresholds;
  }
}
