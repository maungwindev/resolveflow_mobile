import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/imports/packages_imports.dart';

import 'package:resolveflow/src/models/user_model.dart';
import 'package:resolveflow/src/services/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService = AuthService.instance;

  AppUser _toUser(Map<String, dynamic> userData, {String? fallbackEmail, String? fallbackName}) {
    final user = AppUser.fromJson(
      userData['user'] is Map<String, dynamic>
          ? userData['user'] as Map<String, dynamic>
          : userData,
    );
    if (fallbackEmail == null && fallbackName == null) return user;
    return AppUser(
      id: user.id,
      email: user.email.isEmpty ? (fallbackEmail ?? '') : user.email,
      name: user.name ?? fallbackName,
      photoUrl: user.photoUrl,
      teams: user.teams,
    );
  }

  @override
  Stream<AppUser?> get onAuthStateChanged {
    return _authService.authStateChanges.map((userData) {
      if (userData == null) return null;
      return _toUser(userData);
    });
  }

  @override
  FutureEither<AppUser> login({
    required String email,
    required String password,
  }) async {
    final result = await _authService.login(email: email, password: password);

    return result.flatMap((userData) {
      if (userData == null) {
        return left(const ServerFailure('Login failed: User record not found'));
      }
      return right(_toUser(userData, fallbackEmail: email));
    });
  }

  @override
  FutureEither<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _authService.signUp(
      name: name,
      email: email,
      password: password,
    );

    return result.flatMap((userData) {
      if (userData == null) {
        return left(
            const ServerFailure('Sign up failed: User record corrupted'));
      }
      return right(_toUser(userData, fallbackEmail: email, fallbackName: name));
    });
  }

  @override
  FutureEither<void> forgotPassword({required String email}) {
    return _authService.forgotPassword(email: email);
  }

  @override
  FutureEither<void> logout() {
    return _authService.logout();
  }

  @override
  FutureEither<void> deleteAccount(String userId) {
    return _authService.deleteAccount(userId);
  }

  @override
  FutureEither<AppUser?> checkAuthState() async {
    final result = await _authService.getCurrentUser();

    return result.map((userData) {
      if (userData == null) return null;
      return _toUser(userData);
    });
  }
}
