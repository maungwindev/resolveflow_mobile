import 'package:get/get.dart';
import 'package:resolveflow/src/services/auth_repository_impl.dart';
import 'package:resolveflow/src/services/diagnostic_repository.dart';
import 'package:resolveflow/src/services/inventory_repository.dart';
import 'package:resolveflow/src/services/work_order_repository.dart';

import 'package:resolveflow/src/controllers/auth/auth_controller.dart';
import 'package:resolveflow/src/controllers/auth/session_controller.dart';
import 'package:resolveflow/src/controllers/diagnostic/diagnostic_controller.dart';
import 'package:resolveflow/src/controllers/inventory/inventory_controller.dart';
import 'package:resolveflow/src/controllers/team/team_management_controller.dart';
import 'package:resolveflow/src/controllers/work_order/work_order_controller.dart';

class AppBindings implements Bindings {
  @override
  void dependencies() {
    final authRepository = AuthRepositoryImpl();
    final diagnosticRepository = DiagnosticRepositoryImpl();
    final inventoryRepository = InventoryRepositoryImpl();
    final workOrderRepository = WorkOrderRepositoryImpl();

    Get.put<SessionController>(
      SessionController(repository: authRepository),
      permanent: true,
    );

    Get.lazyPut<AuthController>(
      () => AuthController(repository: authRepository),
      fenix: true,
    );

    Get.lazyPut<InventoryController>(
      () => InventoryController(repository: inventoryRepository),
      fenix: true,
    );

    Get.lazyPut<DiagnosticController>(
      () => DiagnosticController(repository: diagnosticRepository),
      fenix: true,
    );

    Get.lazyPut<WorkOrderController>(
      () => WorkOrderController(
        workOrderRepository: workOrderRepository,
        inventoryRepository: inventoryRepository,
      ),
      fenix: true,
    );

    Get.lazyPut<TeamManagementController>(
      () => TeamManagementController(),
      fenix: true,
    );
  }
}
