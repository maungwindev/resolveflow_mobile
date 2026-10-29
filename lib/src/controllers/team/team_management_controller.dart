import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:resolveflow/src/controllers/auth/session_controller.dart';
import 'package:resolveflow/src/models/technician_member.dart';
import 'package:resolveflow/src/services/user_provisioning_service.dart';
import 'package:resolveflow/src/shared/helpers/show_toast.dart';
import 'package:resolveflow/src/utils/async_state.dart';
import 'package:resolveflow/src/utils/failure.dart';
import 'package:resolveflow/src/utils/logger.dart';

class TeamManagementController extends GetxController {
  TeamManagementController({UserProvisioningService? service})
      : _service = service ?? UserProvisioningServiceImpl();

  final UserProvisioningService _service;

  final Rx<RequestState<List<TechnicianMember>>> techniciansState =
      Rx<RequestState<List<TechnicianMember>>>(const RequestInitial());

  final Rx<RequestState<TechnicianMember?>> createState =
      Rx<RequestState<TechnicianMember?>>(const RequestInitial());

  final RxBool isDeleting = false.obs;
  final RxBool isUpdatingPassword = false.obs;

  List<TechnicianMember> get technicians => switch (techniciansState.value) {
        RequestSuccess(:final data) => data,
        _ => const [],
      };

  bool get isLoading => techniciansState.value.isLoading;
  bool get isCreating => createState.value.isLoading;

  @override
  void onInit() {
    super.onInit();
    final session = Get.find<SessionController>();
    if (session.user?.isManager ?? false) {
      fetchTechnicians();
    }
  }

  Future<void> fetchTechnicians({bool showLoading = true}) async {
    final session = Get.find<SessionController>();
    if (!(session.user?.isManager ?? false)) {
      techniciansState.value = const RequestFailure(
        ServerFailure('Access restricted to Managers.'),
      );
      return;
    }

    if (showLoading) {
      techniciansState.value = const RequestLoading();
    }

    final result = await _service.getTechnicians();

    result.fold(
      (failure) => techniciansState.value = RequestFailure(failure),
      (data) => techniciansState.value = RequestSuccess(data),
    );
  }

  Future<bool> createTechnician({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final session = Get.find<SessionController>();
    if (!(session.user?.isManager ?? false)) {
      if (context.mounted) {
        showToast(
          context,
          message: 'Permission denied: Only managers can provision technicians.',
          status: 'error',
        );
      }
      return false;
    }

    createState.value = const RequestLoading();

    try {
      final result = await _service.createTechnician(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      return result.fold(
        (failure) {
          createState.value = RequestFailure(failure);
          if (context.mounted) {
            showToast(context, message: failure.message, status: 'error');
          }
          return false;
        },
        (newTechnician) {
          createState.value = RequestSuccess(newTechnician);
          if (context.mounted) {
            showToast(
              context,
              message: 'Technician ${newTechnician.name} provisioned successfully!',
              status: 'success',
            );
          }
          // Refresh list immediately
          fetchTechnicians(showLoading: false);
          return true;
        },
      );
    } catch (e, st) {
      AppLogger.error('TeamManagementController: createTechnician exception', error: e, stackTrace: st);
      final failure = ServerFailure('Unexpected error: $e');
      createState.value = RequestFailure(failure);
      if (context.mounted) {
        showToast(context, message: failure.message, status: 'error');
      }
      return false;
    }
  }

  Future<bool> deleteTechnician({
    required BuildContext context,
    required String userId,
    required String membershipId,
    required String name,
  }) async {
    final session = Get.find<SessionController>();
    if (!(session.user?.isManager ?? false)) {
      if (context.mounted) {
        showToast(
          context,
          message: 'Permission denied: Only managers can delete technicians.',
          status: 'error',
        );
      }
      return false;
    }

    isDeleting.value = true;

    try {
      final result = await _service.deleteTechnician(
        userId: userId,
        membershipId: membershipId,
      );

      return result.fold(
        (failure) {
          isDeleting.value = false;
          if (context.mounted) {
            showToast(context, message: 'Deactivation failed: ${failure.message}', status: 'error');
          }
          return false;
        },
        (_) {
          isDeleting.value = false;
          if (context.mounted) {
            showToast(
              context,
              message: 'Technician $name deactivated successfully.',
              status: 'success',
            );
          }
          fetchTechnicians(showLoading: false);
          return true;
        },
      );
    } catch (e, st) {
      isDeleting.value = false;
      AppLogger.error('TeamManagementController: deleteTechnician exception', error: e, stackTrace: st);
      if (context.mounted) {
        showToast(context, message: 'Delete error: $e', status: 'error');
      }
      return false;
    }
  }

  Future<bool> reactivateTechnician({
    required BuildContext context,
    required String userId,
    required String name,
  }) async {
    final session = Get.find<SessionController>();
    if (!(session.user?.isManager ?? false)) {
      if (context.mounted) {
        showToast(
          context,
          message: 'Permission denied: Only managers can reactivate technicians.',
          status: 'error',
        );
      }
      return false;
    }

    try {
      final result = await _service.reactivateTechnician(userId: userId);

      return result.fold(
        (failure) {
          if (context.mounted) {
            showToast(context, message: 'Reactivation failed: ${failure.message}', status: 'error');
          }
          return false;
        },
        (_) {
          if (context.mounted) {
            showToast(
              context,
              message: 'Technician $name reactivated successfully.',
              status: 'success',
            );
          }
          fetchTechnicians(showLoading: false);
          return true;
        },
      );
    } catch (e, st) {
      AppLogger.error('TeamManagementController: reactivateTechnician exception', error: e, stackTrace: st);
      if (context.mounted) {
        showToast(context, message: 'Reactivation error: $e', status: 'error');
      }
      return false;
    }
  }

  Future<bool> updateTechnicianPassword({
    required BuildContext context,
    required String userId,
    required String newPassword,
    required String name,
  }) async {
    final session = Get.find<SessionController>();
    if (!(session.user?.isManager ?? false)) {
      if (context.mounted) {
        showToast(
          context,
          message: 'Permission denied: Only managers can update passwords.',
          status: 'error',
        );
      }
      return false;
    }

    isUpdatingPassword.value = true;

    try {
      final result = await _service.updateTechnicianPassword(
        userId: userId,
        newPassword: newPassword,
      );

      return result.fold(
        (failure) {
          isUpdatingPassword.value = false;
          if (context.mounted) {
            showToast(context, message: 'Password update failed: ${failure.message}', status: 'error');
          }
          return false;
        },
        (_) {
          isUpdatingPassword.value = false;
          if (context.mounted) {
            showToast(
              context,
              message: 'Password for $name updated successfully.',
              status: 'success',
            );
          }
          return true;
        },
      );
    } catch (e, st) {
      isUpdatingPassword.value = false;
      AppLogger.error('TeamManagementController: updateTechnicianPassword exception', error: e, stackTrace: st);
      if (context.mounted) {
        showToast(context, message: 'Password update error: $e', status: 'error');
      }
      return false;
    }
  }
}
