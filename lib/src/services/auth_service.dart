import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_secrets.dart';
import '../utils/utils.dart';
import '../config/app_config.dart';
import 'package:appwrite/appwrite.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Account get _account => AppConfig.appwriteAccount;

  // Appwrite doesn't have a built-in auth state stream, so we manage our own
  final StreamController<Map<String, dynamic>?> _authStateController =
      StreamController<Map<String, dynamic>?>.broadcast();

  /// Stream of auth state changes. Emits the current user map or null.
  Stream<Map<String, dynamic>?> get authStateChanges {
    return logAuthStateChanges(
      _authStateController.stream,
      userIdOf: (user) => user['id'] as String? ?? '',
    );
  }

  Future<List<String>> _getUserTeams() async {
    try {
      final teamsList = await AppConfig.appwriteTeams.list();
      return teamsList.teams.map((t) => t.$id).toList();
    } catch (_) {
      return [];
    }
  }

  FutureEither<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    return runTask(() async {
      // Ensure no residual or blocked session cookie is attached to the client
      try {
        await _account.deleteSession(sessionId: 'current');
      } catch (_) {
        await AppConfig.resetAppwriteClient();
      }

      try {
        await _account.createEmailPasswordSession(
          email: email, 
          password: password,
        );
      } on AppwriteException catch (e) {
        // If a blocked session caused an early rejection, force a complete client reset and retry once
        if (e.type == 'user_blocked' || e.code == 403 || e.message?.contains('blocked') == true) {
          await AppConfig.resetAppwriteClient();
          await _account.createEmailPasswordSession(
            email: email, 
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final user = await _account.get();
      final teams = await _getUserTeams();
      final userData = {
        'id': user.$id,
        'email': user.email,
        'name': user.name,
        'teams': teams,
      };
      _authStateController.add(userData);
      return userData;
    },
      operation: 'auth.login',
      category: LogCategory.auth,
      context: {'method': 'email'},
      requiresNetwork: true,
    );
  }

  FutureEither<Map<String, dynamic>?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return runTask(() async {
      final user = await _account.create(
        userId: ID.unique(),
        email: email, 
        password: password,
        name: name,
      );
      // login after signup to get session
      await _account.createEmailPasswordSession(
        email: email, 
        password: password
      );
      final teams = await _getUserTeams();
      final userData = {
        'id': user.$id,
        'email': user.email,
        'name': user.name,
        'teams': teams,
      };
      _authStateController.add(userData);
      return userData;
    },
      operation: 'auth.signUp',
      category: LogCategory.auth,
      context: {'method': 'email'},
      requiresNetwork: true,
    );
  }

  FutureEither<void> forgotPassword({required String email}) async {
    return runTask(() async {
      // url for password recovery in your app
      await _account.createRecovery(
        email: email, 
        url: 'https://example.com/recovery'
      );
    },
      operation: 'auth.forgotPassword',
      category: LogCategory.auth,
      requiresNetwork: true,
    );
  }

  FutureEither<void> logout() async {
    return runTask(() async {
      try {
        await _account.deleteSession(sessionId: 'current');
      } catch (e) {
        AppLogger.warning('Logout session delete error: $e');
      }
      await AppConfig.resetAppwriteClient();
      _authStateController.add(null);
    },
      operation: 'auth.logout',
      category: LogCategory.auth,
      requiresNetwork: true,
    );
  }

  FutureEither<void> deleteAccount(String userId) async {
    return runTask(() async {
      // 1. Terminate client session FIRST while account is still recognized
      try {
        await _account.deleteSession(sessionId: 'current');
      } catch (e) {
        AppLogger.warning('Client session delete warning: $e');
      }

      // 2. Terminate all server-side sessions using Admin API so no open tokens exist
      final dio = Dio(
        BaseOptions(
          baseUrl: AppSecrets.endpoint.endsWith('/')
              ? AppSecrets.endpoint.substring(0, AppSecrets.endpoint.length - 1)
              : AppSecrets.endpoint,
          headers: {
            'X-Appwrite-Project': AppSecrets.projectId,
            'X-Appwrite-Key': AppSecrets.adminApiKey,
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 15),
        ),
      );

      try {
        await dio.delete('/users/$userId/sessions');
      } catch (_) {}

      // 3. Soft-delete: Mark user account as inactive (status: false) in Appwrite via admin API
      try {
        await dio.patch(
          '/users/$userId/status',
          data: {'status': false},
        );

        try {
          await dio.put(
            '/users/$userId/labels',
            data: {'labels': ['inactive']},
          );
        } catch (_) {}
      } catch (e) {
        AppLogger.warning('Admin user deactivation API error: $e');
      }

      // 4. Clear all local cookies and reinitialize clean Appwrite client
      await AppConfig.resetAppwriteClient();
      _authStateController.add(null);
    },
      operation: 'auth.deleteAccount',
      category: LogCategory.auth,
      requiresNetwork: true,
    );
  }

  FutureEither<Map<String, dynamic>?> getCurrentUser() async {
    return runTask(() async {
      try {
        final user = await _account.get();
        final teams = await _getUserTeams();
        return {
          'id': user.$id,
          'email': user.email,
          'name': user.name,
          'teams': teams,
        };
      } catch (e) {
        return null; // session likely missing or invalid
      }
    },
      operation: 'auth.getCurrentUser',
      category: LogCategory.auth,
    );
  }

  void dispose() {
    _authStateController.close();
  }
}
