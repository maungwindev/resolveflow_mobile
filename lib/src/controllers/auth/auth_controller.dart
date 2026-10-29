import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/imports/packages_imports.dart';
import 'package:resolveflow/src/services/auth_repository.dart';

class AuthController extends GetxController {
  AuthController({required AuthRepository repository})
      : _repository = repository;

  final AuthRepository _repository;
  final Rx<RequestState<void>> state = Rx<RequestState<void>>(const RequestInitial());

  bool get isLoading => state.value.isLoading;

  void login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    state.value = const RequestLoading();

    final result = await _repository.login(email: email, password: password);

    result.fold(
      (failure) {
        state.value = RequestFailure(failure);
        if (context.mounted) {
          showToast(context, message: failure.message, status: 'error');
        }
      },
      (_) {
        state.value = const RequestSuccess(null);
        Get.offAllNamed(AppRoutes.home);
      },
    );
  }

  void signUp({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
  }) async {
    state.value = const RequestLoading();

    final result = await _repository.signUp(
      name: name,
      email: email,
      password: password,
    );

    result.fold(
      (failure) {
        state.value = RequestFailure(failure);
        if (context.mounted) {
          showToast(context, message: failure.message, status: 'error');
        }
      },
      (_) {
        state.value = const RequestSuccess(null);
        Get.offAllNamed(AppRoutes.home);
      },
    );
  }

  void forgotPassword({
    required BuildContext context,
    required String email,
  }) async {
    state.value = const RequestLoading();

    final result = await _repository.forgotPassword(email: email);

    result.fold(
      (failure) {
        state.value = RequestFailure(failure);
        if (context.mounted) {
          showToast(context, message: failure.message, status: 'error');
        }
      },
      (_) {
        state.value = const RequestSuccess(null);
        if (context.mounted) {
          showToast(
            context,
            message: 'Password reset link sent successfully',
            status: 'success',
          );
        }
        Get.offNamed(AppRoutes.login);
      },
    );
  }
}
