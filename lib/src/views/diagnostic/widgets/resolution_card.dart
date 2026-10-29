import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/imports/packages_imports.dart';
import 'package:resolveflow/src/controllers/inventory/inventory_controller.dart';
import 'package:resolveflow/src/controllers/work_order/work_order_controller.dart';
import 'package:resolveflow/src/models/inventory_part.dart';
import 'package:resolveflow/src/models/resolution_result.dart';
import 'package:resolveflow/src/models/work_order.dart';
import 'package:resolveflow/src/models/work_order_part.dart';
import 'package:resolveflow/src/theme/resolveflow_colors.dart';
import 'package:resolveflow/src/views/diagnostic/widgets/sku_badge_chip.dart';

class ResolutionCard extends StatelessWidget {
  const ResolutionCard({
    super.key,
    required this.resolution,
    this.onApplyFix,
  });

  final ResolutionResult resolution;
  final VoidCallback? onApplyFix;

  @override
  Widget build(BuildContext context) {
    final inventoryController = Get.find<InventoryController>();

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: resolution.isHighConfidence
              ? AppColors.fern.withValues(alpha: 0.3)
              : Colors.black12,
          width: resolution.isHighConfidence ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.evergreen.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Confidence Badge + Title
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.hunterGreen.withValues(alpha: 0.04),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    resolution.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.evergreen,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: resolution.isHighConfidence
                        ? AppColors.fern
                        : AppColors.palmLeaf,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    resolution.similarityPercentage,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Diagnostic Observation
                if (resolution.observation.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        FlutterRemix.microscope_line,
                        size: 16.sp,
                        color: AppColors.hunterGreen,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          resolution.observation,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.black87,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],

                // Fix Procedure
                Text(
                  'Resolution Procedure:',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.hunterGreen,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    resolution.fixProcedure,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ),

                SizedBox(height: 14.h),

                // Suggested SKU Chip & Real-time Stock Status
                Obx(() {
                  final part = inventoryController.allParts
                      .where((p) => p.sku.toUpperCase() == resolution.requiredSku.toUpperCase())
                      .firstOrNull;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Highlighted SKU Chip in Lime Cream
                      SkuBadgeChip(sku: resolution.requiredSku),

                      // Real-time stock status badge
                      _buildStockBadge(part),
                    ],
                  );
                }),

                SizedBox(height: 16.h),

                // Apply Fix & Deduct Stock Action Button
                Obx(() {
                  final part = inventoryController.allParts
                      .where((p) => p.sku.toUpperCase() == resolution.requiredSku.toUpperCase())
                      .firstOrNull;
                  final isOutOfStock = part != null && part.isOutOfStock;

                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOutOfStock ? Colors.grey : AppColors.fern,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 1,
                    ),
                    onPressed: isOutOfStock
                        ? null
                        : () => _confirmAndApplyFix(context, resolution, part),
                    icon: const Icon(FlutterRemix.check_double_line, size: 18),
                    label: Text(
                      isOutOfStock ? 'Cannot Apply (Out of Stock)' : 'Apply Fix & Deduct Stock',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(InventoryPart? part) {
    if (part == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          'Part Unlisted',
          style: TextStyle(fontSize: 11.sp, color: Colors.black54),
        ),
      );
    }

    if (part.isOutOfStock) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FlutterRemix.close_circle_line, size: 12.sp, color: Colors.red.shade800),
            SizedBox(width: 4.w),
            Text(
              '0 Available (Depleted)',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
          ],
        ),
      );
    }

    if (part.isLowStock) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FlutterRemix.alert_line, size: 12.sp, color: Colors.amber.shade900),
            SizedBox(width: 4.w),
            Text(
              '${part.quantityOnHand} Left (Low Stock)',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.limeCream,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FlutterRemix.check_line, size: 12.sp, color: AppColors.evergreen),
          SizedBox(width: 4.w),
          Text(
            '${part.quantityOnHand} Available',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.evergreen,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAndApplyFix(
    BuildContext context,
    ResolutionResult res,
    InventoryPart? part,
  ) {
    final workOrderController = Get.find<WorkOrderController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.fern.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      FlutterRemix.file_transfer_line,
                      color: AppColors.fern,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confirm Repair & Stock Deduction',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.evergreen,
                          ),
                        ),
                        Text(
                          'Atomic transaction across work_orders & parts_inventory',
                          style: TextStyle(fontSize: 11.sp, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 28.h),

              // Item Breakdown
              _buildTransactionRow('Problem', res.title),
              SizedBox(height: 8.h),
              _buildTransactionRow('Required SKU', res.requiredSku),
              SizedBox(height: 8.h),
              _buildTransactionRow(
                'Part Name',
                part?.name ?? 'Identified Component',
              ),
              SizedBox(height: 8.h),
              _buildTransactionRow(
                'Stock Balance',
                part != null
                    ? '${part.quantityOnHand} units  ➔  ${part.quantityOnHand - 1} units (-1)'
                    : '1 unit to be deducted',
                highlight: true,
              ),

              SizedBox(height: 24.h),

              // Confirm Button
              Obx(() {
                final isExecuting = workOrderController.isExecuting;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fern,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: isExecuting
                      ? null
                      : () async {
                          print("check:::$res &&&& ${res.requiredSku.toString()}");
                          final result = await workOrderController.executeWorkOrder(
                            context: context,
                            resolution: res,
                            sku: res.requiredSku,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);

                          if (result != null && context.mounted) {
                            _showReceiptDialog(context, result.workOrder, result.workOrderPart);
                          }
                        },
                  child: isExecuting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Execute Work Order & Deduct 1 Unit',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                );
              }),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionRow(String label, String value, {bool highlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.fern : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _showReceiptDialog(BuildContext context, WorkOrder wo, WorkOrderPart partLog) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.limeCream,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FlutterRemix.checkbox_circle_line,
                  color: AppColors.evergreen,
                  size: 40.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Work Order Executed!',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.evergreen,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Record created in work_orders & parts_inventory decremented successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, color: Colors.black54),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  children: [
                    Text(
                      wo.workOrderNumber,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.fern,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Deducted: 1x ${partLog.sku} (${partLog.partName})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.fern,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
  }
}
