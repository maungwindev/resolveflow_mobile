import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/imports/packages_imports.dart';
import 'package:resolveflow/src/controllers/diagnostic/diagnostic_controller.dart';
import 'package:resolveflow/src/controllers/inventory/inventory_controller.dart';
import 'package:resolveflow/src/theme/resolveflow_colors.dart';

class KnowledgeIngestionForm extends StatefulWidget {
  const KnowledgeIngestionForm({
    super.key,
    this.initialSymptom = '',
    this.onClose,
  });

  final String initialSymptom;
  final VoidCallback? onClose;

  @override
  State<KnowledgeIngestionForm> createState() => _KnowledgeIngestionFormState();
}

class _KnowledgeIngestionFormState extends State<KnowledgeIngestionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _symptomController;
  late final TextEditingController _observationController;
  late final TextEditingController _fixController;
  late final TextEditingController _skuController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _symptomController = TextEditingController(text: widget.initialSymptom);
    _observationController = TextEditingController();
    _fixController = TextEditingController();
    _skuController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant KnowledgeIngestionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSymptom != oldWidget.initialSymptom &&
        _symptomController.text.isEmpty) {
      _symptomController.text = widget.initialSymptom;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _symptomController.dispose();
    _observationController.dispose();
    _fixController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final diagnosticController = Get.find<DiagnosticController>();
    final success = await diagnosticController.submitKnowledge(
      context: context,
      title: _titleController.text,
      symptom: _symptomController.text,
      observation: _observationController.text,
      fixProcedure: _fixController.text,
      requiredSku: _skuController.text,
    );

    if (success && widget.onClose != null) {
      widget.onClose!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final diagnosticController = Get.find<DiagnosticController>();
    final inventoryController = Get.find<InventoryController>();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.palmLeaf.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.evergreen.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.limeCream,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    FlutterRemix.lightbulb_line,
                    color: AppColors.evergreen,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adaptive Knowledge Ingestion',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.evergreen,
                        ),
                      ),
                      Text(
                        'No matching fix? Contribute new solution to Knowledge Base',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(FlutterRemix.close_line, size: 18),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
            Divider(height: 24.h, color: AppColors.palmLeaf.withValues(alpha: 0.2)),

            // Symptom Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Symptom Title *',
                hintText: 'e.g., Radiator Cap Pressure Release Failure',
                prefixIcon: Icon(FlutterRemix.error_warning_line, size: 18),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
            ),
            SizedBox(height: 12.h),

            // Diagnostic Observation
            TextFormField(
              controller: _observationController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Diagnostic Observation',
                hintText: 'e.g., Warped rubber seal; releases coolant below 0.9 bar.',
                prefixIcon: Icon(FlutterRemix.survey_line, size: 18),
              ),
            ),
            SizedBox(height: 12.h),

            // Fix Implemented (Procedure)
            TextFormField(
              controller: _fixController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Fix Implemented (Procedure) *',
                hintText: '1. Wait for engine to cool\n2. Replace with 1.1 Bar cap\n3. Bleed air pockets',
                prefixIcon: Icon(FlutterRemix.file_text_line, size: 18),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please describe the fix steps'
                  : null,
            ),
            SizedBox(height: 12.h),

            // Required SKU (with quick suggestion chips)
            TextFormField(
              controller: _skuController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Required Part SKU *',
                hintText: 'e.g., RAD-CAP-04',
                prefixIcon: const Icon(FlutterRemix.tools_line, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(FlutterRemix.arrow_down_s_line, size: 18),
                  onPressed: () {
                    // Show quick bottom picker of current inventory SKUs
                    _showSkuPicker(context, inventoryController);
                  },
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter required part SKU'
                  : null,
            ),

            // Quick SKU suggestion pills
            Obx(() {
              final parts = inventoryController.allParts.take(4).toList();
              if (parts.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: parts.map((part) {
                    return ActionChip(
                      label: Text(
                        part.sku,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.evergreen,
                        ),
                      ),
                      backgroundColor: AppColors.limeCream.withValues(alpha: 0.6),
                      onPressed: () {
                        setState(() {
                          _skuController.text = part.sku;
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            }),

            SizedBox(height: 16.h),

            // Submit Button
            Obx(() {
              final isSubmitting = diagnosticController.isSubmitting;
              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.fern,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: isSubmitting ? null : _submit,
                icon: isSubmitting
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(FlutterRemix.add_circle_line),
                label: Text(
                  isSubmitting ? 'Saving to Knowledge Base...' : 'Save to Knowledge Base',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSkuPicker(BuildContext context, InventoryController controller) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select SKU from Inventory',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.evergreen,
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: ListView.separated(
                  itemCount: controller.allParts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final part = controller.allParts[index];
                    return ListTile(
                      dense: true,  
                      title: Text(
                        '${part.sku} — ${part.name}',
                        style: const TextStyle(fontWeight: FontWeight.w600,color: AppColors.evergreen),
                      ),
                      subtitle: Text('Stock: ${part.quantityOnHand} units'),
                      onTap: () {
                        setState(() {
                          _skuController.text = part.sku;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

