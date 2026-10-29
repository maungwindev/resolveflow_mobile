// Flutter SDK
export 'package:flutter/material.dart';
export 'package:flutter/cupertino.dart' hide RefreshCallback;
export 'package:flutter/foundation.dart';
export 'package:flutter/services.dart';
export 'package:flutter_native_splash/flutter_native_splash.dart';

export 'package:easy_localization/easy_localization.dart'
    hide TextDirection, MapExtension;

// Project Core — everything exported through shared.dart (theme, extensions,
// utils, widgets, enums) plus routing and services.
export '../config/app_config.dart';
export '../config/appwrite_collections.dart';
export '../routing/app_router.dart';
export '../routing/app_routes.dart';
export '../routing/global_navigator.dart';
export '../routing/app_bindings.dart';
export '../services/services.dart';
export '../shared/shared.dart';

export '../views/auth/login_screen.dart';
export '../views/auth/signup_screen.dart';
export '../views/auth/forgot_password_screen.dart';
export '../views/home/home_page.dart';
export '../views/profile/profile_screen.dart';
export '../views/onboarding/onboarding_page.dart';
