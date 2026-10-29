import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/imports/packages_imports.dart';
import 'package:resolveflow/src/controllers/auth/session_controller.dart';
import 'package:resolveflow/src/controllers/inventory/inventory_controller.dart';
import 'package:resolveflow/src/models/inventory_part.dart';
import 'package:resolveflow/src/theme/resolveflow_colors.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InventoryController>();
    final session = Get.find<SessionController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Filter Bar & Low Stock Summary
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Compact Search Input
                SizedBox(
                  height: 44.h,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => controller.searchQuery.value = val,
                    style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search SKU, part name, or location...',
                      hintStyle: TextStyle(fontSize: 12.sp, color: Colors.black38),
                      prefixIcon: const Icon(FlutterRemix.search_line, size: 16,color: AppColors.fern,),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(FlutterRemix.close_circle_line, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                controller.searchQuery.value = '';
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),

                // Low Stock Alert Banner
                Obx(() {
                  final lowCount = controller.lowStockCount;
                  if (lowCount == 0) return const SizedBox.shrink();

                  return Container(
                    margin: EdgeInsets.only(top: 10.h),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(FlutterRemix.alarm_warning_line, size: 16.sp, color: Colors.amber.shade900),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '$lowCount part(s) are low in stock or depleted. Restock recommended.',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Inventory List
          Expanded(
            child: Obx(() {
              final state = controller.partsState.value;

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
                            onPressed: () => controller.fetchParts(),
                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                RequestSuccess() => _buildPartsList(controller, session),
              };
            }),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        final isManager = session.user?.isManager ?? false;
        if (!isManager) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          backgroundColor: AppColors.hunterGreen,
          foregroundColor: Colors.white,
          elevation: 3,
          onPressed: () => Get.toNamed(AppRoutes.addPart),
          icon: const Icon(FlutterRemix.add_line),
          label: const Text('Add Part', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      }),
    );
  }

  Widget _buildPartsList(InventoryController controller, SessionController session) {
    final parts = controller.filteredParts;
    final isManager = session.user?.isManager ?? false;

    if (parts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FlutterRemix.inbox_line, size: 48.sp, color: Colors.black26),
            SizedBox(height: 8.h),
            Text(
              'No inventory parts found',
              style: TextStyle(fontSize: 14.sp, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.fern,
      onRefresh: () => controller.fetchParts(showLoading: false),
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: parts.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final part = parts[index];
          return _buildPartCard(context, part, controller, isManager);
        },
      ),
    );
  }

  Widget _buildPartCard(
    BuildContext context,
    InventoryPart part,
    InventoryController controller,
    bool isManager,
  ) {
    Color statusBgColor = AppColors.limeCream;
    Color statusTextColor = AppColors.evergreen;
    String statusTitle = 'In Stock (${part.quantityOnHand} Available)';
    IconData statusIcon = FlutterRemix.checkbox_circle_fill;

    if (part.isOutOfStock) {
      statusBgColor = Colors.red.shade50;
      statusTextColor = Colors.red.shade800;
      statusTitle = 'Out of Stock (0 Available)';
      statusIcon = FlutterRemix.close_circle_fill;
    } else if (part.isLowStock) {
      statusBgColor = Colors.amber.shade100;
      statusTextColor = Colors.amber.shade900;
      statusTitle = 'Low Stock (${part.quantityOnHand} Left)';
      statusIcon = FlutterRemix.error_warning_fill;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: part.isOutOfStock
              ? Colors.red.shade200
              : (part.isLowStock ? Colors.amber.shade300 : Colors.grey.shade200),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: SKU Badge + Stock Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.limeCream,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: AppColors.palmLeaf.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FlutterRemix.tools_line, size: 12.sp, color: AppColors.evergreen),
                    SizedBox(width: 4.w),
                    Text(
                      part.sku,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.evergreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Stock Status Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12.sp, color: statusTextColor),
                    SizedBox(width: 4.w),
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: statusTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Part Name
          Text(
            part.name,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10.h),

          // Details Grid (Price, Min Threshold, Location)
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetaItem(
                      label: 'Unit Price',
                      value: part.unitPrice > 0 ? '\$${part.unitPrice.toStringAsFixed(2)}' : 'Not set',
                      icon: FlutterRemix.money_dollar_circle_line,
                    ),
                    _buildMetaItem(
                      label: 'Min Reorder Threshold',
                      value: '${part.minThreshold} units',
                      icon: FlutterRemix.shield_flash_line,
                    ),
                  ],
                ),
                if (part.location.isNotEmpty) ...[
                  Divider(height: 16.h, color: Colors.grey.shade200),
                  Row(
                    children: [
                      Icon(FlutterRemix.map_pin_2_line, size: 14.sp, color: Colors.black45),
                      SizedBox(width: 6.w),
                      Text(
                        'Location: ',
                        style: TextStyle(fontSize: 11.sp, color: Colors.black54, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        part.location,
                        style: TextStyle(fontSize: 12.sp, color: Colors.black87, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Manager Restock Action Button
          if (isManager) ...[
            SizedBox(height: 12.h),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.fern, width: 1.2),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              icon: const Icon(FlutterRemix.add_circle_line, color: AppColors.fern, size: 18),
              label: Text(
                'Restock Stock (${part.sku})',
                style: const TextStyle(
                  color: AppColors.fern,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => _showRestockDialog(context, part, controller),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: AppColors.fern),
        SizedBox(width: 6.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10.sp, color: Colors.black45, fontWeight: FontWeight.w600),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 12.sp, color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  void _showRestockDialog(
    BuildContext context,
    InventoryPart part,
    InventoryController controller,
  ) {
    final amountController = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            'Restock ${part.sku}',
            style: TextStyle(color: AppColors.evergreen, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current stock: ${part.quantityOnHand} units\nHow many units would you like to add?',
                style: TextStyle(fontSize: 13.sp, color: Colors.black87),
              ),
              SizedBox(height: 14.h),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Units to Add',
                  prefixIcon: const Icon(FlutterRemix.add_line),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.fern),
              onPressed: () async {
                final amount = int.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  Navigator.pop(ctx);
                  await controller.restockPart(
                    context: context,
                    sku: part.sku,
                    amount: amount,
                  );
                }
              },
              child: const Text('Confirm Restock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
