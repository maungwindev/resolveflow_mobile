import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:get/get.dart';
import 'package:resolveflow/src/controllers/auth/auth_controller.dart';
import 'package:resolveflow/src/routing/app_routes.dart';
import 'package:resolveflow/src/theme/resolveflow_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = Get.find<AuthController>();
    controller.login(
      context: context,
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 10.h),

                // Brand Header (Logo + Name) matching Image 1
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.fern,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          FlutterRemix.pulse_line,
                          size: 22.sp,
                          color: AppColors.limeCream,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'ResolveFlow',
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.evergreen,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 36.h),

                // Title
                Text(
                  'Login to your Account',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.evergreen,
                  ),
                ),

                SizedBox(height: 24.h),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(fontSize: 15.sp, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black38),
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                          prefixIcon: const Icon(FlutterRemix.mail_line, color: Colors.black45, size: 20),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(color: AppColors.fern, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(color: Colors.red, width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16.h),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        style: TextStyle(fontSize: 15.sp, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black38),
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                          prefixIcon: const Icon(FlutterRemix.lock_line, color: Colors.black45, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? FlutterRemix.eye_off_line : FlutterRemix.eye_line,
                              color: Colors.black45,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(color: AppColors.fern, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(color: Colors.red, width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 24.h),

                      // Sign In Button
                      Obx(() {
                        final isLoading = controller.state.value.isLoading;
                        return SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.fern,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: isLoading ? null : _handleLogin,
                            child: isLoading
                                ? SizedBox(
                                    width: 22.w,
                                    height: 22.w,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                SizedBox(height: 28.h),

                // Divider "- Or Sign In with -"
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Text(
                        '- Or sign in with -',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                  ],
                ),

                SizedBox(height: 20.h),

                // Demo Quick Fill Buttons for Technician & Manager
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      icon: const Icon(FlutterRemix.tools_line, size: 16, color: AppColors.hunterGreen),
                      label: Text(
                        'Demo Tech',
                        style: TextStyle(fontSize: 12.sp, color: AppColors.hunterGreen, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        _emailController.text = 'technician@resolveflow.com';
                        _passwordController.text = 'Password123@';
                      },
                    ),
                    SizedBox(width: 12.w),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      icon: const Icon(FlutterRemix.shield_user_line, size: 16, color: AppColors.evergreen),
                      label: Text(
                        'Demo Manager',
                        style: TextStyle(fontSize: 12.sp, color: AppColors.evergreen, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        _emailController.text = 'manager@resolveflow.com';
                        _passwordController.text = 'Password123@';
                      },
                    ),
                  ],
                ),

                SizedBox(height: 36.h),

                // Bottom Link: Don't have an account? Sign up
                // Center(
                //   child: InkWell(
                //     onTap: () {
                //       Get.toNamed(AppRoutes.signup);
                //     },
                //     child: Padding(
                //       padding: EdgeInsets.all(8.w),
                //       child: RichText(
                //         text: TextSpan(
                //           text: "Don't have an account? ",
                //           style: TextStyle(
                //             fontSize: 14.sp,
                //             color: Colors.black54,
                //           ),
                //           children: const [
                //             TextSpan(
                //               text: 'Sign up',
                //               style: TextStyle(
                //                 color: AppColors.fern,
                //                 fontWeight: FontWeight.bold,
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ),
                //   ),
                // ),

                // SizedBox(height: 10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
