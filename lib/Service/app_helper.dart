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

    LogService.debug('💰 AppHelper: Adding progress: ${progress.inMinutes} minutes');
    LogService.debug('💰 Before: credit=${loginUser!.userCredit}, progress=${loginUser!.creditProgress.inMinutes} minutes');

    loginUser!.creditProgress += progress;

    // Handle positive progress
    while (loginUser!.creditProgress.inHours >= 1) {
      loginUser!.userCredit += 1;
      loginUser!.creditProgress -= const Duration(hours: 1);
      LogService.debug('💰 Credit increased! New credit: ${loginUser!.userCredit}');
    }

    // Handle negative progress
    while (loginUser!.creditProgress.inHours <= -1) {
      loginUser!.userCredit -= 1;
      loginUser!.creditProgress += const Duration(hours: 1);
      LogService.debug('💰 Credit decreased! New credit: ${loginUser!.userCredit}');
    }

    LogService.debug('💰 After: credit=${loginUser!.userCredit}, progress=${loginUser!.creditProgress.inMinutes} minutes');

    await ServerManager().updateUser(userModel: loginUser!);

    // Sync with UserProvider to update UI
    UserProvider().setUser(loginUser!);
  }
}
