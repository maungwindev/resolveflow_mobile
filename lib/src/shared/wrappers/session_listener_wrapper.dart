import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/imports/packages_imports.dart';

import 'package:resolveflow/src/controllers/auth/session_controller.dart';


class SessionListenerWrapper extends StatefulWidget {
  final Widget child;
  const SessionListenerWrapper({super.key, required this.child});

  @override
  State<SessionListenerWrapper> createState() => _SessionListenerWrapperState();
}

class _SessionListenerWrapperState extends State<SessionListenerWrapper> {
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Get.find<SessionController>();

      void handleState(SessionState next) {
        switch (next) {
          case SessionUnknown():
            break;
          case SessionAuthenticated():
            FlutterNativeSplash.remove();
            // ignore: inference_failure_on_function_invocation
            Get.offAllNamed(AppRoutes.home);
          case SessionUnauthenticated():
            FlutterNativeSplash.remove();
            // ignore: inference_failure_on_function_invocation
            Get.offAllNamed(AppRoutes.login);
        }
      }

      // If state is already resolved before the post-frame callback fires
      if (!session.state.value.isUnknown) {
        handleState(session.state.value);
      }

      _worker = ever(session.state, handleState);
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
