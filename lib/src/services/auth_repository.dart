import 'package:resolveflow/src/utils/utils.dart';
import 'package:resolveflow/src/models/user_model.dart';

abstract class AuthRepository {
  /// Stream of auth state changes. Emits AppUser when authenticated, null when not.
  Stream<AppUser?> get onAuthStateChanged;

  /// Sign In with email and password
  FutureEither<AppUser> login({
    required String email,
    required String password,
  });

  /// Sign up with email, password, and optional name
  FutureEither<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Send a password reset email
  FutureEither<void> forgotPassword({
    required String email,
  });

  /// Sign out the current user
  FutureEither<void> logout();

  /// Permanently delete the user account
  FutureEither<void> deleteAccount(String userId);

  /// Check if the user is currently authenticated natively
  FutureEither<AppUser?> checkAuthState();
}

