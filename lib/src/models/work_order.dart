import 'package:equatable/equatable.dart';

/// Operational record stored in Appwrite Operations Registry (`work_orders`).
class WorkOrder extends Equatable {
  const WorkOrder({
    required this.id,
    required this.workOrderNumber,
    required this.symptomTitle,
    required this.resolutionSummary,
    required this.technicianId,
    this.technicianName = '',
    this.status = 'completed',
    required this.createdAt,
  });

  final String id;
  final String workOrderNumber;
  final String symptomTitle;
  final String resolutionSummary;
  final String technicianId;
  final String technicianName;
  final String status;
  final DateTime createdAt;

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    final id = json['\$id']?.toString() ?? json['id']?.toString() ?? '';
    final workOrderNumber = json['work_order_number']?.toString() ?? '';
    final symptomTitle = json['symptom_title']?.toString() ?? '';
    final resolutionSummary = json['resolution_summary']?.toString() ?? '';
    final technicianId = json['technician_id']?.toString() ?? '';
    final technicianName = json['technician_name']?.toString() ?? '';
    final status = json['status']?.toString() ?? 'completed';

    DateTime parsedDate;
    final dateRaw = json['created_at'] ?? json['\$createdAt'];
    if (dateRaw is String) {
      parsedDate = DateTime.tryParse(dateRaw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return WorkOrder(
      id: id,
      workOrderNumber: workOrderNumber,
      symptomTitle: symptomTitle,
      resolutionSummary: resolutionSummary,
      technicianId: technicianId,
      technicianName: technicianName,
      status: status,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'work_order_number': workOrderNumber,
        'symptom_title': symptomTitle,
        'resolution_summary': resolutionSummary,
        'technician_id': technicianId,
        'technician_name': technicianName,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  WorkOrder copyWith({
    String? id,
    String? workOrderNumber,
    String? symptomTitle,
    String? resolutionSummary,
    String? technicianId,
    String? technicianName,
    String? status,
    DateTime? createdAt,
  }) {
    return WorkOrder(
      id: id ?? this.id,
      workOrderNumber: workOrderNumber ?? this.workOrderNumber,
      symptomTitle: symptomTitle ?? this.symptomTitle,
      resolutionSummary: resolutionSummary ?? this.resolutionSummary,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        workOrderNumber,
        symptomTitle,
        resolutionSummary,
        technicianId,
        technicianName,
        status,
        createdAt,
      ];
}

