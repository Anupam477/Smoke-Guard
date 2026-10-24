import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sp;

import '../../core/errors/failures.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/user_model.dart';
import '../../features/settings/demo_mode_provider.dart';

abstract class IAuthRepository {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
  Future<UserModel> signInWithEmailPassword(String email, String password);
  Future<UserModel> signUpWithEmailPassword(String email, String password);
  Future<UserModel> signInWithGoogle();
  Future<void> sendPhoneOtp(String phone);
  Future<UserModel> verifyPhoneOtp(String phone, String token);
  Future<void> sendPasswordResetEmail(String email);
  Future<UserModel> signInAsDemoUser();
  Future<void> signOut();
}

/// Real implementation using Supabase Auth
class SupabaseAuthRepository implements IAuthRepository {
  final sp.SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Stream<UserModel?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        phone: user.phone,
        displayName: user.userMetadata?['full_name'] as String?,
        isDemoUser: false,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
    });
  }

  @override
  UserModel? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      phone: user.phone,
      displayName: user.userMetadata?['full_name'] as String?,
      isDemoUser: false,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  @override
  Future<UserModel> signInWithEmailPassword(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) throw const AuthFailure('Login failed: user data missing.');
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        phone: user.phone,
        displayName: user.userMetadata?['full_name'] as String?,
        isDemoUser: false,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
    } on sp.AuthException catch (e) {
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<UserModel> signUpWithEmailPassword(String email, String password) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) throw const AuthFailure('Signup failed: user data missing.');
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        phone: user.phone,
        displayName: user.userMetadata?['full_name'] as String?,
        isDemoUser: false,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
    } on sp.AuthException catch (e) {
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(sp.OAuthProvider.google);
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const AuthFailure('Google sign-in incomplete or canceled.');
      }
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        phone: user.phone,
        displayName: user.userMetadata?['full_name'] as String?,
        isDemoUser: false,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
    } on sp.AuthException catch (e) {
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
    } on sp.AuthException catch (e) {
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<UserModel> verifyPhoneOtp(String phone, String token) async {
    try {
      final res = await _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: sp.OtpType.sms,
      );
      final user = res.user;
      if (user == null) throw const AuthFailure('OTP verification failed.');
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        phone: user.phone,
        displayName: user.userMetadata?['full_name'] as String?,
        isDemoUser: false,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
    } on sp.AuthException catch (e) {
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on sp.AuthException catch (e) {
      throw AuthFailure(e.message, code: e.statusCode);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<UserModel> signInAsDemoUser() async {
    return UserModel.demo();
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('[SupabaseAuthRepository] Sign out warning: $e');
    }
  }
}

/// Deterministic Mock implementation for Demo Mode and offline environments
class MockAuthRepository implements IAuthRepository {
  UserModel? _mockUser;
  final ValueNotifier<UserModel?> _notifier = ValueNotifier<UserModel?>(null);

  @override
  Stream<UserModel?> get authStateChanges async* {
    yield _mockUser;
  }

  @override
  UserModel? get currentUser => _mockUser;

  @override
  Future<UserModel> signInWithEmailPassword(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _mockUser = UserModel(
      id: 'mock-user-1',
      email: email,
      displayName: email.split('@').first,
      isDemoUser: true,
      createdAt: DateTime.now(),
    );
    _notifier.value = _mockUser;
    return _mockUser!;
  }

  @override
  Future<UserModel> signUpWithEmailPassword(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _mockUser = UserModel(
      id: 'mock-user-1',
      email: email,
      displayName: email.split('@').first,
      isDemoUser: true,
      createdAt: DateTime.now(),
    );
    _notifier.value = _mockUser;
    return _mockUser!;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockUser = UserModel(
      id: 'mock-google-user',
      email: 'alex.google@example.com',
      displayName: 'Alex Rivers',
      isDemoUser: true,
      createdAt: DateTime.now(),
    );
    _notifier.value = _mockUser;
    return _mockUser!;
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<UserModel> verifyPhoneOtp(String phone, String token) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockUser = UserModel(
      id: 'mock-phone-user',
      email: '',
      phone: phone,
      displayName: 'Mobile User',
      isDemoUser: true,
      createdAt: DateTime.now(),
    );
    _notifier.value = _mockUser;
    return _mockUser!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<UserModel> signInAsDemoUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockUser = UserModel.demo();
    _notifier.value = _mockUser;
    return _mockUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockUser = null;
    _notifier.value = null;
  }
}

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final isDemoMode = ref.watch(demoModeProvider);

  if (isDemoMode || !SupabaseService.isInitialized) {
    return MockAuthRepository();
  } else {
    return SupabaseAuthRepository(SupabaseService.client);
  }
});
