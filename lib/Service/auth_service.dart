import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Model/user_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Service/id_service.dart';
import 'package:next_level/Core/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final HiveService _hiveService = HiveService();
  final ServerManager _serverManager = ServerManager();

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Stream for authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email, password and username
  Future<UserModel?> registerWithEmailPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      debugPrint('Starting registration process...');
      debugPrint('Email: $email, Username: $username');

      // Create user with Firebase Auth
      debugPrint('Creating user with Firebase Auth...');
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
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

        // Generate unique ID for local storage using timestamp-based ID
        debugPrint('Generating unique user ID...');
        final int userId = IdService().generateUserId();
        debugPrint('Unique user ID generated: $userId');

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

        // Sync data to Firebase after successful registration
        debugPrint('Starting Firebase sync after registration...');
        try {
          await _serverManager.syncToFirebase();
          debugPrint('Firebase sync completed successfully');
        } catch (e) {
          debugPrint('Firebase sync failed: $e');
          // Don't fail registration if sync fails
        }

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
    debugPrint('Registration process completed with null result');
    return null;
  }

  // Login with email and password
  Future<UserModel?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Starting sign in process...');
      debugPrint('Email: $email');

      // Sign in with Firebase Auth
      debugPrint('Signing in with Firebase Auth...');
      final UserCredential result = await _auth.signInWithEmailAndPassword(
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

        // Sync data from Firebase after successful login
        debugPrint('Starting Firebase sync after login...');
        try {
          await _serverManager.syncFromFirebase();
          debugPrint('Firebase sync completed successfully');
        } catch (e) {
          debugPrint('Firebase sync failed: $e');
          // Don't fail login if sync fails
        }

        // Start real-time sync
        debugPrint('Starting real-time sync...');
        try {
          await _serverManager.startRealTimeSync();
          debugPrint('Real-time sync started successfully');
        } catch (e) {
          debugPrint('Real-time sync failed to start: $e');
          // Don't fail login if real-time sync fails
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
    debugPrint('Sign in process completed with null result');
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Stop real-time sync before signing out
      debugPrint('Stopping real-time sync before logout...');
      try {
        await _serverManager.stopRealTimeSync();
        debugPrint('Real-time sync stopped successfully');
      } catch (e) {
        debugPrint('Real-time sync stop failed: $e');
        // Don't fail logout if real-time sync stop fails
      }

      // Sync data to Firebase before signing out
      debugPrint('Starting Firebase sync before logout...');
      try {
        await _serverManager.syncToFirebase();
        debugPrint('Firebase sync completed successfully');
      } catch (e) {
        debugPrint('Firebase sync failed: $e');
        // Don't fail logout if sync fails
      }

      await _auth.signOut();
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
    try {
      await _auth.sendPasswordResetEmail(email: email);
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
    final User? user = currentUser;
    if (user != null) {
      // User is signed in, get local user data
      UserModel? localUser = await _getUserFromLocalStorage(user.email!);
      if (localUser != null) {
        loginUser = localUser;
        debugPrint('User authenticated: ${localUser.email}');

        // Note: Firebase sync is handled by login method, not here
        debugPrint('Local user loaded successfully from storage');
      } else {
        // If no local user found, sign out from Firebase
        debugPrint('No local user found for Firebase user ${user.email}, signing out');
        await signOut();
      }
    } else {
      loginUser = null;
    }
  }
}
