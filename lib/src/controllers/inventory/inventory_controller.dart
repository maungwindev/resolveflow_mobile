import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/imports/packages_imports.dart';
import 'package:resolveflow/src/models/inventory_part.dart';

class InventoryController extends GetxController {
  InventoryController({required InventoryRepository repository})
      : _repository = repository;

  final InventoryRepository _repository;

  final Rx<RequestState<List<InventoryPart>>> partsState =
      Rx<RequestState<List<InventoryPart>>>(const RequestInitial());

  final Rx<String> searchQuery = ''.obs;
  final Rx<RequestState<void>> mutationState =
      Rx<RequestState<void>>(const RequestInitial());

  List<InventoryPart> get allParts => switch (partsState.value) {
        RequestSuccess(:final data) => data,
        _ => const [],
      };

  bool get isLoading => partsState.value.isLoading;
  bool get isMutating => mutationState.value.isLoading;

  /// Parts filtered by search text (matching SKU or part name)
  List<InventoryPart> get filteredParts {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return allParts;
    return allParts.where((p) {
      return p.sku.toLowerCase().contains(query) ||
          p.name.toLowerCase().contains(query) ||
          p.location.toLowerCase().contains(query);
    }).toList();
  }

  /// Total count of parts currently low or out of stock
  int get lowStockCount =>
      allParts.where((p) => p.isLowStock || p.isOutOfStock).length;

  @override
  void onInit() {
    super.onInit();
    fetchParts();
  }

  Future<void> fetchParts({bool showLoading = true}) async {
    if (showLoading) {
      partsState.value = const RequestLoading();
    }

    final result = await _repository.getParts();

    result.fold(
      (failure) => partsState.value = RequestFailure(failure),
      (data) => partsState.value = RequestSuccess(data),
    );
  }

  Future<InventoryPart?> getPartBySku(String sku) async {
    // Check in-memory list first
    final cleanSku = sku.trim().toUpperCase();
    final local = allParts.where((p) => p.sku.toUpperCase() == cleanSku).firstOrNull;
    if (local != null) return local;

    // Fetch from backend
    final result = await _repository.getPartBySku(cleanSku);
    return result.fold((_) => null, (part) => part);
  }

  /// Restock action (Manager capability)
  Future<bool> restockPart({
    required BuildContext context,
    required String sku,
    required int amount,
  }) async {
    mutationState.value = const RequestLoading();

    final result = await _repository.restockPart(sku, amount);

    return result.fold(
      (failure) {
        mutationState.value = RequestFailure(failure);
        if (context.mounted) {
          showToast(context, message: failure.message, status: 'error');
        }
        return false;
      },
      (updatedPart) {
        mutationState.value = const RequestSuccess(null);
        if (context.mounted) {
          showToast(
            context,
            message: 'Restocked ${updatedPart.sku}: +$amount units',
            status: 'success',
          );
        }
        // Refresh local list
        fetchParts(showLoading: false);
        return true;
      },
    );
  }

  /// Add new part action (Manager capability)
  Future<bool> addPart({
    required BuildContext context,
    required InventoryPart part,
  }) async {
    mutationState.value = const RequestLoading();

    final result = await _repository.addPart(part);

    return result.fold(
      (failure) {
        mutationState.value = RequestFailure(failure);
        if (context.mounted) {
          showToast(context, message: failure.message, status: 'error');
        }
        return false;
      },
      (createdPart) {
        mutationState.value = const RequestSuccess(null);
        if (context.mounted) {
          showToast(
            context,
            message: 'Part ${createdPart.sku} added to inventory!',
            status: 'success',
          );
        }
        fetchParts(showLoading: false);
        return true;
      },
    );
  }
}

