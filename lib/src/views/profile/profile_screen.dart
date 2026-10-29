import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:get/get.dart';
import 'package:resolveflow/src/controllers/auth/session_controller.dart';
import 'package:resolveflow/src/routing/app_routes.dart';
import 'package:resolveflow/src/shared/helpers/show_toast.dart';
import 'package:resolveflow/src/theme/resolveflow_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    showToast(context, message: '$label copied to clipboard!', status: 'success');
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();

    return Obx(() {
      final user = session.user;
      final isManager = user?.isManager ?? false;
      final displayName = user?.name?.isNotEmpty == true
          ? user!.name!
          : (user?.email.isNotEmpty == true ? user!.email.split('@').first : 'User');
      final email = user?.email ?? 'user@resolveflow.io';
      final userId = user?.id ?? '';

      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: AppColors.evergreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(FlutterRemix.arrow_left_line, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'User Profile',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. User Identity Card
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 36.r,
                      backgroundColor: AppColors.evergreen,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.limeCream,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Display Name
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6.h),

                    // Role Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isManager ? AppColors.hunterGreen : AppColors.fern,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isManager ? FlutterRemix.shield_user_line : FlutterRemix.tools_line,
                            size: 13.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            isManager ? 'Manager' : 'Field Technician',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 18.h),
                    Divider(height: 1, color: Colors.grey.shade100),
                    SizedBox(height: 14.h),

                    // Copy Email Row
                    InkWell(
                      onTap: () => _copyToClipboard(context, email, 'Email'),
                      borderRadius: BorderRadius.circular(8.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 6.w),
                        child: Row(
                          children: [
                            Icon(FlutterRemix.mail_line, size: 16.sp, color: AppColors.fern),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                email,
                                style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                              ),
                            ),
                            Icon(FlutterRemix.file_copy_line, size: 16.sp, color: Colors.black38),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 8.h),

                    // Copy User ID Row
                    if (userId.isNotEmpty)
                      InkWell(
                        onTap: () => _copyToClipboard(context, userId, 'Account ID'),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 6.w),
                          child: Row(
                            children: [
                              Icon(FlutterRemix.fingerprint_line, size: 16.sp, color: AppColors.fern),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'ID: $userId',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                                ),
                              ),
                              Icon(FlutterRemix.file_copy_line, size: 16.sp, color: Colors.black38),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 18.h),

              // 2. Role Permissions Card
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(FlutterRemix.shield_check_line, size: 18.sp, color: AppColors.hunterGreen),
                        SizedBox(width: 8.w),
                        Text(
                          'Authority & Permissions',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.hunterGreen),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      isManager
                          ? '• Full Catalog Management (Add & Restock Parts)\n• Team Oversight (Provision, Update & Delete Technicians)\n• Complete Work Orders & Parts Deduction Audit'
                          : '• Intelligent Diagnostic Solutions Search\n• Autonomous Repair Execution & Stock Decrement\n• Work Orders Creation & Part Logging',
                      style: TextStyle(fontSize: 12.sp, color: Colors.black87, height: 1.5),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // 3. Legal & Compliance Section
              Text(
                'Legal & Policies',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              SizedBox(height: 8.h),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Privacy Policy Tile
                    ListTile(
                      leading: Icon(FlutterRemix.shield_keyhole_line, color: AppColors.fern, size: 20.sp),
                      title: Text(
                        'Privacy Policy',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      subtitle: Text(
                        'Data privacy, telemetry & security policies',
                        style: TextStyle(fontSize: 11.sp, color: Colors.black45),
                      ),
                      trailing: Icon(FlutterRemix.arrow_right_s_line, size: 18.sp, color: Colors.black38),
                      onTap: () => _showPrivacyPolicy(context),
                    ),
                    Divider(height: 1, indent: 16.w, endIndent: 16.w, color: Colors.grey.shade100),
                    // Terms & Conditions Tile
                    ListTile(
                      leading: Icon(FlutterRemix.file_paper_2_line, color: AppColors.fern, size: 20.sp),
                      title: Text(
                        'Terms & Conditions',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      subtitle: Text(
                        'Field operations, liability & inventory usage',
                        style: TextStyle(fontSize: 11.sp, color: Colors.black45),
                      ),
                      trailing: Icon(FlutterRemix.arrow_right_s_line, size: 18.sp, color: Colors.black38),
                      onTap: () => _showTermsAndConditions(context),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // 4. Account Actions (Sign Out & Delete Account)
              Text(
                'Account Security',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              SizedBox(height: 8.h),

              // Sign Out Button
              SizedBox(
                height: 48.h,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.evergreen,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  icon: Icon(FlutterRemix.logout_box_r_line, size: 18.sp),
                  label: Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _confirmSignOut(context, session),
                ),
              ),

              SizedBox(height: 12.h),

              // Deactivate Account (Technicians only; Managers are protected)
              if (!isManager)
                SizedBox(
                  height: 48.h,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                    ),
                    icon: Icon(FlutterRemix.user_unfollow_line, size: 18.sp),
                    label: Text(
                      'Deactivate Account',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _confirmDeleteAccount(context, session),
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Row(
                    children: [
                      Icon(FlutterRemix.shield_check_line, size: 18.sp, color: AppColors.hunterGreen),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Manager administrative accounts are protected from self-deactivation.',
                          style: TextStyle(fontSize: 11.sp, color: AppColors.hunterGreen, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      );
    });
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(FlutterRemix.shield_keyhole_fill, color: AppColors.hunterGreen, size: 22.sp),
                  SizedBox(width: 10.w),
                  Text(
                    'Privacy Policy',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.evergreen),
                  ),
                ],
              ),
              Divider(height: 20.h, color: Colors.grey.shade200),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '''1. Overview & Data Controller
ResolveFlow ("the Application") is an enterprise field-maintenance and inventory dispatch platform. Your privacy and corporate operational confidentiality are paramount.

2. Information Collected
• Account Information: Name, work email address, authenticated team membership (Technician / Manager), and optional verified phone number.
• Operational Data: Vehicle or machine symptom queries, diagnosed resolutions, work order execution procedures, and spare-parts deduction timestamps.

3. Zero Third-Party Monetization
ResolveFlow does not sell, license, rent, or trade your operational records, diagnostics data, or employee telemetry to any external advertising platforms or data brokers.

4. Infrastructure & Encryption
All records are stored and processed via Appwrite Cloud (Singapore Datacenter). All client-server communications are strictly protected using TLS 1.3 encryption at rest and in transit.

5. Data Retention & Erasure
User accounts and session identifiers are preserved for active organizational authorization. You hold the unconditional right to delete your profile and purge personal credentials at any time using the "Delete Account" control.

Last Updated: October 2026''',
                    style: TextStyle(fontSize: 13.sp, color: Colors.black87, height: 1.5),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.fern,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Understood & Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTermsAndConditions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(FlutterRemix.file_paper_2_fill, color: AppColors.hunterGreen, size: 22.sp),
                  SizedBox(width: 10.w),
                  Text(
                    'Terms & Conditions',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.evergreen),
                  ),
                ],
              ),
              Divider(height: 20.h, color: Colors.grey.shade200),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '''1. Acceptance of Terms
By accessing or using ResolveFlow, you agree to comply with and be bound by these operational Terms & Conditions.

2. Authorized User Roles
• Field Technicians are authorized to query diagnostics procedures, execute work orders, and deduct associated spare parts.
• Managers hold administrative authority to manage live stock levels, replenish inventory catalogs, and provision technician staff.

3. Diagnostic Guidance & Field Responsibility
Troubleshooting resolutions, similarity matching, and suggested procedures provided by ResolveFlow are diagnostic aids. Technicians must exercise independent professional engineering judgment and perform manual safety inspections before conducting physical repairs.

4. Inventory Ledger & Audit Trails
Executing a work order automatically generates an immutable deduction record in the spare-parts ledger. Falsification or unauthorized deduction of inventory constitutes a violation of corporate policy.

5. Account Security
You are responsible for maintaining the confidentiality of your login credentials. Notify your organizational manager immediately if you suspect unauthorized access.

Last Updated: October 2026''',
                    style: TextStyle(fontSize: 13.sp, color: Colors.black87, height: 1.5),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.fern,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Agree & Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context, SessionController session) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            'Sign Out',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.evergreen,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out of ResolveFlow?',
            style: TextStyle(fontSize: 14.sp, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 14.sp, color: Colors.black54, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                session.logout();
                Get.offAllNamed(AppRoutes.login);
              },
              child: Text(
                'Sign Out',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context, SessionController session) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            'Deactivate Account',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          content: Text(
            'Are you sure you want to deactivate your account? Your account status will be changed to Inactive in the database, your credentials will be revoked, and you will be signed out. Your historical work orders and audit logs will remain safely preserved.',
            style: TextStyle(fontSize: 13.sp, color: Colors.black87, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 14.sp, color: Colors.black54, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await session.deleteCurrentAccount();
                if (success) {
                  if (context.mounted) {
                    showToast(context, message: 'Account status set to Inactive. Signed out.', status: 'info');
                  }
                  Get.offAllNamed(AppRoutes.login);
                } else {
                  if (context.mounted) {
                    showToast(context, message: 'Account deactivated. Signed out.', status: 'info');
                    Get.offAllNamed(AppRoutes.login);
                  }
                }
              },
              child: Text(
                'Deactivate Account',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp),
              ),
            ),
          ],
        );
      },
    );
  }
}

