import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:get/get.dart';
import 'package:resolveflow/src/controllers/auth/session_controller.dart';
import 'package:resolveflow/src/routing/app_routes.dart';
import 'package:resolveflow/src/theme/resolveflow_colors.dart';
import 'package:resolveflow/src/views/diagnostic/diagnostic_search_screen.dart';
import 'package:resolveflow/src/views/inventory/inventory_view.dart';
import 'package:resolveflow/src/views/team/team_management_view.dart';
import 'package:resolveflow/src/views/work_orders/work_orders_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();

    return Obx(() {
      final user = session.user;
      final isManager = user?.isManager ?? false;

      // Dynamic Views: Manager gets the 4th "Technicians" management view
      final views = <Widget>[
        const DiagnosticSearchScreen(),
        const InventoryView(),
        const WorkOrdersView(),
        if (isManager) const TeamManagementView(),
      ];

      // Dynamic Navigation Items: 4th tab hidden if user is a technician
      final navItems = <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: Icon(FlutterRemix.stethoscope_line),
          activeIcon: Icon(FlutterRemix.stethoscope_fill),
          label: 'Diagnostics',
        ),
        const BottomNavigationBarItem(
          icon: Icon(FlutterRemix.archive_line),
          activeIcon: Icon(FlutterRemix.archive_fill),
          label: 'Live Inventory',
        ),
        const BottomNavigationBarItem(
          icon: Icon(FlutterRemix.file_list_3_line),
          activeIcon: Icon(FlutterRemix.file_list_3_fill),
          label: 'Work Orders',
        ),
        if (isManager)
          const BottomNavigationBarItem(
            icon: Icon(FlutterRemix.team_line),
            activeIcon: Icon(FlutterRemix.team_fill),
            label: 'Technicians',
          ),
      ];

      final safeIndex = _currentIndex < views.length ? _currentIndex : 0;

      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: AppColors.evergreen,
          elevation: 0,
          centerTitle: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppColors.limeCream,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  FlutterRemix.pulse_line,
                  color: AppColors.evergreen,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ResolveFlow',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Diagnostics & Spare-Parts',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.limeCream.withValues(alpha: 0.8),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Dynamic RBAC Role Badge & Profile Button (Navigates to dedicated Profile Screen)
            Builder(builder: (context) {
              final isTech = user?.isTechnician ?? false;

              String roleLabel = 'Technician';
              Color roleBg = AppColors.fern;

              if (isManager) {
                roleLabel = 'Manager';
                roleBg = AppColors.hunterGreen;
              } else if (isTech) {
                roleLabel = 'Technician';
                roleBg = AppColors.fern;
              }

              return Center(
                child: InkWell(
                  onTap: () => Get.toNamed(AppRoutes.profile),
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    margin: EdgeInsets.only(right: 12.w),
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: roleBg,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.limeCream.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isManager ? FlutterRemix.shield_user_line : FlutterRemix.tools_line,
                          size: 13.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          FlutterRemix.arrow_right_s_line,
                          size: 14.sp,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        body: IndexedStack(
          index: safeIndex,
          children: views,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppColors.fern,
          unselectedItemColor: Colors.black45,
          selectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 11.sp),
          type: BottomNavigationBarType.fixed,
          items: navItems,
        ),
      );
    });
  }
}
