import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:fpdart/fpdart.dart';
import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/models/work_order.dart';
import 'package:resolveflow/src/models/work_order_part.dart';
import 'package:resolveflow/src/services/appwrite_database_service.dart';

abstract class WorkOrderRepository {
  /// Generates WO-XXXX, records the order in `work_orders`, and logs the deducted part in `work_order_parts`.
  FutureEither<({WorkOrder workOrder, WorkOrderPart workOrderPart})> createWorkOrder({
    required String symptomTitle,
    required String resolutionSummary,
    required String technicianId,
    required String technicianName,
    required String sku,
    required String partName,
    int quantityDeducted = 1,
  });

  /// Lists all work orders (ordered newest first).
  FutureEither<List<WorkOrder>> getWorkOrders({int limit = 50});

  /// Lists parts deduction logs for a given work order.
  FutureEither<List<WorkOrderPart>> getWorkOrderParts(String workOrderId);
}

class WorkOrderRepositoryImpl implements WorkOrderRepository {
  WorkOrderRepositoryImpl({AppwriteDatabaseService? databaseService})
      : _databaseService = databaseService ?? AppwriteDatabaseService.instance;

  final AppwriteDatabaseService _databaseService;

  String _generateWorkOrderNumber() {
    final randomDigits = 1000 + Random().nextInt(9000);
    return 'WO-$randomDigits';
  }

  @override
  FutureEither<({WorkOrder workOrder, WorkOrderPart workOrderPart})> createWorkOrder({
    required String symptomTitle,
    required String resolutionSummary,
    required String technicianId,
    required String technicianName,
    required String sku,
    required String partName,
    int quantityDeducted = 1,
  }) async {
    final woNumber = _generateWorkOrderNumber();
    final now = DateTime.now();

    // 1. Create work_orders record
    final workOrderData = {
      'work_order_number': woNumber,
      'symptom_title': symptomTitle,
      'resolution_summary': resolutionSummary,
      'technician_id': technicianId,
      'technician_name': technicianName,
      'status': 'completed',
      'created_at': now.toIso8601String(),
    };

    final woResult = await _databaseService.createDocument(
      AppwriteConstants.collectionWorkOrders,
      workOrderData,
    );

    if (woResult.isLeft()) {
      return left(woResult.getLeft().toNullable()!);
    }

    final woResponse = woResult.getOrElse((_) => null);
    final woId = woResponse is models.Document ? woResponse.$id : ID.unique();
    final woModel = WorkOrder(
      id: woId,
      workOrderNumber: woNumber,
      symptomTitle: symptomTitle,
      resolutionSummary: resolutionSummary,
      technicianId: technicianId,
      technicianName: technicianName,
      status: 'completed',
      createdAt: now,
    );

    // 2. Insert into work_order_parts
    final partLogData = {
      'work_order_id': woId,
      'sku': sku,
      'part_name': partName,
      'quantity_deducted': quantityDeducted,
      'timestamp': now.toIso8601String(),
    };

    final partResult = await _databaseService.createDocument(
      AppwriteConstants.collectionWorkOrderParts,
      partLogData,
    );

    if (partResult.isLeft()) {
      return left(partResult.getLeft().toNullable()!);
    }

    final partResponse = partResult.getOrElse((_) => null);
    final partLogId = partResponse is models.Document ? partResponse.$id : ID.unique();
    final partModel = WorkOrderPart(
      id: partLogId,
      workOrderId: woId,
      sku: sku,
      partName: partName,
      quantityDeducted: quantityDeducted,
      timestamp: now,
    );

    return right((workOrder: woModel, workOrderPart: partModel));
  }

  @override
  FutureEither<List<WorkOrder>> getWorkOrders({int limit = 50}) async {
    final result = await _databaseService.listDocuments(
      AppwriteConstants.collectionWorkOrders,
      queries: [
        Query.limit(limit),
      ],
    );

    return result.map((response) {
      if (response is models.DocumentList) {
        final list = response.documents.map((doc) {
          final data = doc.data;
          data['\$id'] = doc.$id;
          return WorkOrder.fromJson(data);
        }).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }
      return <WorkOrder>[];
    });
  }

  @override
  FutureEither<List<WorkOrderPart>> getWorkOrderParts(String workOrderId) async {
    final result = await _databaseService.listDocuments(
      AppwriteConstants.collectionWorkOrderParts,
      queries: [
        Query.limit(50),
      ],
    );

    return result.map((response) {
      if (response is models.DocumentList) {
        final list = response.documents
            .map((doc) {
              final data = doc.data;
              data['\$id'] = doc.$id;
              return WorkOrderPart.fromJson(data);
            })
            .where((p) => p.workOrderId == workOrderId)
            .toList();
        return list;
      }
      return <WorkOrderPart>[];
    });
  }
}
