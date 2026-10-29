import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:resolveflow/src/controllers/team/team_management_controller.dart';
import 'package:resolveflow/src/models/technician_member.dart';
import 'package:resolveflow/src/routing/app_routes.dart';
import 'package:resolveflow/src/theme/resolveflow_colors.dart';
import 'package:resolveflow/src/utils/async_state.dart';

class TeamManagementView extends StatefulWidget {
  const TeamManagementView({super.key});

  @override
  State<TeamManagementView> createState() => _TeamManagementViewState();
}

class _TeamManagementViewState extends State<TeamManagementView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all' | 'active' | 'inactive'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<TeamManagementController>()) {
        Get.find<TeamManagementController>().fetchTechnicians(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamManagementController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Top Search & Status Filter Bar
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Input Field
                SizedBox(
                  height: 44.h,
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search technicians by name, email, or phone...',
                      hintStyle: TextStyle(fontSize: 12.sp, color: Colors.black38),
                      prefixIcon: Icon(FlutterRemix.search_line, size: 18.sp, color: AppColors.fern),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(FlutterRemix.close_circle_line, size: 16.sp, color: Colors.black38),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      filled: true,
                      fillColor: const Color(0xFFF7F8F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: const BorderSide(color: AppColors.fern, width: 1.5),
                      ),
                    ),
                    onChanged: (text) {
                      setState(() => _searchQuery = text.trim().toLowerCase());
                    },
                  ),
                ),

                SizedBox(height: 10.h),

                // Team Stats & Status Filter Row (Replaces duplicate Add Technician button)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Active Technicians Counter
                    Obx(() {
                      final allTechs = controller.technicians;
                      final activeCount = allTechs.where((t) => t.isActive).length;
                      final total = allTechs.length;

                      return Row(
                        children: [
                          Icon(FlutterRemix.team_line, size: 16.sp, color: AppColors.hunterGreen),
                          SizedBox(width: 6.w),
                          Text(
                            '$activeCount / $total Active Field Technicians',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.hunterGreen,
                            ),
                          ),
                        ],
                      );
                    }),

                    // Status Filter Dropdown (Beside Active Field Technicians)
                    Container(
                      height: 32.h,
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8F9),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _statusFilter,
                          isDense: true,
                          icon: Icon(FlutterRemix.filter_3_line, size: 14.sp, color: AppColors.fern),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.evergreen,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Status')),
                            DropdownMenuItem(value: 'active', child: Text('Active Only')),
                            DropdownMenuItem(value: 'inactive', child: Text('Inactive Only')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _statusFilter = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Roster List
          Expanded(
            child: Obx(() {
              final state = controller.techniciansState.value;

              return switch (state) {
                RequestInitial() || RequestLoading() => const Center(
                    child: CircularProgressIndicator(color: AppColors.fern),
                  ),
                RequestFailure(:final failure) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FlutterRemix.error_warning_line, size: 40.sp, color: Colors.red),
                          SizedBox(height: 8.h),
                          Text(failure.message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
                          SizedBox(height: 12.h),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.fern),
                            onPressed: () => controller.fetchTechnicians(),
                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                RequestSuccess() => _buildTechniciansList(controller),
              };
            }),
          ),
        ],
      ),
      // Single, Dedicated Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.hunterGreen,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () => Get.toNamed(AppRoutes.createTechnician),
        icon: const Icon(FlutterRemix.user_add_line),
        label: const Text('Add Technician', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTechniciansList(TeamManagementController controller) {
    var technicians = controller.technicians;

    // 1. Filter by Status (Active / Inactive)
    if (_statusFilter == 'active') {
      technicians = technicians.where((t) => t.isActive).toList();
    } else if (_statusFilter == 'inactive') {
      technicians = technicians.where((t) => !t.isActive).toList();
    }

    // 2. Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      technicians = technicians.where((t) {
        final matchesName = t.name.toLowerCase().contains(_searchQuery);
        final matchesEmail = t.email.toLowerCase().contains(_searchQuery);
        final matchesPhone = t.phone != null && t.phone!.contains(_searchQuery);
        return matchesName || matchesEmail || matchesPhone;
      }).toList();
    }

    if (technicians.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FlutterRemix.team_line, size: 48.sp, color: Colors.black26),
            SizedBox(height: 8.h),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No technicians match "$_searchQuery"'
                  : (_statusFilter != 'all'
                      ? 'No technicians with status "${_statusFilter.capitalizeFirst}"'
                      : 'No field technicians provisioned yet'),
              style: TextStyle(fontSize: 14.sp, color: Colors.black54),
            ),
            SizedBox(height: 4.h),
            Text(
              'Tap "Add Technician" to provision a new technician user.',
              style: TextStyle(fontSize: 12.sp, color: Colors.black38),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.fern,
      onRefresh: () => controller.fetchTechnicians(showLoading: false),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h),
        itemCount: technicians.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final tech = technicians[index];
          return _buildTechnicianCard(tech, controller);
        },
      ),
    );
  }

  Widget _buildTechnicianCard(TechnicianMember tech, TeamManagementController controller) {
    final initials = tech.name.trim().isNotEmpty
        ? tech.name.trim().split(' ').map((part) => part.isNotEmpty ? part[0] : '').take(2).join().toUpperCase()
        : 'T';

    final joinedFormatted = tech.joinedAt != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(tech.joinedAt!)
        : 'Active Member';

    final isActive = tech.isActive;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isActive ? Colors.grey.shade200 : Colors.red.shade200,
          width: isActive ? 1 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Avatar, Name, Email, Status Pill, Role Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: isActive ? AppColors.evergreen : Colors.grey.shade600,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.limeCream : Colors.white70,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            tech.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.black87 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        // Status & Role Badges
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Explicit Status Badge (Active / Inactive)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: isActive ? const Color(0xFFA5D6A7) : const Color(0xFFFFCDD2),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6.w,
                                    height: 6.w,
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // SizedBox(width: 5.w),
                            // // Role Badge
                            // Container(
                            //   padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                            //   decoration: BoxDecoration(
                            //     color: AppColors.fern.withValues(alpha: 0.12),
                            //     borderRadius: BorderRadius.circular(6.r),
                            //   ),
                            //   child: Text(
                            //     'Technician',
                            //     style: TextStyle(
                            //       fontSize: 10.sp,
                            //       fontWeight: FontWeight.bold,
                            //       color: AppColors.fern,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(FlutterRemix.mail_line, size: 12.sp, color: AppColors.hunterGreen),
                          SizedBox(width: 4.w),
                        Text(
                          tech.email,
                          style: TextStyle(fontSize: 12.sp, color: AppColors.hunterGreen),
                        ),
                      ],
                    ),
                    if (tech.phone != null && tech.phone!.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Icon(FlutterRemix.phone_line, size: 12.sp, color: AppColors.hunterGreen),
                          SizedBox(width: 4.w),
                          Text(
                            tech.phone!,
                            style: TextStyle(fontSize: 11.sp, color: AppColors.hunterGreen, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(FlutterRemix.time_line, size: 12.sp, color: Colors.black38),
                        SizedBox(width: 4.w),
                        Text(
                          'Joined: $joinedFormatted',
                          style: TextStyle(fontSize: 11.sp, color: Colors.black38),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          Divider(height: 18.h, color: Colors.grey.shade100),

          // Manager Actions: Reset Password & Delete User
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Reset Password Button
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.hunterGreen,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(FlutterRemix.key_2_line, size: 14.sp),
                label: Text(
                  'Update Password',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showResetPasswordDialog(context, tech, controller),
              ),
              SizedBox(width: 8.w),
              // Deactivate or Reactivate Button
              if (tech.isActive)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    backgroundColor: Colors.red.shade50,
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  icon: Icon(FlutterRemix.user_unfollow_line, size: 14.sp),
                  label: Text(
                    'Deactivate',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _confirmDeleteTechnician(context, tech, controller),
                )
              else
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.hunterGreen,
                    backgroundColor: const Color(0xFFE8F5E9),
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  icon: Icon(FlutterRemix.user_shared_line, size: 14.sp),
                  label: Text(
                    'Reactivate',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => controller.reactivateTechnician(
                    context: context,
                    userId: tech.userId,
                    name: tech.name,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(
    BuildContext context,
    TechnicianMember tech,
    TeamManagementController controller,
  ) {
    final passwordController = TextEditingController();
    bool obscure = false;

    void generatePassword(StateSetter setState) {
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*';
      final random = Random.secure();
      final pwd = List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
      setState(() {
        passwordController.text = pwd;
        obscure = false;
      });
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              title: Text(
                'Update Password',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.evergreen,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Set a new login password for ${tech.name} (${tech.email})',
                    style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'New Password',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                        onPressed: () => generatePassword(setState),
                        icon: Icon(FlutterRemix.magic_line, size: 12.sp, color: AppColors.fern),
                        label: Text(
                          'Generate',
                          style: TextStyle(fontSize: 11.sp, color: AppColors.fern, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Minimum 8 characters',
                      hintStyle: TextStyle(fontSize: 12.sp, color: Colors.black38),
                      prefixIcon: Icon(FlutterRemix.lock_line, size: 16.sp, color: AppColors.fern),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? FlutterRemix.eye_off_line : FlutterRemix.eye_line,
                          size: 16.sp,
                          color: Colors.black45,
                        ),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: AppColors.fern, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: Colors.black54, fontSize: 13.sp)),
                ),
                Obx(() {
                  final isUpdating = controller.isUpdatingPassword.value;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.fern,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    onPressed: isUpdating
                        ? null
                        : () async {
                            final newPwd = passwordController.text.trim();
                            if (newPwd.length < 8) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password must be at least 8 characters')),
                              );
                              return;
                            }
                            final success = await controller.updateTechnicianPassword(
                              context: context,
                              userId: tech.userId,
                              newPassword: newPwd,
                              name: tech.name,
                            );
                            if (success && ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          },
                    child: isUpdating
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Save Password', style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTechnician(
    BuildContext context,
    TechnicianMember tech,
    TeamManagementController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            'Deactivate Technician',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          content: Text(
            'Are you sure you want to deactivate technician "${tech.name}" (${tech.email})? This action sets their account status to Inactive and revokes system login access, while safely preserving their historical work orders and audit trails in the database.',
            style: TextStyle(fontSize: 13.sp, color: Colors.black87, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 13.sp, color: Colors.black54, fontWeight: FontWeight.w600),
              ),
            ),
            Obx(() {
              final isDeleting = controller.isDeleting.value;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        final success = await controller.deleteTechnician(
                          context: context,
                          userId: tech.userId,
                          membershipId: tech.id,
                          name: tech.name,
                        );
                        if (success && ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                child: isDeleting
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Deactivate Account',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp),
                      ),
              );
            }),
          ],
        );
      },
    );
  }
}
