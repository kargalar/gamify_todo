import 'package:flutter/material.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Model/user_model.dart';
import 'package:next_level/Page/Login/modern_login_page.dart';
import 'package:next_level/Page/navbar_page_manager.dart';
import 'package:next_level/Service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('AuthWrapper: build() called');
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        debugPrint('AuthWrapper: StreamBuilder state = ${snapshot.connectionState}, hasData = ${snapshot.hasData}, data = ${snapshot.data?.email}');

        // Show loading while checking authentication
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('AuthWrapper: Showing loading...');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is authenticated
        final user = snapshot.data;
        debugPrint('AuthWrapper: Current loginUser = ${loginUser?.username}');

        if (user != null) {
          debugPrint('AuthWrapper: Firebase user found: ${user.email}');

          // Check if we have both Firebase user and local user
          if (loginUser != null) {
            debugPrint('AuthWrapper: Both Firebase and local user exist, showing NavbarPageManager');
            return const NavbarPageManager();
          } else {
            debugPrint('AuthWrapper: Firebase user exists but loginUser is null, trying to load from local storage');
            // Firebase user exists, check if we have local user data
            return FutureBuilder<UserModel?>(
              future: _ensureLocalUser(user),
              builder: (context, localSnapshot) {
                debugPrint('AuthWrapper: FutureBuilder state = ${localSnapshot.connectionState}, hasData = ${localSnapshot.hasData}, loginUser = ${loginUser?.username}');

                if (localSnapshot.connectionState == ConnectionState.waiting) {
                  debugPrint('AuthWrapper: Loading local user...');
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (localSnapshot.hasData && localSnapshot.data != null && loginUser != null) {
                  debugPrint('AuthWrapper: Local user loaded successfully, showing NavbarPageManager');
                  return const NavbarPageManager();
                } else {
                  debugPrint('AuthWrapper: Failed to load local user, showing LoginPage');
                  return const ModernLoginPage();
                }
              },
            );
          }
        } else {
          debugPrint('AuthWrapper: No Firebase user, showing LoginPage');
          return const ModernLoginPage();
        }
      },
    );
  }

  Future<UserModel?> _ensureLocalUser(User firebaseUser) async {
    debugPrint('_ensureLocalUser: Called with Firebase user: ${firebaseUser.email}');
    debugPrint('_ensureLocalUser: Current loginUser: ${loginUser?.username}');

    // If loginUser is already set, return it
    if (loginUser != null) {
      debugPrint('_ensureLocalUser: loginUser already exists, returning it');
      return loginUser;
    }

    // Try to get user from local storage
    debugPrint('_ensureLocalUser: Calling checkAuthState...');
    final AuthService authService = AuthService();
    await authService.checkAuthState();

    debugPrint('_ensureLocalUser: After checkAuthState, loginUser = ${loginUser?.username}');

    // If still no loginUser found, sign out from Firebase to force re-login
    if (loginUser == null) {
      debugPrint('_ensureLocalUser: No local user found, signing out from Firebase');
      await authService.signOut();
    }

    return loginUser;
  }
}
