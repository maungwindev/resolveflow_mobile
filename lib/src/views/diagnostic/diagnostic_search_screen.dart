import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/imports/packages_imports.dart';
import 'package:resolveflow/src/controllers/diagnostic/diagnostic_controller.dart';
import 'package:resolveflow/src/models/resolution_result.dart';
import 'package:resolveflow/src/theme/resolveflow_colors.dart';
import 'package:resolveflow/src/views/diagnostic/widgets/knowledge_ingestion_form.dart';
import 'package:resolveflow/src/views/diagnostic/widgets/resolution_card.dart';

class DiagnosticSearchScreen extends StatefulWidget {
  const DiagnosticSearchScreen({super.key});

  @override
  State<DiagnosticSearchScreen> createState() => _DiagnosticSearchScreenState();
}

class _DiagnosticSearchScreenState extends State<DiagnosticSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _quickQueries = [
    'coolant boiling into reservoir',
    'engine slow warm up heater cold',
    'rough idle check engine light P0135',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch(String query) {
    _searchController.text = query;
    Get.find<DiagnosticController>().search(query);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DiagnosticController>();

    return Column(
      children: [
        // Search Header Card
        Container(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Compact Sleek Search Input Field
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment
                      .stretch, // Stretches button to exactly match TextField height
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (val) => controller.search(val),
                        textAlignVertical: TextAlignVertical.center,
                        style:
                            TextStyle(fontSize: 13.sp, color: Colors.black87),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Enter symptoms (e.g. coolant boiling)...',
                          hintStyle:
                              TextStyle(fontSize: 12.sp, color: Colors.black38),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 40.w,
                            minHeight: 40.h,
                          ),
                          prefixIcon: Icon(
                            FlutterRemix.stethoscope_line,
                            size: 18.sp,
                            color: AppColors.fern,
                          ),
                          suffixIconConstraints: BoxConstraints(
                            minWidth: 36.w,
                            minHeight: 36.h,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    FlutterRemix.close_circle_line,
                                    size: 16.sp,
                                    color: Colors.black38,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    controller.clearSearch();
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10
                                .h, // Controls the final total height smoothly
                          ),
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
                            borderSide: const BorderSide(
                              color: AppColors.fern,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (text) => setState(() {}),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    AspectRatio(
                      aspectRatio:
                          1.7, // Keeps button perfectly square relative to the TextField's height
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.hunterGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        onPressed: () =>
                            controller.search(_searchController.text),
                        child: Icon(FlutterRemix.search_2_line, size: 20.sp),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10.h),
              Text(
                'Examples ',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.hunterGreen,
                ),
              ),
              SizedBox(height: 5.h),
              // Quick Symptom Suggestions
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._quickQueries.map((q) {
                      return Padding(
                        padding: EdgeInsets.only(right: 6.w),
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor:
                              AppColors.limeCream.withValues(alpha: 0.4),
                          label: Text(
                            q,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.evergreen,
                            ),
                          ),
                          onPressed: () => _triggerSearch(q),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Search Results Body
        Expanded(
          child: Obx(() {
            final state = controller.searchState.value;

            return switch (state) {
              RequestInitial() => _buildInitialPrompt(controller),
              RequestLoading() => const Center(
                  child: CircularProgressIndicator(color: AppColors.fern),
                ),
              RequestFailure(:final failure) =>
                _buildErrorView(failure, controller),
              RequestSuccess(:final data) =>
                _buildResultsList(data, controller),
            };
          }),
        ),
      ],
    );
  }

  Widget _buildInitialPrompt(DiagnosticController controller) {
    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        SizedBox(height: 20.h),
        Center(
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.limeCream.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FlutterRemix.pulse_line,
              size: 48.sp,
              color: AppColors.fern,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Semantic Diagnostic Search',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.evergreen,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Describe the vehicle or machine symptom in plain language. ResolveFlow Intelligent Diagnostics matches historical troubleshooting procedures using semantic similarity.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.sp, color: Colors.black54, height: 1.4),
        ),
        SizedBox(height: 24.h),

        // Toggle Knowledge Form
        Obx(() {
          if (controller.showKnowledgeForm.value) {
            return KnowledgeIngestionForm(
              initialSymptom: _searchController.text,
              onClose: () => controller.toggleKnowledgeForm(false),
            );
          }

          return OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.palmLeaf),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            icon: const Icon(FlutterRemix.add_line, color: AppColors.fern),
            label: const Text(
              'Add New Procedure to Knowledge Base',
              style:
                  TextStyle(color: AppColors.fern, fontWeight: FontWeight.w700),
            ),
            onPressed: () => controller.toggleKnowledgeForm(true),
          );
        }),
      ],
    );
  }

  Widget _buildErrorView(dynamic failure, DiagnosticController controller) {
    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        SizedBox(height: 20.h),
        Center(
          child: Icon(
            FlutterRemix.error_warning_line,
            size: 40.sp,
            color: Colors.amber.shade800,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Could not retrieve procedures',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6.h),
        Text(
          failure.message.toString(),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp, color: Colors.black54),
        ),
        SizedBox(height: 20.h),
        KnowledgeIngestionForm(
          initialSymptom: _searchController.text,
          onClose: () => controller.toggleKnowledgeForm(false),
        ),
      ],
    );
  }

  Widget _buildResultsList(
    List<ResolutionResult> results,
    DiagnosticController controller,
  ) {
    if (results.isEmpty) {
      return ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(FlutterRemix.search_eye_line,
                    color: Colors.amber.shade900),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'No historical procedures matched your query. Please submit your resolution below to teach the system.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          KnowledgeIngestionForm(
            initialSymptom: _searchController.text,
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Matched Solutions (${results.length})',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.evergreen,
              ),
            ),
            TextButton.icon(
              onPressed: () => controller.toggleKnowledgeForm(),
              icon: const Icon(FlutterRemix.add_line, size: 16),
              label: const Text('Add Knowledge'),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // Matched cards
        ...results.map((res) => ResolutionCard(resolution: res)),

        // Inline Knowledge Form if toggled or if top match is low similarity
        Obx(() {
          if (!controller.showKnowledgeForm.value) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8.h),
              KnowledgeIngestionForm(
                initialSymptom: _searchController.text,
                onClose: () => controller.toggleKnowledgeForm(false),
              ),
            ],
          );
        }),
      ],
    );
  }
}
