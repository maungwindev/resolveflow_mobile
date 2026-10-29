import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:fpdart/fpdart.dart';
import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/models/resolution_result.dart';
import 'package:resolveflow/src/services/appwrite_database_service.dart';

abstract class DiagnosticRepository {
  /// Queries Knowledge Base (`resolutions_vector`) using semantic query matching.
  FutureEither<List<ResolutionResult>> searchResolutions(String query);

  /// Submits newly solved symptom knowledge to Knowledge Base.
  FutureEither<ResolutionResult> addNewResolutionKnowledge({
    required String title,
    required String symptom,
    required String observation,
    required String fixProcedure,
    required String requiredSku,
  });
}

class DiagnosticRepositoryImpl implements DiagnosticRepository {
  DiagnosticRepositoryImpl({AppwriteDatabaseService? databaseService})
      : _databaseService = databaseService ?? AppwriteDatabaseService.instance;

  final AppwriteDatabaseService _databaseService;

  @override
  FutureEither<List<ResolutionResult>> searchResolutions(String query) async {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return right(<ResolutionResult>[]);
    }

    // Try Appwrite search query first
    List<String> queries = [
      Query.limit(25),
      Query.orderDesc('\$createdAt'),
    ];

    try {
      queries.add(Query.search('symptom', trimmedQuery));
    } catch (_) {}

    var result = await _databaseService.listDocuments(
      AppwriteConstants.collectionResolutionsVector,
      queries: queries,
    );

    // If search query fails (e.g., search index still generating in Appwrite), fallback to list all
    if (result.isLeft()) {
      result = await _databaseService.listDocuments(
        AppwriteConstants.collectionResolutionsVector,
        queries: [
          Query.limit(50),
          Query.orderDesc('\$createdAt'),
        ],
      );
    }

    return result.map((response) {
      final documents = _extractDocuments(response);
      final queryWords = trimmedQuery.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();

      final results = documents.map((doc) {
        final data = doc.data;
        data['\$id'] = doc.$id;
        final item = ResolutionResult.fromJson(data);

        // Calculate semantic word-overlap similarity score
        double score = item.similarity;
        if (queryWords.isNotEmpty) {
          final targetContent = '${item.title} ${item.symptom} ${item.observation}'.toLowerCase();
          int matchedWords = 0;
          for (final word in queryWords) {
            if (targetContent.contains(word)) {
              matchedWords++;
            }
          }
          final matchRatio = matchedWords / queryWords.length;
          score = (matchRatio * 0.5) + (item.similarity * 0.5);
          if (score > 1.0) score = 1.0;
        }

        return item.copyWith(similarity: double.parse(score.toStringAsFixed(2)));
      }).toList();

      // Sort by highest similarity first
      results.sort((a, b) => b.similarity.compareTo(a.similarity));
      return results;
    });
  }

  @override
  FutureEither<ResolutionResult> addNewResolutionKnowledge({
    required String title,
    required String symptom,
    required String observation,
    required String fixProcedure,
    required String requiredSku,
  }) async {
    final payload = {
      'title': title.trim(),
      'symptom': symptom.trim(),
      'observation': observation.trim(),
      'fix_procedure': fixProcedure.trim(),
      'required_sku': requiredSku.trim().toUpperCase(),
      'similarity_score': 1.0,
    };

    final result = await _databaseService.createDocument(
      AppwriteConstants.collectionResolutionsVector,
      payload,
    );

    return result.map((response) {
      if (response is models.Document) {
        final data = response.data;
        data['\$id'] = response.$id;
        return ResolutionResult.fromJson(data);
      }
      return ResolutionResult.fromJson(payload);
    });
  }

  List<models.Document> _extractDocuments(Object? response) {
    if (response is models.DocumentList) {
      return response.documents;
    }
    return <models.Document>[];
  }
}

