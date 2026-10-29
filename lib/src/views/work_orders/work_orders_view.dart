import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:resolveflow/src/controllers/work_order/work_order_controller.dart';
import 'package:resolveflow/src/models/work_order.dart';
import 'package:resolveflow/src/models/work_order_part.dart';
import 'package:resolveflow/src/theme/resolveflow_colors.dart';
import 'package:resolveflow/src/utils/async_state.dart';

class WorkOrdersView extends StatefulWidget {
  const WorkOrdersView({super.key});

  @override
  State<WorkOrdersView> createState() => _WorkOrdersViewState();
}

class _WorkOrdersViewState extends State<WorkOrdersView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkOrderController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Top Search Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
            child: SizedBox(
              height: 44.h,
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search by WO# (e.g. WO-4821) or symptom...',
                  hintStyle: TextStyle(fontSize: 12.sp, color: Colors.black38),
                  prefixIcon: Icon(FlutterRemix.search_line, size: 16, color: AppColors.fern),
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
          ),

          // Orders List
          Expanded(
            child: Obx(() {
              final state = controller.ordersState.value;

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
                          Text(failure.message, textAlign: TextAlign.center),
                          SizedBox(height: 12.h),
                          ElevatedButton(
                            onPressed: () => controller.fetchWorkOrders(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                RequestSuccess() => _buildOrdersList(controller),
              };
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(WorkOrderController controller) {
    var orders = controller.orders;

    if (_searchQuery.isNotEmpty) {
      orders = orders.where((o) {
        final matchesNumber = o.workOrderNumber.toLowerCase().contains(_searchQuery);
        final matchesSymptom = o.symptomTitle.toLowerCase().contains(_searchQuery);
        final matchesTech = o.technicianName.toLowerCase().contains(_searchQuery);
        return matchesNumber || matchesSymptom || matchesTech;
      }).toList();
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FlutterRemix.file_list_3_line, size: 48.sp, color: Colors.black26),
            SizedBox(height: 8.h),
            Text(
              _searchQuery.isNotEmpty ? 'No work orders match "$_searchQuery"' : 'No work orders executed yet',
              style: TextStyle(fontSize: 14.sp, color: Colors.black54),
            ),
            SizedBox(height: 4.h),
            Text(
              _searchQuery.isNotEmpty ? 'Try searching another number or symptom.' : 'Apply a resolution fix to create a work order.',
              style: TextStyle(fontSize: 12.sp, color: Colors.black38),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.fern,
      onRefresh: () => controller.fetchWorkOrders(showLoading: false),
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: orders.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(context, order, controller);
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WorkOrder order, WorkOrderController controller) {
    final formattedTime = DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt);

    return InkWell(
      onTap: () => _showOrderDetail(context, order, controller),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.grey.shade200),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.hunterGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FlutterRemix.file_text_line, size: 14.sp, color: AppColors.hunterGreen),
                      SizedBox(width: 4.w),
                      Text(
                        order.workOrderNumber,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.hunterGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppColors.limeCream,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.evergreen,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(FlutterRemix.arrow_right_s_line, size: 18.sp, color: Colors.black26),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              order.symptomTitle,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              order.resolutionSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.sp, color: Colors.black54),
            ),
            Divider(height: 20.h, color: Colors.grey.shade200),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(FlutterRemix.user_3_line, size: 14.sp, color: Colors.black45),
                    SizedBox(width: 4.w),
                    Text(
                      order.technicianName.isNotEmpty ? order.technicianName : 'Technician',
                      style: TextStyle(fontSize: 11.sp, color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(FlutterRemix.time_line, size: 14.sp, color: Colors.black45),
                    SizedBox(width: 4.w),
                    Text(
                      formattedTime,
                      style: TextStyle(fontSize: 11.sp, color: Colors.black45),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetail(BuildContext context, WorkOrder order, WorkOrderController controller) {
    final formattedTime = DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt);

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
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
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

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Work Order Details',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.evergreen,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        order.workOrderNumber,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.hunterGreen,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.limeCream,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.evergreen,
                      ),
                    ),
                  ),
                ],
              ),

              Divider(height: 24.h, color: Colors.grey.shade200),

              // Scrollable Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Metadata card
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8F9),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(FlutterRemix.user_settings_line, size: 16.sp, color: AppColors.fern),
                                SizedBox(width: 8.w),
                                Text(
                                  'Technician: ',
                                  style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                                ),
                                Text(
                                  order.technicianName.isNotEmpty ? order.technicianName : 'Field Technician',
                                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Icon(FlutterRemix.time_line, size: 16.sp, color: AppColors.fern),
                                SizedBox(width: 8.w),
                                Text(
                                  'Executed: ',
                                  style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                                ),
                                Text(
                                  formattedTime,
                                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Diagnosed Problem
                      Text(
                        'Diagnosed Problem',
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.hunterGreen),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        order.symptomTitle,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),

                      SizedBox(height: 16.h),

                      // Resolution Procedure
                      Text(
                        'Executed Procedure',
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.hunterGreen),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          order.resolutionSummary,
                          style: TextStyle(fontSize: 13.sp, color: Colors.black87, height: 1.4),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Parts Deducted Section (from work_order_parts)
                      Text(
                        'Deducted Spare Parts',
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.hunterGreen),
                      ),
                      SizedBox(height: 8.h),

                      FutureBuilder<List<WorkOrderPart>>(
                        future: controller.fetchWorkOrderParts(order.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(color: AppColors.fern, strokeWidth: 2),
                              ),
                            );
                          }

                          final parts = snapshot.data ?? [];

                          if (parts.isEmpty) {
                            return Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(FlutterRemix.information_line, size: 16.sp, color: Colors.black45),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      '1 unit was decremented from live inventory upon execution.',
                                      style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: parts.map((part) {
                              final partTime = DateFormat('hh:mm a').format(part.timestamp);
                              return Container(
                                margin: EdgeInsets.only(bottom: 8.h),
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(color: AppColors.fern.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.limeCream,
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Text(
                                        part.sku,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.evergreen,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            part.partName,
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            'Deducted at $partTime',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: Colors.black45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Text(
                                        '-${part.quantityDeducted} unit',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Close Button
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Close',
                    style: TextStyle(fontSize: 14.sp, color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
