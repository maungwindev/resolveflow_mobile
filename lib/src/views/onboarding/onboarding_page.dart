import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:get/get.dart';
import 'package:resolveflow/src/routing/app_routes.dart';
import 'package:resolveflow/src/theme/resolveflow_colors.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.evergreen,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Centered Brand Identity
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Icon Container
                  Container(
                    width: 96.w,
                    height: 96.w,
                    decoration: BoxDecoration(
                      color: AppColors.limeCream,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.limeCream.withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        FlutterRemix.pulse_line,
                        size: 48.sp,
                        color: AppColors.evergreen,
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Brand Name
                  Text(
                    'ResolveFlow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Subtitle
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'Smart Field Maintenance & Spare-Parts Procurement',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.limeCream.withValues(alpha: 0.9),
                        height: 1.45,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Section: Get Started Button
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.fern,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      onPressed: () {
                        Get.offNamed(AppRoutes.login);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            FlutterRemix.arrow_right_line,
                            size: 18.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Intelligent Field Service & Spare-Parts Management',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
