import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/imports/packages_imports.dart';
import 'package:resolveflow/src/models/resolution_result.dart';

class DiagnosticController extends GetxController {
  DiagnosticController({required DiagnosticRepository repository})
      : _repository = repository;

  final DiagnosticRepository _repository;

  final Rx<RequestState<List<ResolutionResult>>> searchState =
      Rx<RequestState<List<ResolutionResult>>>(const RequestInitial());

  final Rx<String> currentQuery = ''.obs;
  final Rx<bool> showKnowledgeForm = false.obs;
  final Rx<RequestState<ResolutionResult?>> submitState =
      Rx<RequestState<ResolutionResult?>>(const RequestInitial());

  List<ResolutionResult> get results => switch (searchState.value) {
        RequestSuccess(:final data) => data,
        _ => const [],
      };

  bool get isLoading => searchState.value.isLoading;
  bool get isSubmitting => submitState.value.isLoading;

  /// High-confidence matches (similarity >= 0.60)
  List<ResolutionResult> get highConfidenceMatches =>
      results.where((r) => r.isHighConfidence).toList();

  /// Low-confidence matches (similarity < 0.60)
  List<ResolutionResult> get lowConfidenceMatches =>
      results.where((r) => !r.isHighConfidence).toList();

  Future<void> search(String query) async {
    final trimmed = query.trim();
    currentQuery.value = trimmed;

    if (trimmed.isEmpty) {
      searchState.value = const RequestInitial();
      showKnowledgeForm.value = false;
      return;
    }

    searchState.value = const RequestLoading();

    final result = await _repository.searchResolutions(trimmed);

    result.fold(
      (failure) {
        searchState.value = RequestFailure(failure);
        showKnowledgeForm.value = true;
      },
      (data) {
        searchState.value = RequestSuccess(data);
        // Show knowledge ingestion form if no results or top result confidence < 60%
        final topSimilarity = data.isNotEmpty ? data.first.similarity : 0.0;
        showKnowledgeForm.value = data.isEmpty || topSimilarity < 0.60;
      },
    );
  }

  void toggleKnowledgeForm([bool? value]) {
    showKnowledgeForm.value = value ?? !showKnowledgeForm.value;
  }

  Future<bool> submitKnowledge({
    required BuildContext context,
    required String title,
    required String symptom,
    required String observation,
    required String fixProcedure,
    required String requiredSku,
  }) async {
    submitState.value = const RequestLoading();

    final result = await _repository.addNewResolutionKnowledge(
      title: title,
      symptom: symptom,
      observation: observation,
      fixProcedure: fixProcedure,
      requiredSku: requiredSku,
    );

    return result.fold(
      (failure) {
        submitState.value = RequestFailure(failure);
        if (context.mounted) {
          showToast(context, message: failure.message, status: 'error');
        }
        return false;
      },
      (newResolution) {
        submitState.value = RequestSuccess(newResolution);
        if (context.mounted) {
          showToast(
            context,
            message: 'Resolution added to Knowledge Base!',
            status: 'success',
          );
        }
        showKnowledgeForm.value = false;
        // Refresh search so the new procedure is visible immediately
        search(currentQuery.value.isNotEmpty ? currentQuery.value : symptom);
        return true;
      },
    );
  }

  void clearSearch() {
    currentQuery.value = '';
    searchState.value = const RequestInitial();
    showKnowledgeForm.value = false;
  }
}

