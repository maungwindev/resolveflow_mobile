import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:resolveflow/src/theme/resolveflow_colors.dart';

/// Highlighted chip for suggested SKU using Lime Cream (#ECF39E) and Evergreen (#132A13)
/// for WCAG AA compliance.
class SkuBadgeChip extends StatelessWidget {
  const SkuBadgeChip({
    super.key,
    required this.sku,
    this.label,
    this.onTap,
  });

  final String sku;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: AppColors.limeCream,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppColors.palmLeaf.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FlutterRemix.tools_line,
              size: 14.sp,
              color: AppColors.onSurfaceHighlight,
            ),
            SizedBox(width: 6.w),
            Text(
              label != null ? '$label: $sku' : 'SKU: $sku',
              style: TextStyle(
                color: AppColors.onSurfaceHighlight,
                fontWeight: FontWeight.w800,
                fontSize: 12.sp,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

