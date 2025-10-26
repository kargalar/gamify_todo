import 'package:next_level/General/accessible.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Service/logging_service.dart';

class AppHelper {
  void addCreditByProgress(Duration? progress) async {
    if (progress == null) {
      LogService.error('⚠️ AppHelper: progress is null');
      return;
    }

    if (loginUser == null) {
      LogService.error('⚠️ AppHelper: loginUser is null');
      return;
    }

    // Hiç ilerleme yoksa loglama yapma (performans için)
    if (progress == Duration.zero) {
      return;
    }

    int oldCredit = loginUser!.userCredit;

    loginUser!.creditProgress += progress;

    // Handle positive progress
    while (loginUser!.creditProgress.inHours >= 1) {
      loginUser!.userCredit += 1;
      loginUser!.creditProgress -= const Duration(hours: 1);
    }

    // Handle negative progress
    while (loginUser!.creditProgress.inHours <= -1) {
      loginUser!.userCredit -= 1;
      loginUser!.creditProgress += const Duration(hours: 1);
    }

    // Credit değişti mi kontrol et - sadece o zaman loglaysa
    bool creditChanged = oldCredit != loginUser!.userCredit;
    if (creditChanged) {
      LogService.debug('💰 AppHelper: Adding progress: ${progress.inMinutes} minutes');
      LogService.debug('💰 Credit changed: $oldCredit -> ${loginUser!.userCredit}');
    }

    await ServerManager().updateUser(userModel: loginUser!);

    // Sync with UserProvider to update UI
    UserProvider().setUser(loginUser!);
  }
}
