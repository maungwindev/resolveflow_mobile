import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:fpdart/fpdart.dart';
import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/models/inventory_part.dart';
import 'package:resolveflow/src/services/appwrite_database_service.dart';

abstract class InventoryRepository {
  /// Fetches all inventory parts.
  FutureEither<List<InventoryPart>> getParts();

  /// Fetches a single part by its SKU.
  FutureEither<InventoryPart?> getPartBySku(String sku);

  /// Validates stock and decrements count by [amount] (default: 1).
  FutureEither<InventoryPart> decrementStock(String sku, {int amount = 1});

  /// Restocks a part by adding [amount] (Manager permission).
  FutureEither<InventoryPart> restockPart(String sku, int amount);

  /// Creates a new inventory item (Manager permission).
  FutureEither<InventoryPart> addPart(InventoryPart part);

  /// Updates an existing part's metadata or threshold (Manager permission).
  FutureEither<InventoryPart> updatePart(InventoryPart part);
}

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl({AppwriteDatabaseService? databaseService})
      : _databaseService = databaseService ?? AppwriteDatabaseService.instance;

  final AppwriteDatabaseService _databaseService;

  @override
  FutureEither<List<InventoryPart>> getParts() async {
    final result = await _databaseService.listDocuments(
      AppwriteConstants.collectionPartsInventory,
      queries: [
        Query.limit(100),
      ],
    );

    return result.map((response) {
      if (response is models.DocumentList) {
        final list = response.documents.map((doc) {
          final data = doc.data;
          data['\$id'] = doc.$id;
          return InventoryPart.fromJson(data);
        }).toList();
        list.sort((a, b) => a.sku.compareTo(b.sku));
        return list;
      }
      return <InventoryPart>[];
    });
  }

  @override
  FutureEither<InventoryPart?> getPartBySku(String sku) async {
    final cleanSku = sku.trim().toUpperCase();
    final partsResult = await getParts();

    return partsResult.map((parts) {
      return parts.where((p) => p.sku.trim().toUpperCase() == cleanSku).firstOrNull;
    });
  }

  @override
  FutureEither<InventoryPart> decrementStock(String sku, {int amount = 1}) async {
    final partResult = await getPartBySku(sku);

    if (partResult.isLeft()) {
      return left(partResult.getLeft().toNullable()!);
    }

    final part = partResult.getOrElse((_) => null);
    if (part == null) {
      return left(ServerFailure('Part with SKU "$sku" not found in inventory.'));
    }

    if (part.quantityOnHand < amount) {
      return left(ServerFailure(
        'Insufficient stock for SKU "${part.sku}". Available: ${part.quantityOnHand}, required: $amount.',
      ));
    }

    final newQuantity = part.quantityOnHand - amount;
    final updateResult = await _databaseService.updateDocument(
      collectionId: AppwriteConstants.collectionPartsInventory,
      documentId: part.id,
      data: {
        'quantity_on_hand': newQuantity,
      },
    );

    return updateResult.map((_) {
      return part.copyWith(quantityOnHand: newQuantity);
    });
  }

  @override
  FutureEither<InventoryPart> restockPart(String sku, int amount) async {
    final partResult = await getPartBySku(sku);

    if (partResult.isLeft()) {
      return left(partResult.getLeft().toNullable()!);
    }

    final part = partResult.getOrElse((_) => null);
    if (part == null) {
      return left(ServerFailure('Part with SKU "$sku" not found.'));
    }

    final newQuantity = part.quantityOnHand + amount;
    final updateResult = await _databaseService.updateDocument(
      collectionId: AppwriteConstants.collectionPartsInventory,
      documentId: part.id,
      data: {
        'quantity_on_hand': newQuantity,
      },
    );

    return updateResult.map((_) {
      return part.copyWith(quantityOnHand: newQuantity);
    });
  }

  @override
  FutureEither<InventoryPart> addPart(InventoryPart part) async {
    final cleanSku = part.sku.trim().toUpperCase();
    final payload = part.copyWith(sku: cleanSku).toJson();

    final result = await _databaseService.createDocument(
      AppwriteConstants.collectionPartsInventory,
      payload,
    );

    return result.map((response) {
      if (response is models.Document) {
        final data = response.data;
        data['\$id'] = response.$id;
        return InventoryPart.fromJson(data);
      }
      return part;
    });
  }

  @override
  FutureEither<InventoryPart> updatePart(InventoryPart part) async {
    final result = await _databaseService.updateDocument(
      collectionId: AppwriteConstants.collectionPartsInventory,
      documentId: part.id,
      data: part.toJson(),
    );

    return result.map((_) => part);
  }
}
