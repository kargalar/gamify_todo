import 'package:flutter/material.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Service/server_manager.dart';

class AppHelper {
  void addCreditByProgress(Duration? progress) async {
    if (progress == null) {
      debugPrint('⚠️ AppHelper: progress is null');
      return;
    }

    if (loginUser == null) {
      debugPrint('⚠️ AppHelper: loginUser is null');
      return;
    }

    debugPrint('💰 AppHelper: Adding progress: ${progress.inMinutes} minutes');
    debugPrint('💰 Before: credit=${loginUser!.userCredit}, progress=${loginUser!.creditProgress.inMinutes} minutes');

    loginUser!.creditProgress += progress;

    // Handle positive progress
    while (loginUser!.creditProgress.inHours >= 1) {
      loginUser!.userCredit += 1;
      loginUser!.creditProgress -= const Duration(hours: 1);
      debugPrint('💰 Credit increased! New credit: ${loginUser!.userCredit}');
    }

    // Handle negative progress
    while (loginUser!.creditProgress.inHours <= -1) {
      loginUser!.userCredit -= 1;
      loginUser!.creditProgress += const Duration(hours: 1);
      debugPrint('💰 Credit decreased! New credit: ${loginUser!.userCredit}');
    }

    debugPrint('💰 After: credit=${loginUser!.userCredit}, progress=${loginUser!.creditProgress.inMinutes} minutes');

    await ServerManager().updateUser(userModel: loginUser!);

    // Sync with UserProvider to update UI
    UserProvider().setUser(loginUser!);
  }
}
