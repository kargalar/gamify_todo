import 'package:next_level/General/accessible.dart';
import 'package:next_level/Service/server_manager.dart';

class AppHelper {
  void addCreditByProgress(Duration? progress) async {
    if (progress == null || loginUser == null) return;

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

    await ServerManager().updateUser(userModel: loginUser!);
  }
}
