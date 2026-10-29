import 'dart:async';
import 'package:resolveflow/src/imports/imports.dart';
import 'package:resolveflow/src/models/user_model.dart';
import 'package:resolveflow/src/services/auth_repository.dart';

/// Exhaustive session variants — prefer `switch (state)` over status enums.
sealed class SessionState {
  const SessionState();

  AppUser? get userOrNull => switch (this) {
        SessionAuthenticated(:final user) => user,
        _ => null,
      };

  bool get isUnknown => this is SessionUnknown;
  bool get isAuthenticated => this is SessionAuthenticated;
  bool get isUnauthenticated => this is SessionUnauthenticated;
}

final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

final class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.user);
  final AppUser user;
}

final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

SessionState sessionFromUser(AppUser? user) => switch (user) {
      final AppUser u => SessionAuthenticated(u),
      null => const SessionUnauthenticated(),
    };

class SessionController extends GetxController with StreamSubscriptionsMixin {
  SessionController({required AuthRepository repository})
      : _repository = repository;

  final AuthRepository _repository;
  final Rx<SessionState> state = Rx<SessionState>(const SessionUnknown());

  AppUser? get user => state.value.userOrNull;
  bool get isAuthenticated => state.value.isAuthenticated;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    final result = await _repository.checkAuthState();
    state.value = result.fold(
      (_) => const SessionUnauthenticated(),
      sessionFromUser,
    );

    addSubscription(
      _repository.onAuthStateChanged.listen((user) {
        state.value = sessionFromUser(user);
      }),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state.value = const SessionUnauthenticated();
  }

  Future<bool> deleteCurrentAccount() async {
    final currentUser = user;
    if (currentUser == null || currentUser.id.isEmpty) return false;

    final result = await _repository.deleteAccount(currentUser.id);
    return result.fold(
      (_) => false,
      (_) {
        state.value = const SessionUnauthenticated();
        return true;
      },
    );
  }

  @override
  void onClose() {
    cancelSubscriptions();
    super.onClose();
  }
}
