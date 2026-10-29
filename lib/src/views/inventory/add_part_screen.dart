import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/imports/packages_imports.dart';
import 'package:resolveflow/src/controllers/inventory/inventory_controller.dart';
import 'package:resolveflow/src/models/inventory_part.dart';
import 'package:resolveflow/src/theme/resolveflow_colors.dart';

class AddPartScreen extends StatefulWidget {
  const AddPartScreen({super.key});

  @override
  State<AddPartScreen> createState() => _AddPartScreenState();
}

class _AddPartScreenState extends State<AddPartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '10');
  final _minController = TextEditingController(text: '2');
  final _priceController = TextEditingController(text: '0.00');
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _qtyController.dispose();
    _minController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = Get.find<InventoryController>();

    final sku = _skuController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    final quantity = int.tryParse(_qtyController.text.trim()) ?? 0;
    final minThreshold = int.tryParse(_minController.text.trim()) ?? 2;
    final unitPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final location = _locationController.text.trim();

    final newPart = InventoryPart(
      id: '',
      sku: sku,
      name: name,
      quantityOnHand: quantity,
      minThreshold: minThreshold,
      unitPrice: unitPrice,
      location: location,
    );

    final success = await controller.addPart(
      context: context,
      part: newPart,
    );

    if (success && mounted) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InventoryController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.evergreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(FlutterRemix.arrow_left_line, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Add New Inventory Part',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17.sp,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.limeCream.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.palmLeaf.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        FlutterRemix.archive_line,
                        color: AppColors.evergreen,
                        size: 22.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'Add a spare part to the catalog. Technicians can view and deduct stock when applying resolutions.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.evergreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Part SKU (Required)
                _buildLabel('Part SKU *'),
                TextFormField(
                  controller: _skuController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'e.g. RAD-CAP-04, THRM-82C',
                    prefixIcon: const Icon(FlutterRemix.tools_line, size: 18),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return 'Part SKU is required';
                    if (trimmed.length > 150) return 'SKU cannot exceed 150 characters';
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Part Name (Required)
                _buildLabel('Part Name *'),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'e.g. Radiator Pressure Cap 1.1 Bar',
                    prefixIcon: const Icon(FlutterRemix.price_tag_3_line, size: 18),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return 'Part name is required';
                    if (trimmed.length > 255) return 'Name cannot exceed 255 characters';
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Quantity & Min Threshold
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Initial Stock *'),
                          TextFormField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: '10',
                              prefixIcon: const Icon(FlutterRemix.stack_line, size: 18),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter quantity';
                              }
                              final num = int.tryParse(value.trim());
                              if (num == null || num < 0) return 'Must be >= 0';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Min Threshold *'),
                          TextFormField(
                            controller: _minController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: '2',
                              prefixIcon: const Icon(FlutterRemix.alarm_warning_line, size: 18),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter min';
                              }
                              final num = int.tryParse(value.trim());
                              if (num == null || num < 0) return 'Must be >= 0';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Unit Price & Warehouse Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Unit Price (\$)'),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: '18.50',
                              prefixIcon: const Icon(FlutterRemix.money_dollar_circle_line, size: 18),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final p = double.tryParse(value.trim());
                                if (p == null || p < 0) return 'Invalid price';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Bin / Location'),
                          TextFormField(
                            controller: _locationController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Aisle 3, Bin B4',
                              prefixIcon: const Icon(FlutterRemix.map_pin_2_line, size: 18),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),

                // Save Part Button
                Obx(() {
                  final isMutating = controller.isMutating;
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.fern,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                    onPressed: isMutating ? null : _onSave,
                    icon: isMutating
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(FlutterRemix.save_line, size: 20),
                    label: Text(
                      isMutating ? 'Saving Part...' : 'Save Part to Inventory',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, left: 2.w),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.evergreen,
        ),
      ),
    );
  }
}

