import 'package:appwrite/appwrite.dart';
import '../config/app_config.dart';
import '../utils/utils.dart';

class AppwriteDatabaseService {
  AppwriteDatabaseService._();
  static final instance = AppwriteDatabaseService._();

  Databases get _databases => Databases(AppConfig.appwriteClient);

  FutureEither<Object?> listDocuments(
    String collectionId, {
    List<String>? queries,
  }) {
    return runTask(
      () {
        _requireDatabaseId();
        // Appwrite 22 returns a generated model that is not stable across SDK
        // releases; keep this public service boundary SDK-version independent.
        // ignore: deprecated_member_use
        return _databases.listDocuments(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: collectionId,
          queries: queries,
        );
      },
      operation: 'appwrite.listDocuments',
      category: LogCategory.database,
      context: {'collectionId': collectionId, 'queries': queries?.toString()},
      requiresNetwork: true,
    );
  }

  FutureEither<Object?> createDocument(
    String collectionId,
    Map<String, dynamic> data, {
    String? documentId,
    List<String>? permissions,
  }) {
    return runTask(
      () {
        _requireDatabaseId();
        // ignore: deprecated_member_use
        return _databases.createDocument(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: collectionId,
          documentId: documentId ?? ID.unique(),
          data: data,
          permissions: permissions,
        );
      },
      operation: 'appwrite.createDocument',
      category: LogCategory.database,
      context: {'collectionId': collectionId},
      requiresNetwork: true,
    );
  }

  FutureEither<Object?> getDocument({
    required String collectionId,
    required String documentId,
  }) {
    return runTask(
      () {
        _requireDatabaseId();
        // ignore: deprecated_member_use
        return _databases.getDocument(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: collectionId,
          documentId: documentId,
        );
      },
      operation: 'appwrite.getDocument',
      category: LogCategory.database,
      context: {'collectionId': collectionId, 'documentId': documentId},
      requiresNetwork: true,
    );
  }

  FutureEither<Object?> updateDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return runTask(
      () {
        _requireDatabaseId();
        // ignore: deprecated_member_use
        return _databases.updateDocument(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: collectionId,
          documentId: documentId,
          data: data,
        );
      },
      operation: 'appwrite.updateDocument',
      category: LogCategory.database,
      context: {'collectionId': collectionId, 'documentId': documentId},
      requiresNetwork: true,
    );
  }

  FutureEither<void> deleteDocument({
    required String collectionId,
    required String documentId,
  }) {
    return runTask(
      () async {
        _requireDatabaseId();
        // ignore: deprecated_member_use
        await _databases.deleteDocument(
          databaseId: AppConfig.appwriteDatabaseId,
          collectionId: collectionId,
          documentId: documentId,
        );
      },
      operation: 'appwrite.deleteDocument',
      category: LogCategory.database,
      context: {'collectionId': collectionId, 'documentId': documentId},
      requiresNetwork: true,
    );
  }

  void _requireDatabaseId() {
    if (AppConfig.appwriteDatabaseId.isEmpty) {
      throw StateError(
        'APPWRITE_DATABASE_ID is required for database operations.',
      );
    }
  }
}
