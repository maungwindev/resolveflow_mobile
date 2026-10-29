import 'package:resolveflow/src/imports/imports.dart';
import 'package:resolveflow/src/routing/app_routes.dart';

import 'package:resolveflow/src/views/auth/login_screen.dart';
import 'package:resolveflow/src/views/auth/signup_screen.dart';
import 'package:resolveflow/src/views/auth/forgot_password_screen.dart';

import 'package:resolveflow/src/views/home/home_page.dart';
import 'package:resolveflow/src/views/inventory/add_part_screen.dart';
import 'package:resolveflow/src/views/onboarding/onboarding_page.dart';
import 'package:resolveflow/src/views/profile/profile_screen.dart';
import 'package:resolveflow/src/views/team/create_technician_screen.dart';


class AppRouter {
  static List<GetPage> get getPages => [
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingPage(),
        ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
        ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupScreen(),
        ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
        ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
        ),
    GetPage(
      name: AppRoutes.addPart,
      page: () => const AddPartScreen(),
    ),
    GetPage(
      name: AppRoutes.createTechnician,
      page: () => const CreateTechnicianScreen(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
    ),
  ];
}
