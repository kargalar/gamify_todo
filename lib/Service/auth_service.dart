import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Model/user_model.dart';
import 'package:next_level/Provider/offline_mode_provider.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/sync_manager.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? _auth;
  final HiveService _hiveService = HiveService();
  final OfflineModeProvider _offlineModeProvider = OfflineModeProvider();

  // Get Firebase Auth instance (lazy initialization)
  FirebaseAuth? get auth {
    if (_offlineModeProvider.shouldDisableFirebase()) {
      return null;
    }
    _auth ??= FirebaseAuth.instance;
    return _auth;
  }

  // Get current Firebase user
  // Get current Firebase user
  User? get currentUser {
    if (_offlineModeProvider.shouldDisableFirebase()) {
      return null;
    }
    return auth?.currentUser;
  }

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Stream for authentication state changes
  Stream<User?> get authStateChanges {
    if (_offlineModeProvider.shouldDisableFirebase()) {
      // In offline mode, return a stream that emits current user state once
      return Stream.value(loginUser != null ? auth?.currentUser : null);
    }
    return auth?.authStateChanges() ?? Stream.value(null);
  }

  // Register with email, password and username
  Future<UserModel?> registerWithEmailPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    if (_offlineModeProvider.shouldDisableFirebase()) {
      Helper().getMessage(
        message: "Offline modda kayıt işlemi yapılamaz. Lütfen çevrimiçi moda geçin.",
        status: StatusEnum.WARNING,
      );
      return null;
    }

    try {
      debugPrint('Starting registration process...');
      debugPrint('Email: $email, Username: $username');

      // Create user with Firebase Auth
      debugPrint('Creating user with Firebase Auth...');
      final UserCredential result = await auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Firebase user created successfully');

      final User? user = result.user;
      if (user != null) {
        debugPrint('Firebase user is not null, updating display name...');
        // Update display name in Firebase
        await user.updateDisplayName(username);
        debugPrint('Display name updated successfully');

        // Generate unique ID for local storage
        debugPrint('Generating local user ID...');
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        int userId = prefs.getInt('last_user_id') ?? 0;
        userId++;
        await prefs.setInt('last_user_id', userId);
        debugPrint('Local user ID generated: $userId');

        // Create UserModel for local storage
        debugPrint('Creating UserModel for local storage...');
        final UserModel userModel = UserModel(
          id: userId,
          email: email,
          password: '', // Don't store password locally for security
          username: username,
          creditProgress: const Duration(hours: 0, minutes: 0, seconds: 0),
          userCredit: 0,
        );
        debugPrint('UserModel created successfully');

        // Save to Hive
        debugPrint('Saving user to Hive...');
        await _hiveService.addUser(userModel);
        debugPrint('User saved to Hive successfully');

        // Set as logged in user
        loginUser = userModel;
        debugPrint('loginUser set successfully');

        debugPrint('User registered successfully: ${userModel.email}');
        return userModel;
      } else {
        debugPrint('ERROR: Firebase user is null after registration');
      }
    } catch (e, stackTrace) {
      debugPrint('Registration error: $e');
      debugPrint('Stack trace: $stackTrace');
      Helper().getMessage(
        message: _getErrorMessage(e.toString()),
      );
    }
    debugPrint('Registration process done with null result');
    return null;
  }

  // Login with email and password
  Future<UserModel?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (_offlineModeProvider.shouldDisableFirebase()) {
      Helper().getMessage(
        message: "Offline modda giriş işlemi yapılamaz. Lütfen çevrimiçi moda geçin.",
        status: StatusEnum.WARNING,
      );
      return null;
    }

    try {
      debugPrint('Starting sign in process...');
      debugPrint('Email: $email');

      // Sign in with Firebase Auth
      debugPrint('Signing in with Firebase Auth...');
      final UserCredential result = await auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Firebase sign in successful');

      final User? user = result.user;
      if (user != null) {
        debugPrint('Firebase user is not null, getting local user...');
        // Try to get user from local storage first
        UserModel? localUser = await _getUserFromLocalStorage(email);
        debugPrint('Local user found: ${localUser != null}');

        if (localUser == null) {
          debugPrint('Creating new local user record...');
          // If not found locally, create new user record
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          int userId = prefs.getInt('last_user_id') ?? 0;
          userId++;
          await prefs.setInt('last_user_id', userId);

          localUser = UserModel(
            id: userId,
            email: email,
            password: '', // Don't store password locally
            username: user.displayName ?? email.split('@')[0], // Use display name or part of email
            creditProgress: const Duration(hours: 0, minutes: 0, seconds: 0),
            userCredit: 0,
          );

          await _hiveService.addUser(localUser);
          debugPrint('New local user created: ${localUser.username}');
        } else {
          debugPrint('Using existing local user: ${localUser.username}');
        }

        // Set as logged in user
        loginUser = localUser;
        debugPrint('loginUser set successfully: ${loginUser?.username}');

        // Start real-time listeners after successful login (only if offline mode is disabled)
        if (!_offlineModeProvider.shouldDisableFirebase()) {
          try {
            await SyncManager().initialize();
            debugPrint('SyncManager re-initialized after login');
          } catch (e) {
            debugPrint('Error re-initializing SyncManager: $e');
          }
        } else {
          debugPrint('Offline mode enabled, skipping SyncManager initialization');
        }

        debugPrint('User signed in successfully: ${localUser.email}');
        return localUser;
      } else {
        debugPrint('ERROR: Firebase user is null after sign in');
      }
    } catch (e, stackTrace) {
      debugPrint('Sign in error: $e');
      debugPrint('Stack trace: $stackTrace');
      Helper().getMessage(
        message: _getErrorMessage(e.toString()),
      );
    }
    debugPrint('Sign in process done with null result');
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Stop real-time listeners before sign out
      SyncManager().stopRealtimeListeners();

      // Only sign out from Firebase if offline mode is disabled
      if (!_offlineModeProvider.shouldDisableFirebase()) {
        await auth?.signOut();
        debugPrint('Firebase sign out completed');
      } else {
        debugPrint('Offline mode enabled, skipping Firebase sign out');
      }

      loginUser = null;
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Sign out error: $e');
      Helper().getMessage(
        message: "Çıkış yapılırken hata oluştu",
      );
    }
  }

  // Get user from local storage by email
  Future<UserModel?> _getUserFromLocalStorage(String email) async {
    try {
      final users = await _hiveService.getUsers();
      return users.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw StateError('User not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    if (_offlineModeProvider.shouldDisableFirebase()) {
      Helper().getMessage(
        message: "Offline modda şifre sıfırlama yapılamaz. Lütfen çevrimiçi moda geçin.",
        status: StatusEnum.WARNING,
      );
      return false;
    }

    try {
      await auth?.sendPasswordResetEmail(email: email);
      Helper().getMessage(
        message: "Şifre sıfırlama e-postası gönderildi",
      );
      return true;
    } catch (e) {
      debugPrint('Password reset error: $e');
      Helper().getMessage(
        message: _getErrorMessage(e.toString()),
      );
      return false;
    }
  }

  // Get localized error message
  String _getErrorMessage(String error) {
    if (error.contains('weak-password')) {
      return "Şifre çok zayıf";
    } else if (error.contains('email-already-in-use')) {
      return "Bu e-posta adresi zaten kullanımda";
    } else if (error.contains('user-not-found')) {
      return "Kullanıcı bulunamadı";
    } else if (error.contains('wrong-password')) {
      return "Yanlış şifre";
    } else if (error.contains('invalid-email')) {
      return "Geçersiz e-posta adresi";
    } else if (error.contains('user-disabled')) {
      return "Kullanıcı hesabı devre dışı bırakıldı";
    } else if (error.contains('network-request-failed')) {
      return "Ağ bağlantısı hatası";
    } else if (error.contains('operation-not-allowed')) {
      return "Bu işlem izin verilmiyor. Firebase Console'dan Email/Password authentication'ı etkinleştirin";
    } else if (error.contains('too-many-requests')) {
      return "Çok fazla deneme yapıldı. Lütfen biraz bekleyip tekrar deneyin";
    } else {
      return "Kimlik doğrulama hatası: $error";
    }
  }

  // Check authentication state and initialize user
  Future<void> checkAuthState() async {
    debugPrint('checkAuthState: Starting, offline mode: ${_offlineModeProvider.shouldDisableFirebase()}');

    if (_offlineModeProvider.shouldDisableFirebase()) {
      // In offline mode, try to load any local user without Firebase authentication
      debugPrint('checkAuthState: Offline mode - trying to load any local user');
      try {
        final users = await _hiveService.getUsers();
        if (users.isNotEmpty) {
          // Use the first available user (or could be the last used user)
          final prefs = await SharedPreferences.getInstance();
          final lastUserEmail = prefs.getString('last_user_email');

          if (lastUserEmail != null) {
            // Try to find the last used user
            final lastUser = users.where((u) => u.email == lastUserEmail).isNotEmpty ? users.firstWhere((u) => u.email == lastUserEmail) : users.first;
            loginUser = lastUser;
            debugPrint('checkAuthState: Offline mode - loaded last user: ${lastUser.email}');
          } else {
            // Just use the first available user
            loginUser = users.first;
            debugPrint('checkAuthState: Offline mode - loaded first available user: ${users.first.email}');
          }
        } else {
          debugPrint('checkAuthState: Offline mode - no local users found');
          loginUser = null;
        }
      } catch (e) {
        debugPrint('checkAuthState: Error loading offline user: $e');
        loginUser = null;
      }
    } else {
      // Online mode with Firebase authentication
      final User? user = currentUser;
      if (user != null) {
        // User is signed in, get local user data
        UserModel? localUser = await _getUserFromLocalStorage(user.email!);
        if (localUser != null) {
          loginUser = localUser;
          debugPrint('checkAuthState: Online mode - user authenticated: ${localUser.email}');

          // Save as last used user
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_user_email', localUser.email);
        } else {
          // If no local user found, sign out from Firebase
          debugPrint('checkAuthState: Online mode - no local user found, signing out');
          await signOut();
        }
      } else {
        debugPrint('checkAuthState: Online mode - no Firebase user');
        loginUser = null;
      }
    }
  }
}
