import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:get/get.dart';
import 'package:resolveflow/src/controllers/team/team_management_controller.dart';
import 'package:resolveflow/src/theme/resolveflow_colors.dart';

class CreateTechnicianScreen extends StatefulWidget {
  const CreateTechnicianScreen({super.key});

  @override
  State<CreateTechnicianScreen> createState() => _CreateTechnicianScreenState();
}

class _CreateTechnicianScreenState extends State<CreateTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*';
    final random = Random.secure();
    final pwd = List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
    setState(() {
      _passwordController.text = pwd;
      _obscurePassword = false;
    });
  }

  void _handleCreate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = Get.find<TeamManagementController>();
    final success = await controller.createTechnician(
      context: context,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
    );

    if (success && mounted) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamManagementController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.evergreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FlutterRemix.arrow_left_line, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Add Field Technician',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Informational Banner
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.limeCream.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.palmLeaf.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(FlutterRemix.shield_check_line, size: 20.sp, color: AppColors.evergreen),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manager Authority Granted',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.evergreen,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'This user will be provisioned directly into the technicians team with field diagnostic and repair execution permissions.',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.black87,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Full Name
                Text(
                  'Technician Name *',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'e.g. John Doe',
                    hintStyle: TextStyle(fontSize: 13.sp, color: Colors.black38),
                    prefixIcon: Icon(FlutterRemix.user_line, size: 18.sp, color: AppColors.fern),
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.fern, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Technician name is required';
                    return null;
                  },
                ),

                SizedBox(height: 18.h),

                // Email
                Text(
                  'Email Address *',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'e.g. j.doe@resolveflow.io',
                    hintStyle: TextStyle(fontSize: 13.sp, color: Colors.black38),
                    prefixIcon: Icon(FlutterRemix.mail_line, size: 18.sp, color: AppColors.fern),
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.fern, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email address';
                    return null;
                  },
                ),

                SizedBox(height: 18.h),

                // Phone Number with auto '+' from backside
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Phone Number *',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(
                      '(Max 15 digits)',
                      style: TextStyle(fontSize: 11.sp, color: Colors.black45),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Country code + number (e.g. 12025550123)',
                    hintStyle: TextStyle(fontSize: 13.sp, color: Colors.black38),
                    prefixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 12.w),
                        Icon(FlutterRemix.phone_line, size: 18.sp, color: AppColors.fern),
                        SizedBox(width: 6.w),
                        Text(
                          '+',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.evergreen,
                          ),
                        ),
                        SizedBox(width: 4.w),
                      ],
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.fern, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone number is required';
                    final digits = v.trim().replaceAll(RegExp(r'[^\d]'), '');
                    if (digits.length < 7) return 'Phone number must be at least 7 digits';
                    if (digits.length > 15) return 'Maximum of 15 digits allowed';
                    return null;
                  },
                ),

                SizedBox(height: 18.h),

                // Initial Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Initial Password *',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      onPressed: _generateRandomPassword,
                      icon: Icon(FlutterRemix.magic_line, size: 14.sp, color: AppColors.fern),
                      label: Text(
                        'Generate Secure',
                        style: TextStyle(fontSize: 12.sp, color: AppColors.fern, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleCreate(),
                  style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Minimum 8 characters',
                    hintStyle: TextStyle(fontSize: 13.sp, color: Colors.black38),
                    prefixIcon: Icon(FlutterRemix.lock_line, size: 18.sp, color: AppColors.fern),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? FlutterRemix.eye_off_line : FlutterRemix.eye_line,
                        size: 18.sp,
                        color: Colors.black45,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.fern, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),

                SizedBox(height: 24.h),

                // Assigned Role Preview
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8F9),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assigned Team Role',
                        style: TextStyle(fontSize: 12.sp, color: Colors.black54, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.fern,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FlutterRemix.tools_line, size: 12.sp, color: Colors.white),
                            SizedBox(width: 4.w),
                            Text(
                              'Technician',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // Submit Button
                Obx(() {
                  final isCreating = controller.isCreating;
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
                      onPressed: isCreating ? null : _handleCreate,
                      child: isCreating
                          ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(FlutterRemix.user_add_line, size: 18.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  'Provision Technician Account',
                                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
