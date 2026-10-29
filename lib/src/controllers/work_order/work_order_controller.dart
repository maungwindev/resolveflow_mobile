import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/imports/packages_imports.dart';
import 'package:resolveflow/src/controllers/auth/session_controller.dart';
import 'package:resolveflow/src/controllers/inventory/inventory_controller.dart';
import 'package:resolveflow/src/models/resolution_result.dart';
import 'package:resolveflow/src/models/work_order.dart';
import 'package:resolveflow/src/models/work_order_part.dart';
import 'package:resolveflow/src/services/inventory_repository.dart';
import 'package:resolveflow/src/services/work_order_repository.dart';

class WorkOrderController extends GetxController {
  WorkOrderController({
    required WorkOrderRepository workOrderRepository,
    required InventoryRepository inventoryRepository,
  })  : _workOrderRepository = workOrderRepository,
        _inventoryRepository = inventoryRepository;

  final WorkOrderRepository _workOrderRepository;
  final InventoryRepository _inventoryRepository;

  final Rx<RequestState<List<WorkOrder>>> ordersState =
      Rx<RequestState<List<WorkOrder>>>(const RequestInitial());

  final Rx<RequestState<({WorkOrder workOrder, WorkOrderPart workOrderPart})?>>
      executionState = Rx<
          RequestState<
              ({WorkOrder workOrder, WorkOrderPart workOrderPart})?>>(
          const RequestInitial());

  List<WorkOrder> get orders => switch (ordersState.value) {
        RequestSuccess(:final data) => data,
        _ => const [],
      };

  bool get isLoading => ordersState.value.isLoading;
  bool get isExecuting => executionState.value.isLoading;

  @override
  void onInit() {
    super.onInit();
    fetchWorkOrders();
  }

  Future<void> fetchWorkOrders({bool showLoading = true}) async {
    if (showLoading) {
      ordersState.value = const RequestLoading();
    }

    final result = await _workOrderRepository.getWorkOrders();

    result.fold(
      (failure) => ordersState.value = RequestFailure(failure),
      (data) => ordersState.value = RequestSuccess(data),
    );
  }

  /// Fetches deduction records for a specific work order.
  Future<List<WorkOrderPart>> fetchWorkOrderParts(String workOrderId) async {
    final result = await _workOrderRepository.getWorkOrderParts(workOrderId);
    return result.getOrElse((_) => <WorkOrderPart>[]);
  }

  /// Transactional State Execution:
  /// 1. Validate target SKU inventory > 0
  /// 2. Decrement inventory count by 1 in `parts_inventory`
  /// 3. Insert record into `work_orders` (WO-XXXX)
  /// 4. Insert entry into `work_order_parts`
  /// 5. Refresh inventory and orders state
  Future<({WorkOrder workOrder, WorkOrderPart workOrderPart})?> executeWorkOrder({
    required BuildContext context,
    required ResolutionResult resolution,
    required String sku,
  }) async {
    executionState.value = const RequestLoading();

    try {
      // 1. Verify available inventory
      AppLogger.info('executeWorkOrder: Step 1 - Fetching part by SKU: $sku');
      final partResult = await _inventoryRepository.getPartBySku(sku);

      if (partResult.isLeft()) {
        final failure = partResult.getLeft().toNullable()!;
        executionState.value = RequestFailure(failure);
        if (context.mounted) {
          showToast(context, message: 'Stock lookup error: ${failure.message}', status: 'error');
        }
        return null;
      }

      final part = partResult.getOrElse((_) => null);

      if (part == null) {
        final failure = ServerFailure('Part with SKU "$sku" not found in inventory catalog.');
        executionState.value = RequestFailure(failure);
        if (context.mounted) {
          showToast(
            context,
            message: 'Error: Part SKU "$sku" does not exist in inventory.',
            status: 'error',
          );
        }
        return null;
      }

      if (part.quantityOnHand <= 0) {
        final failure = ServerFailure('Part "${part.name}" is OUT OF STOCK. Cannot apply fix.');
        executionState.value = RequestFailure(failure);
        if (context.mounted) {
          showToast(
            context,
            message: 'Depleted Stock: ${part.name} (0 available). Contact manager.',
            status: 'error',
          );
        }
        return null;
      }

      // 2. Decrement inventory count by 1
      AppLogger.info('executeWorkOrder: Step 2 - Decrementing stock for SKU: ${part.sku}');
      final decrementResult = await _inventoryRepository.decrementStock(sku, amount: 1);

      if (decrementResult.isLeft()) {
        final failure = decrementResult.getLeft().toNullable()!;
        executionState.value = RequestFailure(failure);
        if (context.mounted) {
          showToast(
            context,
            message: 'Failed to decrement inventory: ${failure.message}',
            status: 'error',
          );
        }
        return null;
      }

      // 3. Obtain current technician info from session
      final session = Get.find<SessionController>();
      final user = session.user;
      final techId = user?.id.isNotEmpty == true ? user!.id : 'tech_field';
      final techName = user?.name?.isNotEmpty == true
          ? user!.name!
          : (user?.email.isNotEmpty == true ? user!.email : 'Technician');

      // 4. Create work order and log part deduction
      AppLogger.info('executeWorkOrder: Step 4 - Creating work_order and logging part');
      final orderResult = await _workOrderRepository.createWorkOrder(
        symptomTitle: resolution.title,
        resolutionSummary: resolution.fixProcedure,
        technicianId: techId,
        technicianName: techName,
        sku: part.sku,
        partName: part.name,
        quantityDeducted: 1,
      );

      return orderResult.fold(
        (failure) {
          executionState.value = RequestFailure(failure);
          if (context.mounted) {
            showToast(
              context,
              message: 'Failed to create work order: ${failure.message}',
              status: 'error',
            );
          }
          return null;
        },
        (successRecord) {
          executionState.value = RequestSuccess(successRecord);

          // 5. Trigger reactive refresh in InventoryController
          if (Get.isRegistered<InventoryController>()) {
            Get.find<InventoryController>().fetchParts(showLoading: false);
          }

          // Refresh orders list
          fetchWorkOrders(showLoading: false);

          return successRecord;
        },
      );
    } catch (e, st) {
      AppLogger.error('executeWorkOrder exception', error: e, stackTrace: st);
      final failure = ServerFailure('Unexpected transaction error: $e');
      executionState.value = RequestFailure(failure);
      if (context.mounted) {
        showToast(context, message: 'Transaction error: $e', status: 'error');
      }
      return null;
    }
  }
}
