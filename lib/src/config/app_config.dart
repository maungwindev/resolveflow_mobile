import 'package:shared_preferences/shared_preferences.dart';
import '../middleware/dio_logging_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:appwrite/appwrite.dart';
import 'app_secrets.dart';

class AppConfig {
  AppConfig._();
  static late final Dio dio;
  static late Client appwriteClient;
  static late Account appwriteAccount;
  static late Teams appwriteTeams;

  static const String appwriteEndpoint = AppSecrets.endpoint;
  static const String appwriteProjectId = AppSecrets.projectId;
  static const String appwriteDatabaseId = AppSecrets.databaseId;
  static const String appwriteBucketId = AppSecrets.bucketId;
  static const String baseUrl = AppSecrets.baseUrl;

  static Future<void> init() async {
    appwriteClient = Client()
      ..setEndpoint(appwriteEndpoint)
      ..setProject(appwriteProjectId)
      ..setSelfSigned(status: true);
    appwriteAccount = Account(appwriteClient);
    appwriteTeams = Teams(appwriteClient);
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(DioLoggingInterceptor());
  }

  /// Clears stored session cookies from SharedPreferences and reinitializes the Appwrite client
  static Future<void> resetAppwriteClient() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = prefs.getKeys().where((k) {
        final lower = k.toLowerCase();
        return lower.contains('cookie') || lower.contains('session') || lower.contains('appwrite');
      }).toList();
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
    } catch (_) {}

    appwriteClient = Client()
      ..setEndpoint(appwriteEndpoint)
      ..setProject(appwriteProjectId)
      ..setSelfSigned(status: true);
    appwriteAccount = Account(appwriteClient);
    appwriteTeams = Teams(appwriteClient);
  }
}
